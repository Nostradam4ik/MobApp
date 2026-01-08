/// Configuration globale de l'application
class AppConfig {
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'SmartSpend';

  /// Version de l'application
  static const String version = '1.0.0';

  /// Devise par défaut
  static const String defaultCurrency = 'EUR';

  /// Symboles des devises supportées
  static const Map<String, String> currencySymbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'CHF': 'CHF',
    'CAD': 'CA\$',
    'MAD': 'DH',
    'XOF': 'CFA',
  };

  /// Seuil d'alerte budget par défaut (%)
  static const int defaultBudgetAlertThreshold = 80;

  /// Nombre maximum d'objectifs en version gratuite
  static const int freeMaxGoals = 3;

  /// Prix Premium mensuel
  static const double premiumMonthlyPrice = 3.99;

  /// Prix Premium annuel
  static const double premiumYearlyPrice = 29.99;

  /// Durée animation rapide (ms)
  static const int animationFast = 200;

  /// Durée animation normale (ms)
  static const int animationNormal = 300;

  /// Durée animation lente (ms)
  static const int animationSlow = 500;

  // ============ URLs LÉGALES ============
  // TODO: Remplacer par vos vraies URLs une fois les pages créées

  /// URL de la politique de confidentialité
  static const String privacyPolicyUrl = 'https://smartspend.app/privacy';

  /// URL des conditions d'utilisation
  static const String termsOfServiceUrl = 'https://smartspend.app/terms';

  /// URL de support
  static const String supportUrl = 'https://smartspend.app/support';

  /// Email de support
  static const String supportEmail = 'support@smartspend.app';

  // ============ AUTEUR ============

  /// Nom de l'auteur
  static const String authorName = 'Andrii Zhmuryk';

  /// LinkedIn de l'auteur
  static const String authorLinkedIn = 'https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/';
}
