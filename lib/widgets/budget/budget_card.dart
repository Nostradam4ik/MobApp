import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/budget.dart';

/// Carte de budget
class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final progressColor = _getProgressColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: budget.category?.colorValue.withOpacity(0.15) ??
                          AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      budget.category?.iconData ?? Icons.account_balance_wallet,
                      color: budget.category?.colorValue ?? AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${currencyFormat.format(budget.spent)} / ${currencyFormat.format(budget.monthlyLimit)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Pourcentage
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${budget.percentUsed.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (budget.percentUsed / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              // Reste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.remaining >= 0
                        ? 'Reste: ${currencyFormat.format(budget.remaining)}'
                        : 'Dépassé de ${currencyFormat.format(-budget.remaining)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (budget.status == BudgetStatus.warning)
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Attention',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor() {
    switch (budget.status) {
      case BudgetStatus.ok:
        return AppColors.success;
      case BudgetStatus.warning:
        return AppColors.warning;
      case BudgetStatus.exceeded:
        return AppColors.error;
    }
  }
}
