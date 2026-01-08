/// Configuration de la monétisation (RevenueCat + AdMob)
///
/// INSTRUCTIONS DE CONFIGURATION:
///
/// 1. RevenueCat (Achats in-app):
///    - Créez un compte sur https://app.revenuecat.com
///    - Créez un projet et liez-le à Google Play Console et/ou App Store Connect
///    - Créez vos produits (mensuel, annuel, à vie) dans les stores
///    - Configurez les produits dans RevenueCat Dashboard
///    - Copiez vos clés API ci-dessous
///
/// 2. AdMob (Publicités):
///    - Créez un compte sur https://admob.google.com
///    - Créez une app Android et/ou iOS
///    - Créez des blocs d'annonces (bannière + interstitiel)
///    - Copiez vos IDs ci-dessous
///    - N'oubliez pas de configurer AndroidManifest.xml et Info.plist
///
/// 3. Après configuration:
///    - Décommentez le code dans PurchaseService.init()
///    - Testez en mode debug avec les IDs de test
///    - Passez en production uniquement après validation

class MonetizationConfig {
  MonetizationConfig._();

  // ============================================================
  // REVENUECAT - Achats in-app
  // ============================================================

  /// Clé API RevenueCat pour Android
  /// Trouvez-la dans: RevenueCat Dashboard > Project Settings > API Keys
  static const String revenueCatAndroidKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';

  /// Clé API RevenueCat pour iOS
  /// Trouvez-la dans: RevenueCat Dashboard > Project Settings > API Keys
  static const String revenueCatIosKey = 'YOUR_REVENUECAT_IOS_API_KEY';

  /// IDs des produits (doivent correspondre à ceux créés dans les stores)
  static const String productMonthly = 'smartspend_premium_monthly';
  static const String productYearly = 'smartspend_premium_yearly';
  static const String productLifetime = 'smartspend_premium_lifetime';

  /// Nom de l'entitlement Premium dans RevenueCat
  static const String premiumEntitlement = 'premium';

  // ============================================================
  // ADMOB - Publicités
  // ============================================================

  /// ID de l'app AdMob pour Android
  /// Trouvez-le dans: AdMob > Apps > Votre app > App settings
  /// Doit aussi être ajouté dans android/app/src/main/AndroidManifest.xml
  static const String admobAndroidAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  /// ID de l'app AdMob pour iOS
  /// Trouvez-le dans: AdMob > Apps > Votre app > App settings
  /// Doit aussi être ajouté dans ios/Runner/Info.plist
  static const String admobIosAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  /// ID du bloc bannière Android
  /// Trouvez-le dans: AdMob > Apps > Votre app > Ad units
  static const String bannerAdUnitIdAndroid = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';

  /// ID du bloc bannière iOS
  static const String bannerAdUnitIdIos = 'YOUR_IOS_BANNER_AD_UNIT_ID';

  /// ID du bloc interstitiel Android
  static const String interstitialAdUnitIdAndroid = 'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';

  /// ID du bloc interstitiel iOS
  static const String interstitialAdUnitIdIos = 'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';

  /// ID du bloc Native Ad Android
  static const String nativeAdUnitIdAndroid = 'YOUR_ANDROID_NATIVE_AD_UNIT_ID';

  /// ID du bloc Native Ad iOS
  static const String nativeAdUnitIdIos = 'YOUR_IOS_NATIVE_AD_UNIT_ID';

  // ============================================================
  // IDs DE TEST (Ne pas modifier)
  // ============================================================

  /// Ces IDs sont fournis par Google pour les tests
  /// Ils affichent des publicités de test et ne génèrent pas de revenus

  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  // ============================================================
  // HELPERS
  // ============================================================

  /// Vérifie si RevenueCat est configuré
  static bool get isRevenueCatConfigured =>
      revenueCatAndroidKey != 'YOUR_REVENUECAT_ANDROID_API_KEY' ||
      revenueCatIosKey != 'YOUR_REVENUECAT_IOS_API_KEY';

  /// Vérifie si AdMob est configuré pour la production
  static bool get isAdMobConfigured =>
      bannerAdUnitIdAndroid != 'YOUR_ANDROID_BANNER_AD_UNIT_ID' ||
      bannerAdUnitIdIos != 'YOUR_IOS_BANNER_AD_UNIT_ID';
}
