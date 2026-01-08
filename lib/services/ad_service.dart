import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/config/monetization_config.dart';
import 'subscription_service.dart';

/// Service de gestion des publicités AdMob
class AdService {
  AdService._();

  static bool _isInitialized = false;
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  // Cache pour les Native Ads
  static final Map<String, NativeAd> _nativeAdCache = {};
  static int _nativeAdLoadAttempts = 0;

  /// ID du bloc bannière (utilise les IDs de test en debug)
  static String get bannerAdUnitId {
    if (kDebugMode) {
      // IDs de test officiels Google
      if (defaultTargetPlatform == TargetPlatform.android) {
        return MonetizationConfig.testBannerAndroid;
      } else {
        return MonetizationConfig.testBannerIos;
      }
    }
    // IDs de production
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MonetizationConfig.bannerAdUnitIdAndroid;
    } else {
      return MonetizationConfig.bannerAdUnitIdIos;
    }
  }

  /// ID du bloc interstitiel (utilise les IDs de test en debug)
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return MonetizationConfig.testInterstitialAndroid;
      } else {
        return MonetizationConfig.testInterstitialIos;
      }
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MonetizationConfig.interstitialAdUnitIdAndroid;
    } else {
      return MonetizationConfig.interstitialAdUnitIdIos;
    }
  }

  /// ID du bloc native ad (utilise les IDs de test en debug)
  static String get nativeAdUnitId {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return MonetizationConfig.testNativeAndroid;
      } else {
        return MonetizationConfig.testNativeIos;
      }
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MonetizationConfig.nativeAdUnitIdAndroid;
    } else {
      return MonetizationConfig.nativeAdUnitIdIos;
    }
  }

  /// Initialise le SDK AdMob
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized');

      // Précharger les ads si l'utilisateur n'est pas premium
      if (!SubscriptionService.isPremium()) {
        loadBannerAd();
        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
  }

  /// Vérifie si les pubs doivent être affichées
  static bool shouldShowAds() {
    return !SubscriptionService.isPremium();
  }

  /// Charge une bannière publicitaire
  static void loadBannerAd() {
    if (!_isInitialized || !shouldShowAds()) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );

    _bannerAd?.load();
  }

  /// Récupère la bannière publicitaire
  static BannerAd? get bannerAd => _bannerAd;

  /// Charge une pub interstitielle
  static void loadInterstitialAd() {
    if (!_isInitialized || !shouldShowAds()) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialLoadAttempts++;
          _interstitialAd = null;

          if (_interstitialLoadAttempts < maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Affiche une pub interstitielle
  static Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (!shouldShowAds()) {
      onAdDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      loadInterstitialAd();
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    await _interstitialAd!.show();
  }

  // ============================================================
  // NATIVE ADS
  // ============================================================

  /// Charge une native ad avec un ID unique
  static Future<NativeAd?> loadNativeAd(String id) async {
    if (!_isInitialized || !shouldShowAds()) return null;

    // Retourner l'ad en cache si elle existe
    if (_nativeAdCache.containsKey(id)) {
      return _nativeAdCache[id];
    }

    final completer = Completer<NativeAd?>();

    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native ad loaded: $id');
          _nativeAdCache[id] = ad as NativeAd;
          _nativeAdLoadAttempts = 0;
          completer.complete(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
          _nativeAdLoadAttempts++;

          if (_nativeAdLoadAttempts < maxFailedLoadAttempts) {
            // Réessayer après un délai
            Future.delayed(const Duration(seconds: 2), () {
              loadNativeAd(id);
            });
          }
          completer.complete(null);
        },
        onAdOpened: (ad) => debugPrint('Native ad opened'),
        onAdClosed: (ad) => debugPrint('Native ad closed'),
        onAdClicked: (ad) => debugPrint('Native ad clicked'),
      ),
    );

    nativeAd.load();
    return completer.future;
  }

  /// Récupère une native ad du cache
  static NativeAd? getNativeAd(String id) {
    return _nativeAdCache[id];
  }

  /// Précharge plusieurs native ads
  static Future<void> preloadNativeAds(int count) async {
    if (!shouldShowAds()) return;

    for (int i = 0; i < count; i++) {
      await loadNativeAd('native_ad_$i');
    }
  }

  /// Libère une native ad spécifique
  static void disposeNativeAd(String id) {
    _nativeAdCache[id]?.dispose();
    _nativeAdCache.remove(id);
  }

  /// Libère toutes les native ads
  static void disposeAllNativeAds() {
    for (final ad in _nativeAdCache.values) {
      ad.dispose();
    }
    _nativeAdCache.clear();
  }

  /// Libère les ressources
  static void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    disposeAllNativeAds();
  }
}
