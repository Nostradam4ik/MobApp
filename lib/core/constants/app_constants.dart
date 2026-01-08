// ============================================================================
// SmartSpend - Constantes de l'application
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

/// Constantes de l'application
class AppConstants {
  AppConstants._();

  // Storage keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLastSyncDate = 'last_sync_date';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  // Cache duration
  static const Duration cacheDuration = Duration(minutes: 5);

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int maxNoteLength = 500;
  static const double maxExpenseAmount = 999999.99;

  // Date formats
  static const String dateFormatShort = 'dd/MM';
  static const String dateFormatMedium = 'dd MMM';
  static const String dateFormatFull = 'dd MMMM yyyy';
  static const String dateFormatMonth = 'MMMM yyyy';

  // Quick expense amounts
  static const List<double> quickAmounts = [5, 10, 20, 50, 100];
}

/// Constantes de sécurité
class SecurityConstants {
  SecurityConstants._();

  // ==================== MOT DE PASSE ====================

  /// Longueur minimale du mot de passe (OWASP recommande 12+)
  static const int minPasswordLength = 12;

  /// Longueur maximale (éviter DoS)
  static const int maxPasswordLength = 128;

  /// Force minimale requise (0-10)
  static const int minPasswordStrength = 6;

  // ==================== CODE PIN ====================

  /// Longueur minimale du PIN
  static const int minPinLength = 4;

  /// Longueur maximale du PIN
  static const int maxPinLength = 8;

  // ==================== SESSION ====================

  /// Durée de session (30 minutes d'inactivité)
  static const Duration sessionTimeout = Duration(minutes: 30);

  /// Durée du token de rafraîchissement
  static const Duration refreshTokenExpiry = Duration(days: 7);

  /// Durée avant expiration pour rafraîchir
  static const Duration refreshThreshold = Duration(minutes: 5);

  // ==================== ANTI-BRUTEFORCE ====================

  /// Nombre max de tentatives avant verrouillage
  static const int maxLoginAttempts = 5;

  /// Durée du verrouillage initial (1 minute)
  static const Duration initialLockoutDuration = Duration(minutes: 1);

  /// Durée maximale de verrouillage (30 minutes)
  static const Duration maxLockoutDuration = Duration(minutes: 30);

  /// Multiplicateur pour backoff exponentiel
  static const double lockoutMultiplier = 2.0;

  // ==================== ENCRYPTION ====================

  /// Longueur de clé AES (256 bits)
  static const int aesKeyLength = 32;

  /// Longueur IV (128 bits)
  static const int ivLength = 16;

  /// Longueur du sel pour hash
  static const int saltLength = 16;

  /// Nombre d'itérations PBKDF2
  static const int pbkdf2Iterations = 100000;

  // ==================== TOKENS ====================

  /// Longueur des tokens sécurisés
  static const int secureTokenLength = 32;

  /// Longueur du code de vérification
  static const int verificationCodeLength = 6;

  // ==================== RATE LIMITING ====================

  /// Nombre max de requêtes par minute
  static const int maxRequestsPerMinute = 60;

  /// Nombre max de requêtes d'auth par heure
  static const int maxAuthRequestsPerHour = 10;

  // ==================== BIOMÉTRIE ====================

  /// Timeout pour ré-authentification biométrique
  static const Duration biometricReauthTimeout = Duration(minutes: 5);

  /// Timeout pour opérations sensibles
  static const Duration sensitiveOperationTimeout = Duration(minutes: 2);

  // ==================== STOCKAGE ====================

  /// Clés de stockage sécurisé
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keySessionExpiry = 'session_expiry';
  static const String keyPinHash = 'pin_hash';
  static const String keyEncryptionKey = 'encryption_key';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyFailedAttempts = 'failed_attempts';
  static const String keyLockoutUntil = 'lockout_until';
  static const String keyLastActivity = 'last_activity';

  // ==================== RÉSEAU ====================

  /// Timeout de connexion
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Timeout de réception
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Nombre de tentatives de retry
  static const int maxRetries = 3;

  /// Domaines autorisés
  static const List<String> allowedDomains = [
    'supabase.co',
    'supabase.com',
  ];

  // ==================== VALIDATION ====================

  /// Longueur max nom
  static const int maxNameLength = 50;

  /// Longueur max email
  static const int maxEmailLength = 254;

  /// Longueur max texte
  static const int maxTextLength = 1000;

  /// Longueur max URL
  static const int maxUrlLength = 2048;
}

/// Types de revenus
enum IncomeType {
  fixed('fixed', 'Fixe'),
  variable('variable', 'Variable');

  const IncomeType(this.value, this.label);
  final String value;
  final String label;

  static IncomeType fromString(String value) {
    return IncomeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IncomeType.fixed,
    );
  }
}

/// Périodes pour les statistiques
enum StatsPeriod {
  day('Jour'),
  week('Semaine'),
  month('Mois'),
  year('Année');

  const StatsPeriod(this.label);
  final String label;
}

/// Types d'insight
enum InsightType {
  warning('warning'),
  tip('tip'),
  achievement('achievement'),
  prediction('prediction');

  const InsightType(this.value);
  final String value;
}
