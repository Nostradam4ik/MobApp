import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';
import 'biometric_service.dart';
import 'input_validator.dart';

/// Gestionnaire de sécurité centralisé
/// Point d'entrée unique pour toutes les opérations de sécurité
class SecurityManager {
  static SecurityManager? _instance;

  late SecureStorageService _storage;
  late EncryptionService _encryption;
  late BiometricService _biometric;
  late InputValidator _validator;

  // État de la session
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  DateTime? _lastActivity;
  Timer? _sessionTimer;

  // Callbacks
  final _sessionExpiredCallbacks = <VoidCallback>[];
  final _securityEventCallbacks = <void Function(SecurityEvent)>[];

  SecurityManager._();

  static Future<SecurityManager> getInstance() async {
    if (_instance == null) {
      _instance = SecurityManager._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    _storage = await SecureStorageService.getInstance();
    _encryption = await EncryptionService.getInstance();
    _biometric = await BiometricService.getInstance();
    _validator = InputValidator.getInstance();

    _isInitialized = true;

    // Vérifier la session existante
    await _checkExistingSession();

    // Démarrer le monitoring de session
    _startSessionMonitoring();
  }

  // ==================== GESTION DE SESSION ====================

  /// Vérifie si une session valide existe
  Future<void> _checkExistingSession() async {
    final hasToken = await _storage.hasValidSession();
    if (hasToken) {
      _isAuthenticated = true;
      _lastActivity = DateTime.now();
      _notifySecurityEvent(SecurityEvent.sessionRestored);
    }
  }

  /// Démarre le monitoring de session
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionValidity(),
    );
  }

  /// Vérifie la validité de la session
  Future<void> _checkSessionValidity() async {
    if (!_isAuthenticated) return;

    // Vérifier le timeout d'inactivité
    if (_lastActivity != null) {
      final elapsed = DateTime.now().difference(_lastActivity!);
      if (elapsed > SecurityConstants.sessionTimeout) {
        await logout(reason: LogoutReason.sessionTimeout);
        return;
      }
    }

    // Vérifier l'expiration du token
    final isValid = await _storage.hasValidSession();
    if (!isValid) {
      await logout(reason: LogoutReason.tokenExpired);
    }
  }

  /// Enregistre une activité utilisateur
  void recordActivity() {
    _lastActivity = DateTime.now();
    _storage.updateLastActivity();
  }

  /// Vérifie si l'utilisateur est authentifié
  bool get isAuthenticated => _isAuthenticated;

  /// Obtient le temps restant de session
  Duration? get sessionTimeRemaining {
    if (_lastActivity == null) return null;
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = SecurityConstants.sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ==================== AUTHENTIFICATION ====================

  /// Tente une connexion avec email/password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Vérifier le verrouillage
    final lockStatus = await _storage.checkLockout();
    if (lockStatus.isLocked) {
      _notifySecurityEvent(SecurityEvent.accountLocked);
      return AuthResult.locked(lockStatus.remainingTime!);
    }

    // Valider les entrées
    final emailResult = _validator.validateEmail(email);
    if (!emailResult.isValid) {
      return AuthResult.error(emailResult.message!);
    }

    final passwordResult = _validator.validatePassword(password);
    if (!passwordResult.isValid) {
      return AuthResult.error('Mot de passe invalide');
    }

    // L'authentification réelle se fait via Supabase
    // Ici on gère juste la partie sécurité locale
    return AuthResult.needsVerification();
  }

  /// Finalise l'authentification après vérification Supabase
  Future<void> onAuthSuccess({
    required String authToken,
    required String refreshToken,
  }) async {
    await _storage.saveAuthToken(authToken);
    await _storage.saveRefreshToken(refreshToken);
    await _storage.resetFailedAttempts();

    _isAuthenticated = true;
    _lastActivity = DateTime.now();

    _notifySecurityEvent(SecurityEvent.loginSuccess);
  }

  /// Enregistre un échec d'authentification
  Future<AuthResult> onAuthFailure() async {
    await _storage.incrementFailedAttempts();

    final lockStatus = await _storage.checkLockout();
    if (lockStatus.isLocked) {
      _notifySecurityEvent(SecurityEvent.accountLocked);
      return AuthResult.locked(lockStatus.remainingTime!);
    }

    final remaining = await _storage.getRemainingAttempts();
    _notifySecurityEvent(SecurityEvent.loginFailed);

    return AuthResult.error(
      'Identifiants incorrects. $remaining tentative(s) restante(s).',
    );
  }

  /// Déconnexion
  Future<void> logout({LogoutReason reason = LogoutReason.userInitiated}) async {
    _isAuthenticated = false;
    _lastActivity = null;

    await _storage.clearAuthToken();
    await _storage.clearRefreshToken();

    switch (reason) {
      case LogoutReason.sessionTimeout:
        _notifySecurityEvent(SecurityEvent.sessionExpired);
        _notifySessionExpired();
        break;
      case LogoutReason.tokenExpired:
        _notifySecurityEvent(SecurityEvent.tokenExpired);
        _notifySessionExpired();
        break;
      case LogoutReason.userInitiated:
        _notifySecurityEvent(SecurityEvent.logout);
        break;
      case LogoutReason.securityBreach:
        _notifySecurityEvent(SecurityEvent.securityBreach);
        _notifySessionExpired();
        break;
    }
  }

  // ==================== BIOMÉTRIE ====================

  /// Vérifie si la biométrie est disponible
  Future<BiometricStatus> getBiometricStatus() async {
    return await _biometric.checkBiometricStatus();
  }

  /// Active la biométrie
  Future<bool> enableBiometric() async {
    final result = await _biometric.enableBiometric();
    if (result) {
      _notifySecurityEvent(SecurityEvent.biometricEnabled);
    }
    return result;
  }

  /// Désactive la biométrie
  Future<void> disableBiometric() async {
    await _biometric.disableBiometric();
    _notifySecurityEvent(SecurityEvent.biometricDisabled);
  }

  /// Authentifie avec la biométrie
  Future<BiometricResult> authenticateWithBiometric({
    String? reason,
  }) async {
    final result = await _biometric.authenticate(
      reason: reason ?? 'Authentifiez-vous pour continuer',
    );

    if (result.success) {
      recordActivity();
      _notifySecurityEvent(SecurityEvent.biometricSuccess);
    } else {
      _notifySecurityEvent(SecurityEvent.biometricFailed);
    }

    return result;
  }

  /// Authentifie pour une opération sensible
  Future<bool> authenticateForSensitiveOperation({
    required String operationDescription,
  }) async {
    // Vérifier si une ré-auth biométrique est nécessaire
    final needsReauth = await _biometric.needsReauthentication(
      timeout: SecurityConstants.sensitiveOperationTimeout,
    );

    if (!needsReauth) {
      return true;
    }

    final result = await _biometric.authenticateForSensitiveOperation(
      operationDescription: operationDescription,
    );

    if (result.success) {
      _notifySecurityEvent(SecurityEvent.sensitiveOperationAuthorized);
    }

    return result.success;
  }

  // ==================== CODE PIN ====================

  /// Configure un code PIN
  Future<bool> setupPin(String pin) async {
    final result = _validator.validatePin(pin);
    if (!result.isValid) {
      return false;
    }

    final hashedPin = _encryption.hashPin(pin);
    await _storage.savePinHash(hashedPin);

    _notifySecurityEvent(SecurityEvent.pinConfigured);
    return true;
  }

  /// Vérifie un code PIN
  Future<bool> verifyPin(String pin) async {
    final hashedPin = await _storage.getPinHash();
    if (hashedPin == null) {
      return false;
    }

    final isValid = _encryption.verifyPin(pin, hashedPin);

    if (isValid) {
      recordActivity();
      _notifySecurityEvent(SecurityEvent.pinSuccess);
    } else {
      _notifySecurityEvent(SecurityEvent.pinFailed);
    }

    return isValid;
  }

  /// Vérifie si un PIN est configuré
  Future<bool> hasPinConfigured() async {
    final hashedPin = await _storage.getPinHash();
    return hashedPin != null;
  }

  // ==================== ENCRYPTION ====================

  /// Chiffre des données sensibles
  String encryptData(String data) {
    return _encryption.encryptString(data);
  }

  /// Déchiffre des données
  String decryptData(String encryptedData) {
    return _encryption.decryptString(encryptedData);
  }

  /// Chiffre un objet JSON
  String encryptJson(Map<String, dynamic> json) {
    return _encryption.encryptJson(json);
  }

  /// Déchiffre un objet JSON
  Map<String, dynamic> decryptJson(String encryptedJson) {
    return _encryption.decryptJson(encryptedJson);
  }

  // ==================== VALIDATION ====================

  /// Valide un email
  ValidationResult validateEmail(String email) {
    return _validator.validateEmail(email);
  }

  /// Valide un mot de passe
  PasswordValidationResult validatePassword(String password) {
    return _validator.validatePassword(password);
  }

  /// Valide un code PIN
  ValidationResult validatePin(String pin) {
    return _validator.validatePin(pin);
  }

  /// Valide un montant
  ValidationResult validateAmount(String amount) {
    return _validator.validateAmount(amount);
  }

  /// Valide et sanitize du texte
  ValidationResult validateText(String text, {int maxLength = 1000}) {
    return _validator.validateText(text, maxLength: maxLength);
  }

  // ==================== MASQUAGE ====================

  /// Masque des données sensibles
  String maskSensitiveData(String data, {int visibleChars = 4}) {
    return _encryption.maskSensitiveData(data, visibleChars: visibleChars);
  }

  /// Masque un email
  String maskEmail(String email) {
    return _encryption.maskEmail(email);
  }

  // ==================== TOKENS ====================

  /// Génère un token sécurisé
  String generateSecureToken({int length = 32}) {
    return _encryption.generateSecureToken(length: length);
  }

  /// Génère un code de vérification
  String generateVerificationCode({int length = 6}) {
    return _encryption.generateVerificationCode(length: length);
  }

  // ==================== CALLBACKS ====================

  /// Ajoute un callback pour l'expiration de session
  void addSessionExpiredCallback(VoidCallback callback) {
    _sessionExpiredCallbacks.add(callback);
  }

  /// Supprime un callback
  void removeSessionExpiredCallback(VoidCallback callback) {
    _sessionExpiredCallbacks.remove(callback);
  }

  void _notifySessionExpired() {
    for (final callback in _sessionExpiredCallbacks) {
      callback();
    }
  }

  /// Ajoute un listener d'événements de sécurité
  void addSecurityEventListener(void Function(SecurityEvent) listener) {
    _securityEventCallbacks.add(listener);
  }

  /// Supprime un listener
  void removeSecurityEventListener(void Function(SecurityEvent) listener) {
    _securityEventCallbacks.remove(listener);
  }

  void _notifySecurityEvent(SecurityEvent event) {
    for (final callback in _securityEventCallbacks) {
      callback(event);
    }
  }

  // ==================== NETTOYAGE ====================

  /// Efface toutes les données de sécurité
  Future<void> clearAllSecurityData() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    _lastActivity = null;
    _notifySecurityEvent(SecurityEvent.dataCleared);
  }

  /// Libère les ressources
  void dispose() {
    _sessionTimer?.cancel();
    _sessionExpiredCallbacks.clear();
    _securityEventCallbacks.clear();
  }
}

/// Résultat d'authentification
class AuthResult {
  final AuthStatus status;
  final String? message;
  final Duration? lockoutDuration;

  AuthResult._({
    required this.status,
    this.message,
    this.lockoutDuration,
  });

  factory AuthResult.success() => AuthResult._(status: AuthStatus.success);

  factory AuthResult.needsVerification() =>
      AuthResult._(status: AuthStatus.needsVerification);

  factory AuthResult.error(String message) =>
      AuthResult._(status: AuthStatus.error, message: message);

  factory AuthResult.locked(Duration duration) => AuthResult._(
        status: AuthStatus.locked,
        lockoutDuration: duration,
        message: 'Compte verrouillé. Réessayez dans ${duration.inMinutes} minutes.',
      );

  bool get isSuccess => status == AuthStatus.success;
  bool get isLocked => status == AuthStatus.locked;
  bool get needsVerification => status == AuthStatus.needsVerification;
}

/// Statut d'authentification
enum AuthStatus {
  success,
  needsVerification,
  error,
  locked,
}

/// Raison de déconnexion
enum LogoutReason {
  userInitiated,
  sessionTimeout,
  tokenExpired,
  securityBreach,
}

/// Événements de sécurité
enum SecurityEvent {
  // Session
  sessionRestored,
  sessionExpired,
  tokenExpired,

  // Authentification
  loginSuccess,
  loginFailed,
  logout,
  accountLocked,

  // Biométrie
  biometricEnabled,
  biometricDisabled,
  biometricSuccess,
  biometricFailed,

  // PIN
  pinConfigured,
  pinSuccess,
  pinFailed,

  // Opérations
  sensitiveOperationAuthorized,
  securityBreach,
  dataCleared,
}
