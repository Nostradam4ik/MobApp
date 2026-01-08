import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_service.dart';

/// Widget qui affiche le compteur de limites (ex: "2/5 catégories")
class LimitCounterWidget extends StatelessWidget {
  final int currentCount;
  final int maxCount;
  final String label;
  final PremiumFeature feature;
  final bool showUpgradeButton;

  const LimitCounterWidget({
    super.key,
    required this.currentCount,
    required this.maxCount,
    required this.label,
    required this.feature,
    this.showUpgradeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        // Si premium, afficher "illimité"
        if (subscription.isPremium) {
          return _buildUnlimitedBadge(isDark);
        }

        final isAtLimit = currentCount >= maxCount;
        final percentage = (currentCount / maxCount).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAtLimit
                  ? AppColors.warning.withOpacity(0.5)
                  : (isDark ? AppColors.dividerDark : AppColors.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$currentCount / $maxCount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAtLimit
                          ? AppColors.warning
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAtLimit ? AppColors.warning : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              if (isAtLimit && showUpgradeButton) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.premium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.premiumGradient),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Passer à illimité',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnlimitedBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive, color: AppColors.secondary, size: 16),
          SizedBox(width: 6),
          Text(
            'Illimité',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compact pour afficher dans les headers
class LimitBadge extends StatelessWidget {
  final int currentCount;
  final int maxCount;
  final PremiumFeature feature;

  const LimitBadge({
    super.key,
    required this.currentCount,
    required this.maxCount,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isPremium) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.all_inclusive, color: AppColors.secondary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Illimité',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final isAtLimit = currentCount >= maxCount;

        return GestureDetector(
          onTap: isAtLimit ? () => context.push(AppRoutes.premium) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAtLimit
                  ? AppColors.warning.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentCount/$maxCount',
                  style: TextStyle(
                    color: isAtLimit ? AppColors.warning : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAtLimit) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.workspace_premium,
                    color: AppColors.warning,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialog pour quand l'utilisateur atteint une limite
class LimitReachedDialog extends StatelessWidget {
  final PremiumFeature feature;
  final int maxCount;

  const LimitReachedDialog({
    super.key,
    required this.feature,
    required this.maxCount,
  });

  static Future<void> show(
    BuildContext context, {
    required PremiumFeature feature,
    required int maxCount,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LimitReachedDialog(
        feature: feature,
        maxCount: maxCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.premiumGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Limite atteinte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SubscriptionService.getLimitMessage(feature),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.premium);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Passer à Premium',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    );
  }
}
