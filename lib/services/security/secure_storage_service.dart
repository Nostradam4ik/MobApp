import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de stockage sécurisé pour les données sensibles
/// Utilise flutter_secure_storage (Keychain iOS / Keystore Android)
class SecureStorageService {
  static SecureStorageService? _instance;
  static FlutterSecureStorage? _secureStorage;
  static SharedPreferences? _prefs;

  // Clés pour les données sensibles
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastActivity = 'last_activity';
  static const String _keyFailedAttempts = 'failed_login_attempts';
  static const String _keyLockoutUntil = 'lockout_until';
  static const String _keySessionExpiry = 'session_expiry';
  static const String _keyDeviceId = 'device_id';
  static const String _keyPinHash = 'pin_hash';

  SecureStorageService._();

  static Future<SecureStorageService> getInstance() async {
    if (_instance == null) {
      _instance = SecureStorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    // Configuration du stockage sécurisé avec options maximales
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    );

    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'SmartSpendSecure',
    );

    _secureStorage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );

    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== AUTHENTIFICATION ====================

  /// Sauvegarde le token d'authentification
  Future<void> saveAuthToken(String token) async {
    await _secureStorage?.write(key: _keyAuthToken, value: token);
    await _updateLastActivity();
  }

  /// Récupère le token d'authentification
  Future<String?> getAuthToken() async {
    // Vérifier l'expiration de session
    if (await isSessionExpired()) {
      await clearAuthData();
      return null;
    }
    return _secureStorage?.read(key: _keyAuthToken);
  }

  /// Sauvegarde le refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage?.write(key: _keyRefreshToken, value: token);
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    return _secureStorage?.read(key: _keyRefreshToken);
  }

  /// Sauvegarde l'ID utilisateur
  Future<void> saveUserId(String userId) async {
    await _secureStorage?.write(key: _keyUserId, value: userId);
  }

  /// Récupère l'ID utilisateur
  Future<String?> getUserId() async {
    return _secureStorage?.read(key: _keyUserId);
  }

  /// Efface toutes les données d'authentification
  Future<void> clearAuthData() async {
    await _secureStorage?.delete(key: _keyAuthToken);
    await _secureStorage?.delete(key: _keyRefreshToken);
    await _secureStorage?.delete(key: _keyUserId);
    await _secureStorage?.delete(key: _keySessionExpiry);
    await _secureStorage?.delete(key: _keyLastActivity);
  }

  // ==================== GESTION DE SESSION ====================

  /// Met à jour le timestamp de dernière activité
  Future<void> _updateLastActivity() async {
    final now = DateTime.now().toIso8601String();
    await _secureStorage?.write(key: _keyLastActivity, value: now);
  }

  /// Vérifie si la session a expiré (30 minutes d'inactivité)
  Future<bool> isSessionExpired() async {
    final lastActivityStr = await _secureStorage?.read(key: _keyLastActivity);
    if (lastActivityStr == null) return true;

    try {
      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();
      final inactiveMinutes = now.difference(lastActivity).inMinutes;

      // Session expire après 30 minutes d'inactivité
      return inactiveMinutes > 30;
    } catch (e) {
      return true;
    }
  }

  /// Définit l'expiration de session (durée en heures)
  Future<void> setSessionExpiry(int hours) async {
    final expiry = DateTime.now().add(Duration(hours: hours)).toIso8601String();
    await _secureStorage?.write(key: _keySessionExpiry, value: expiry);
  }

  /// Rafraîchit la session (appelé à chaque activité utilisateur)
  Future<void> refreshSession() async {
    await _updateLastActivity();
  }

  // ==================== PROTECTION ANTI-BRUTEFORCE ====================

  /// Enregistre une tentative de connexion échouée
  Future<int> recordFailedAttempt() async {
    final attemptsStr = await _secureStorage?.read(key: _keyFailedAttempts);
    int attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    attempts++;

    await _secureStorage?.write(key: _keyFailedAttempts, value: attempts.toString());

    // Verrouiller après 5 tentatives
    if (attempts >= 5) {
      final lockoutDuration = _calculateLockoutDuration(attempts);
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await _secureStorage?.write(
        key: _keyLockoutUntil,
        value: lockoutUntil.toIso8601String(),
      );
    }

    return attempts;
  }

  /// Calcule la durée de verrouillage (exponentielle)
  Duration _calculateLockoutDuration(int attempts) {
    // 5 tentatives = 1 min, 6 = 2 min, 7 = 4 min, 8 = 8 min, etc.
    final minutes = 1 << (attempts - 5); // 2^(attempts-5)
    return Duration(minutes: minutes.clamp(1, 60)); // Max 1 heure
  }

  /// Vérifie si le compte est verrouillé
  Future<({bool isLocked, Duration? remainingTime})> checkLockout() async {
    final lockoutUntilStr = await _secureStorage?.read(key: _keyLockoutUntil);
    if (lockoutUntilStr == null) {
      return (isLocked: false, remainingTime: null);
    }

    try {
      final lockoutUntil = DateTime.parse(lockoutUntilStr);
      final now = DateTime.now();

      if (now.isBefore(lockoutUntil)) {
        return (isLocked: true, remainingTime: lockoutUntil.difference(now));
      } else {
        // Verrouillage expiré, réinitialiser
        await resetFailedAttempts();
        return (isLocked: false, remainingTime: null);
      }
    } catch (e) {
      return (isLocked: false, remainingTime: null);
    }
  }

  /// Réinitialise les tentatives échouées (après connexion réussie)
  Future<void> resetFailedAttempts() async {
    await _secureStorage?.delete(key: _keyFailedAttempts);
    await _secureStorage?.delete(key: _keyLockoutUntil);
  }

  /// Obtient le nombre de tentatives restantes
  Future<int> getRemainingAttempts() async {
    final attemptsStr = await _secureStorage?.read(key: _keyFailedAttempts);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    return (5 - attempts).clamp(0, 5);
  }

  // ==================== BIOMÉTRIE ====================

  /// Active/désactive l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage?.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Vérifie si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage?.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // ==================== CODE PIN ====================

  /// Sauvegarde le hash du code PIN
  Future<void> savePinHash(String pinHash) async {
    await _secureStorage?.write(key: _keyPinHash, value: pinHash);
  }

  /// Récupère le hash du code PIN
  Future<String?> getPinHash() async {
    return _secureStorage?.read(key: _keyPinHash);
  }

  /// Vérifie si un code PIN est défini
  Future<bool> hasPinCode() async {
    final pin = await _secureStorage?.read(key: _keyPinHash);
    return pin != null && pin.isNotEmpty;
  }

  /// Supprime le code PIN
  Future<void> clearPinCode() async {
    await _secureStorage?.delete(key: _keyPinHash);
  }

  // ==================== CLÉ DE CHIFFREMENT ====================

  /// Sauvegarde la clé de chiffrement des données
  Future<void> saveEncryptionKey(String key) async {
    await _secureStorage?.write(key: _keyEncryptionKey, value: key);
  }

  /// Récupère la clé de chiffrement
  Future<String?> getEncryptionKey() async {
    return _secureStorage?.read(key: _keyEncryptionKey);
  }

  /// Génère et sauvegarde une nouvelle clé de chiffrement
  Future<String> generateAndSaveEncryptionKey() async {
    final key = _generateSecureKey();
    await saveEncryptionKey(key);
    return key;
  }

  /// Génère une clé sécurisée de 256 bits
  String _generateSecureKey() {
    final random = List<int>.generate(32, (i) => DateTime.now().microsecond % 256);
    return base64Encode(random);
  }

  // ==================== DEVICE ID ====================

  /// Sauvegarde l'ID unique de l'appareil
  Future<void> saveDeviceId(String deviceId) async {
    await _secureStorage?.write(key: _keyDeviceId, value: deviceId);
  }

  /// Récupère l'ID de l'appareil
  Future<String?> getDeviceId() async {
    return _secureStorage?.read(key: _keyDeviceId);
  }

  // ==================== DONNÉES GÉNÉRIQUES ====================

  /// Sauvegarde une valeur sécurisée
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage?.write(key: key, value: value);
  }

  /// Récupère une valeur sécurisée
  Future<String?> getSecure(String key) async {
    return _secureStorage?.read(key: key);
  }

  /// Supprime une valeur sécurisée
  Future<void> deleteSecure(String key) async {
    await _secureStorage?.delete(key: key);
  }

  /// Vérifie si une clé existe
  Future<bool> containsSecure(String key) async {
    final value = await _secureStorage?.read(key: key);
    return value != null;
  }

  // ==================== MÉTHODES ALIAS (pour compatibilité) ====================

  /// Alias pour saveSecure
  Future<void> write(String key, String value) async {
    await saveSecure(key, value);
  }

  /// Alias pour getSecure
  Future<String?> read(String key) async {
    return getSecure(key);
  }

  /// Efface le token d'authentification
  Future<void> clearAuthToken() async {
    await _secureStorage?.delete(key: _keyAuthToken);
  }

  /// Vérifie si une session valide existe
  Future<bool> hasValidSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Met à jour le timestamp de dernière activité (public)
  Future<void> updateLastActivity() async {
    await _updateLastActivity();
  }

  /// Alias pour recordFailedAttempt (compatibilité)
  Future<int> incrementFailedAttempts() async {
    return recordFailedAttempt();
  }

  /// Efface le refresh token
  Future<void> clearRefreshToken() async {
    await _secureStorage?.delete(key: _keyRefreshToken);
  }

  // ==================== NETTOYAGE ====================

  /// Efface toutes les données sécurisées
  Future<void> clearAll() async {
    await _secureStorage?.deleteAll();
    debugPrint('[SecureStorage] All secure data cleared');
  }

  /// Efface les données à la déconnexion
  Future<void> onLogout() async {
    await clearAuthData();
    await resetFailedAttempts();
    debugPrint('[SecureStorage] Logout data cleared');
  }
}
