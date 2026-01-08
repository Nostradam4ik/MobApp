import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ad_service.dart';

/// Widget pour afficher une publicité native dans une liste
class NativeAdWidget extends StatefulWidget {
  final String adId;
  final double height;

  const NativeAdWidget({
    super.key,
    required this.adId,
    this.height = 100,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    // Ne pas disposer l'ad ici, elle est gérée par AdService
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (!AdService.shouldShowAds()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Vérifier si l'ad est déjà en cache
    final cachedAd = AdService.getNativeAd(widget.adId);
    if (cachedAd != null) {
      setState(() {
        _nativeAd = cachedAd;
        _isLoaded = true;
        _isLoading = false;
      });
      return;
    }

    // Charger une nouvelle ad
    final ad = await AdService.loadNativeAd(widget.adId);
    if (mounted && ad != null) {
      setState(() {
        _nativeAd = ad;
        _isLoaded = true;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne rien afficher si les pubs sont désactivées
    if (!AdService.shouldShowAds()) {
      return const SizedBox.shrink();
    }

    // Afficher un placeholder pendant le chargement
    if (!_isLoaded || _nativeAd == null) {
      return _buildPlaceholder();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            AdWidget(ad: _nativeAd!),
            // Badge "Ad"
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Widget pour afficher une native ad dans le style carte dépense
class NativeAdExpenseCard extends StatefulWidget {
  final String adId;

  const NativeAdExpenseCard({
    super.key,
    required this.adId,
  });

  @override
  State<NativeAdExpenseCard> createState() => _NativeAdExpenseCardState();
}

class _NativeAdExpenseCardState extends State<NativeAdExpenseCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AdService.shouldShowAds()) return;

    final cachedAd = AdService.getNativeAd(widget.adId);
    if (cachedAd != null) {
      setState(() {
        _nativeAd = cachedAd;
        _isLoaded = true;
      });
      return;
    }

    final ad = await AdService.loadNativeAd(widget.adId);
    if (mounted && ad != null) {
      setState(() {
        _nativeAd = ad;
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.shouldShowAds()) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceDark,
            AppColors.surfaceDark.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoaded && _nativeAd != null
            ? SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    AdWidget(ad: _nativeAd!),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sponsorisé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _buildLoadingState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.glassDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.glassDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper pour calculer les indices avec les native ads
class NativeAdHelper {
  /// Intervalle entre les publicités (tous les N éléments)
  static const int adInterval = 5;

  /// Calcule l'index réel de l'élément dans la liste originale
  static int getRealIndex(int listIndex) {
    if (listIndex < adInterval) return listIndex;
    final adsBeforeIndex = listIndex ~/ (adInterval + 1);
    return listIndex - adsBeforeIndex;
  }

  /// Vérifie si l'index correspond à une publicité
  static bool isAdIndex(int listIndex) {
    if (listIndex < adInterval) return false;
    return (listIndex + 1) % (adInterval + 1) == 0;
  }

  /// Calcule le nombre total d'éléments (items + ads)
  static int getTotalCount(int itemCount) {
    if (!AdService.shouldShowAds() || itemCount == 0) return itemCount;
    final adsCount = itemCount ~/ adInterval;
    return itemCount + adsCount;
  }

  /// Génère un ID unique pour la publicité à cet index
  static String getAdId(int listIndex) {
    final adNumber = listIndex ~/ (adInterval + 1);
    return 'list_native_ad_$adNumber';
  }
}
