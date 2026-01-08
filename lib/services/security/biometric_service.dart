import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'secure_storage_service.dart';

/// Service d'authentification biométrique
/// Gère Face ID, Touch ID, et empreintes digitales Android
class BiometricService {
  static BiometricService? _instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  SecureStorageService? _secureStorage;

  BiometricService._();

  static Future<BiometricService> getInstance() async {
    if (_instance == null) {
      _instance = BiometricService._();
      _instance!._secureStorage = await SecureStorageService.getInstance();
    }
    return _instance!;
  }

  // ==================== VÉRIFICATION DISPONIBILITÉ ====================

  /// Vérifie si le dispositif supporte la biométrie
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Vérifie si la biométrie peut être utilisée
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Obtient les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Vérifie si la biométrie est configurée sur l'appareil
  Future<BiometricStatus> checkBiometricStatus() async {
    final isSupported = await isDeviceSupported();
    if (!isSupported) {
      return BiometricStatus.notSupported;
    }

    final canCheck = await canCheckBiometrics();
    if (!canCheck) {
      return BiometricStatus.notEnrolled;
    }

    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return BiometricStatus.notEnrolled;
    }

    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) {
      return BiometricStatus.disabled;
    }

    return BiometricStatus.available;
  }

  /// Obtient une description lisible des biométries disponibles
  Future<String> getBiometricTypeDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Empreinte digitale';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Reconnaissance iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biométrie forte';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biométrie';
    }

    return 'Non disponible';
  }

  // ==================== AUTHENTIFICATION ====================

  /// Authentifie l'utilisateur avec la biométrie
  Future<BiometricResult> authenticate({
    String reason = 'Veuillez vous authentifier pour accéder à SmartSpend',
    bool biometricOnly = false,
  }) async {
    try {
      // Vérifier si la biométrie est activée
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return BiometricResult(
          success: false,
          error: BiometricError.disabled,
          message: 'Authentification biométrique désactivée',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        // Enregistrer la dernière authentification réussie
        await _recordSuccessfulAuth();

        return BiometricResult(
          success: true,
          message: 'Authentification réussie',
        );
      } else {
        return BiometricResult(
          success: false,
          error: BiometricError.failed,
          message: 'Authentification échouée',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Authentifie pour une opération sensible (transfert, modification)
  Future<BiometricResult> authenticateForSensitiveOperation({
    required String operationDescription,
  }) async {
    return authenticate(
      reason: 'Confirmez votre identité pour: $operationDescription',
      biometricOnly: true,
    );
  }

  /// Gère les exceptions de plateforme
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notEnrolled:
        return BiometricResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: 'Aucune biométrie enregistrée sur cet appareil',
        );
      case auth_error.lockedOut:
        return BiometricResult(
          success: false,
          error: BiometricError.lockedOut,
          message: 'Trop de tentatives. Réessayez plus tard.',
        );
      case auth_error.permanentlyLockedOut:
        return BiometricResult(
          success: false,
          error: BiometricError.permanentlyLockedOut,
          message: 'Biométrie bloquée. Utilisez votre code PIN.',
        );
      case auth_error.notAvailable:
        return BiometricResult(
          success: false,
          error: BiometricError.notAvailable,
          message: 'Biométrie non disponible',
        );
      case auth_error.passcodeNotSet:
        return BiometricResult(
          success: false,
          error: BiometricError.passcodeNotSet,
          message: 'Aucun code de verrouillage configuré',
        );
      case auth_error.otherOperatingSystem:
        return BiometricResult(
          success: false,
          error: BiometricError.notSupported,
          message: 'Système non supporté',
        );
      default:
        return BiometricResult(
          success: false,
          error: BiometricError.unknown,
          message: 'Erreur inconnue: ${e.message}',
        );
    }
  }

  // ==================== CONFIGURATION ====================

  /// Active l'authentification biométrique
  Future<bool> enableBiometric() async {
    // Vérifier d'abord que la biométrie est disponible
    final status = await checkBiometricStatus();
    if (status == BiometricStatus.notSupported ||
        status == BiometricStatus.notEnrolled) {
      return false;
    }

    // Demander une authentification pour activer
    final result = await authenticate(
      reason: 'Authentifiez-vous pour activer la biométrie',
    );

    if (result.success) {
      await _secureStorage?.setBiometricEnabled(true);
      return true;
    }

    return false;
  }

  /// Désactive l'authentification biométrique
  Future<void> disableBiometric() async {
    await _secureStorage?.setBiometricEnabled(false);
  }

  /// Vérifie si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    return await _secureStorage?.isBiometricEnabled() ?? false;
  }

  // ==================== GESTION SESSION ====================

  /// Enregistre une authentification réussie
  Future<void> _recordSuccessfulAuth() async {
    await _secureStorage?.write(
      'last_biometric_auth',
      DateTime.now().toIso8601String(),
    );
  }

  /// Obtient la dernière authentification biométrique
  Future<DateTime?> getLastBiometricAuth() async {
    final value = await _secureStorage?.read('last_biometric_auth');
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Vérifie si une ré-authentification est nécessaire
  Future<bool> needsReauthentication({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final lastAuth = await getLastBiometricAuth();
    if (lastAuth == null) return true;

    final elapsed = DateTime.now().difference(lastAuth);
    return elapsed > timeout;
  }

  /// Annule toute authentification en cours
  Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}

/// Statut de disponibilité de la biométrie
enum BiometricStatus {
  /// Biométrie disponible et activée
  available,

  /// Appareil ne supporte pas la biométrie
  notSupported,

  /// Biométrie supportée mais pas configurée
  notEnrolled,

  /// Biométrie disponible mais désactivée dans l'app
  disabled,
}

/// Types d'erreurs biométriques
enum BiometricError {
  /// Authentification échouée
  failed,

  /// Aucune biométrie enregistrée
  notEnrolled,

  /// Trop de tentatives
  lockedOut,

  /// Blocage permanent
  permanentlyLockedOut,

  /// Non disponible
  notAvailable,

  /// Aucun code de verrouillage
  passcodeNotSet,

  /// Désactivé par l'utilisateur
  disabled,

  /// Système non supporté
  notSupported,

  /// Erreur inconnue
  unknown,
}

/// Résultat d'une tentative d'authentification biométrique
class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String message;

  BiometricResult({
    required this.success,
    this.error,
    required this.message,
  });

  @override
  String toString() => 'BiometricResult(success: $success, message: $message)';
}
