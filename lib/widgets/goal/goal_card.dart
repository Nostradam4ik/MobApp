import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/goal.dart';

/// Carte d'objectif
class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onAddContribution;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onAddContribution,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final goalColor = AppColors.fromHex(goal.color);

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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(goal.icon),
                      color: goalColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (goal.deadline != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: goal.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDeadline(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: goal.isOverdue
                                          ? AppColors.error
                                          : null,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (goal.isReached)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Progression
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: goalColor,
                                  ),
                            ),
                            Text(
                              '${goal.progress.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: goalColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progress / 100,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Objectif: ${currencyFormat.format(goal.targetAmount)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Bouton ajouter
              if (!goal.isReached && onAddContribution != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAddContribution,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: goalColor,
                      side: BorderSide(color: goalColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDeadline() {
    if (goal.deadline == null) return '';

    final days = goal.daysRemaining;
    if (days == null) return '';

    if (days < 0) {
      return 'Dépassé de ${-days} jours';
    } else if (days == 0) {
      return 'Aujourd\'hui';
    } else if (days == 1) {
      return 'Demain';
    } else if (days < 30) {
      return 'Dans $days jours';
    } else {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(goal.deadline!);
    }
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'savings': Icons.savings,
      'flight': Icons.flight,
      'phone_android': Icons.phone_android,
      'laptop': Icons.laptop,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'school': Icons.school,
      'celebration': Icons.celebration,
      'medical_services': Icons.medical_services,
      'beach_access': Icons.beach_access,
    };
    return iconMap[iconName] ?? Icons.savings;
  }
}
