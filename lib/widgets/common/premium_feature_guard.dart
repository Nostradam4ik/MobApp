import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_service.dart';

/// Widget qui protège une fonctionnalité premium
/// Affiche le contenu enfant si l'utilisateur est premium,
/// sinon affiche un message et redirige vers l'écran premium
class PremiumFeatureGuard extends StatelessWidget {
  final Widget child;
  final PremiumFeature feature;
  final bool showLockOverlay;

  const PremiumFeatureGuard({
    super.key,
    required this.child,
    required this.feature,
    this.showLockOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isPremium) {
          return child;
        }

        if (!showLockOverlay) {
          return child;
        }

        return _buildLockedView(context, subscription);
      },
    );
  }

  Widget _buildLockedView(BuildContext context, SubscriptionProvider subscription) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Contenu flouté/grisé
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.grey.withValues(alpha: 0.5),
            BlendMode.saturation,
          ),
          child: IgnorePointer(child: child),
        ),

        // Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône verrou
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.premiumGradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Fonctionnalité Premium',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      subscription.getLimitMessage(feature),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () => context.push('/premium'),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('Passer à Premium'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour un bouton/lien qui nécessite premium
/// Affiche une icône de cadenas à côté si non premium
class PremiumListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final PremiumFeature feature;

  const PremiumListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        final isPremium = subscription.isPremium;

        return ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: isPremium
              ? trailing
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.premiumGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
          onTap: isPremium
              ? onTap
              : () {
                  _showPremiumDialog(context, subscription);
                },
        );
      },
    );
  }

  void _showPremiumDialog(BuildContext context, SubscriptionProvider subscription) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.premiumGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Fonctionnalité Premium'),
          ],
        ),
        content: Text(subscription.getLimitMessage(feature)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Voir Premium'),
          ),
        ],
      ),
    );
  }
}

/// Badge premium à afficher à côté des éléments
class PremiumBadge extends StatelessWidget {
  final double size;

  const PremiumBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.premiumGradient),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium,
                size: size * 0.8,
                color: Colors.white,
              ),
              const SizedBox(width: 2),
              Text(
                'PRO',
                style: TextStyle(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
