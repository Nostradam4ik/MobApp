import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/ad_service.dart';

/// Widget de bannière publicitaire
/// S'affiche uniquement pour les utilisateurs gratuits
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.shouldShowAds()) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed: $error');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        // Ne pas afficher si premium
        if (subscription.isPremium) {
          return const SizedBox.shrink();
        }

        // Ne pas afficher si l'ad n'est pas chargée
        if (!_isAdLoaded || _bannerAd == null) {
          return const SizedBox(height: 50);
        }

        return Container(
          alignment: Alignment.center,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }
}

/// Widget de bannière publicitaire en bas de l'écran
class BottomAdBanner extends StatelessWidget {
  const BottomAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: const SafeArea(
            top: false,
            child: AdBannerWidget(),
          ),
        );
      },
    );
  }
}
