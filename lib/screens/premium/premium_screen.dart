import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_service.dart';
import '../../services/purchase_service.dart';

/// Écran Premium / Paywall
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Offerings? _offerings;
  bool _isLoadingOfferings = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await PurchaseService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoadingOfferings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscription, _) {
            if (subscription.isPremium) {
              return _buildPremiumActiveView(context, isDark, subscription);
            }
            return _buildPaywallView(context, isDark, subscription);
          },
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView(
    BuildContext context,
    bool isDark,
    SubscriptionProvider subscription,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header avec bouton retour
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Badge Premium
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.premiumGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous êtes Premium !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subscription.daysRemaining != null
                      ? '${subscription.daysRemaining} jours restants'
                      : 'Abonnement à vie',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Liste des avantages actifs
          Text(
            'Vos avantages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          ...PremiumFeature.values.map((feature) {
            return _buildFeatureItem(
              context,
              isDark,
              feature.label,
              true,
            );
          }),

          const SizedBox(height: 32),

          // Bouton pour annuler (à des fins de test)
          TextButton(
            onPressed: () => _showCancelDialog(context, subscription),
            child: Text(
              'Annuler l\'abonnement',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallView(
    BuildContext context,
    bool isDark,
    SubscriptionProvider subscription,
  ) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.backgroundDark,
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.backgroundDark,
                    ]
                  : [
                      AppColors.background,
                      AppColors.primaryLight,
                      AppColors.background,
                    ],
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header avec bouton fermer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    onPressed: () => _restorePurchases(context, subscription),
                    child: Text(
                      'Restaurer',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Logo Premium
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Titre
              Text(
                'SmartSpend Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Débloquez toutes les fonctionnalités',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Features gratuites vs premium
              _buildComparisonCard(context, isDark),

              const SizedBox(height: 24),

              // Liste des fonctionnalités premium
              Text(
                'Fonctionnalités Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(context, isDark, 'Catégories illimitées', false),
              _buildFeatureItem(context, isDark, 'Budgets illimités', false),
              _buildFeatureItem(context, isDark, 'Objectifs illimités', false),
              _buildFeatureItem(context, isDark, 'Graphiques avancés', false),
              _buildFeatureItem(context, isDark, 'Import/Export CSV', false),
              _buildFeatureItem(context, isDark, 'Synchronisation cloud', false),
              _buildFeatureItem(context, isDark, 'Dépenses récurrentes', false),
              _buildFeatureItem(context, isDark, 'Sans publicités', false),

              const SizedBox(height: 32),

              // Essai gratuit
              if (subscription.canStartTrial)
                _buildFreeTrialButton(context, isDark, subscription),

              if (subscription.canStartTrial)
                const SizedBox(height: 16),

              // Prix et boutons d'achat
              _buildPricingSection(context, isDark, subscription),

              const SizedBox(height: 24),

              // Mentions légales
              Text(
                'L\'abonnement sera renouvelé automatiquement sauf si annulé au moins 24h avant la fin de la période en cours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openUrl(AppConfig.termsOfServiceUrl),
                    child: Text(
                      'Conditions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openUrl(AppConfig.privacyPolicyUrl),
                    child: Text(
                      'Confidentialité',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),

        // Loading overlay
        if (subscription.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gratuit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.premiumGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comparaisons
          _buildComparisonRow(context, isDark, 'Catégories', '5 max', 'Illimité'),
          _buildComparisonRow(context, isDark, 'Budgets', '1 max', 'Illimité'),
          _buildComparisonRow(context, isDark, 'Objectifs', '1 max', 'Illimité'),
          _buildComparisonRow(context, isDark, 'Statistiques', 'Basiques', 'Avancées'),
          _buildComparisonRow(context, isDark, 'Import/Export', '—', '✓'),
          _buildComparisonRow(context, isDark, 'Sync cloud', '—', '✓'),
          _buildComparisonRow(context, isDark, 'Publicités', 'Oui', 'Non'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    bool isDark,
    String feature,
    String freeValue,
    String premiumValue,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              premiumValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    bool isDark,
    String text,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : AppColors.accentGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: isActive ? AppColors.secondary : AppColors.accentGold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(
    BuildContext context,
    bool isDark,
    SubscriptionProvider subscription,
  ) {
    return Column(
      children: [
        // Option mensuelle
        _buildPriceOption(
          context,
          isDark,
          title: 'Mensuel',
          price: '2,99 €',
          period: '/mois',
          isPopular: false,
          onTap: () => _purchaseMonthly(context, subscription),
        ),

        const SizedBox(height: 12),

        // Option annuelle (mise en avant)
        _buildPriceOption(
          context,
          isDark,
          title: 'Annuel',
          price: '19,99 €',
          period: '/an',
          savings: 'Économisez 44%',
          isPopular: true,
          onTap: () => _purchaseYearly(context, subscription),
        ),

        const SizedBox(height: 12),

        // Option à vie
        _buildPriceOption(
          context,
          isDark,
          title: 'À vie',
          price: '49,99 €',
          period: 'paiement unique',
          isPopular: false,
          onTap: () => _purchaseLifetime(context, subscription),
        ),
      ],
    );
  }

  Widget _buildPriceOption(
    BuildContext context,
    bool isDark, {
    required String title,
    required String price,
    required String period,
    String? savings,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(colors: AppColors.premiumGradient)
              : null,
          color: isPopular
              ? null
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: isPopular
              ? null
              : Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPopular
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'POPULAIRE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      savings,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPopular
                            ? Colors.white70
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPopular
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPopular
                        ? Colors.white70
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseMonthly(BuildContext context, SubscriptionProvider subscription) async {
    await _purchasePackage(context, subscription, 'monthly');
  }

  void _purchaseYearly(BuildContext context, SubscriptionProvider subscription) async {
    await _purchasePackage(context, subscription, 'yearly');
  }

  void _purchaseLifetime(BuildContext context, SubscriptionProvider subscription) async {
    await _purchasePackage(context, subscription, 'lifetime');
  }

  /// Achète un package via RevenueCat
  Future<void> _purchasePackage(
    BuildContext context,
    SubscriptionProvider subscription,
    String packageType,
  ) async {
    // Récupérer le package correspondant
    Package? package;
    if (_offerings?.current != null) {
      switch (packageType) {
        case 'monthly':
          package = _offerings!.current!.monthly;
          break;
        case 'yearly':
          package = _offerings!.current!.annual;
          break;
        case 'lifetime':
          package = _offerings!.current!.lifetime;
          break;
      }
    }

    // Si pas de package disponible (RevenueCat non configuré), utiliser le mode simulation
    if (package == null) {
      await _simulatePurchase(context, subscription, packageType);
      return;
    }

    // Acheter via RevenueCat
    final result = await PurchaseService.purchase(package);

    if (!context.mounted) return;

    if (result.success) {
      subscription.refresh();
      _showSuccessSnackbar(context, 'Bienvenue dans Premium !');
    } else if (result.cancelled) {
      // Achat annulé par l'utilisateur - ne rien afficher
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Erreur lors de l\'achat'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Mode simulation quand RevenueCat n'est pas configuré
  Future<void> _simulatePurchase(
    BuildContext context,
    SubscriptionProvider subscription,
    String packageType,
  ) async {
    String price;
    String period;
    Duration? duration;

    switch (packageType) {
      case 'monthly':
        price = '2,99€';
        period = '/mois';
        duration = const Duration(days: 30);
        break;
      case 'yearly':
        price = '19,99€';
        period = '/an';
        duration = const Duration(days: 365);
        break;
      case 'lifetime':
        price = '49,99€';
        period = '';
        duration = null;
        break;
      default:
        return;
    }

    final confirmed = await _showPurchaseConfirmation(
      context,
      'Mode Simulation',
      'RevenueCat non configuré.\n\nVoulez-vous simuler un achat à $price$period ?',
    );

    if (confirmed == true) {
      final expiry = duration != null ? DateTime.now().add(duration) : null;
      await subscription.activatePremium(expiryDate: expiry);
      if (context.mounted) {
        _showSuccessSnackbar(context, 'Bienvenue dans Premium !');
      }
    }
  }

  Future<bool?> _showPurchaseConfirmation(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _restorePurchases(BuildContext context, SubscriptionProvider subscription) async {
    final restored = await subscription.restorePurchases();
    if (context.mounted) {
      if (restored) {
        _showSuccessSnackbar(context, 'Achats restaurés !');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun achat trouvé'),
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, SubscriptionProvider subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler Premium ?'),
        content: const Text(
          'Vous perdrez l\'accès à toutes les fonctionnalités Premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () async {
              await subscription.deactivatePremium();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abonnement annulé')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildFreeTrialButton(
    BuildContext context,
    bool isDark,
    SubscriptionProvider subscription,
  ) {
    return GestureDetector(
      onTap: () => _startFreeTrial(context, subscription),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Essai Gratuit 7 jours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Testez toutes les fonctionnalités Premium gratuitement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sans engagement • Annulation facile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startFreeTrial(BuildContext context, SubscriptionProvider subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Essai Gratuit'),
          ],
        ),
        content: const Text(
          'Vous allez bénéficier de 7 jours d\'accès Premium gratuit.\n\n'
          'Aucun paiement requis maintenant.\n'
          'L\'essai se termine automatiquement après 7 jours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Commencer l\'essai'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await subscription.startFreeTrial();
      if (context.mounted) {
        if (success) {
          _showSuccessSnackbar(context, 'Essai gratuit activé ! Profitez de Premium pendant 7 jours.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('L\'essai gratuit a déjà été utilisé'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
