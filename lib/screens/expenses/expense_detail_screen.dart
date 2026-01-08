import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';

/// Écran de détail d'une dépense
class ExpenseDetailScreen extends StatelessWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        final expense = expenseProvider.getExpenseById(expenseId);

        if (expense == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dépense')),
            body: const Center(child: Text('Dépense non trouvée')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détail'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteDialog(context, expenseProvider),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Montant
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: expense.category?.colorValue.withOpacity(0.15) ??
                              AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          expense.category?.iconData ?? Icons.category,
                          size: 40,
                          color: expense.category?.colorValue ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currencyFormat.format(expense.amount),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.category?.name ?? 'Sans catégorie',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Détails
                _buildDetailRow(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateFormat.format(expense.expenseDate),
                ),
                if (expense.note != null && expense.note!.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.note,
                    label: 'Note',
                    value: expense.note!,
                  ),
                _buildDetailRow(
                  context,
                  icon: Icons.access_time,
                  label: 'Ajouté le',
                  value: DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                      .format(expense.createdAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteExpense(expenseId);
              if (success && context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dépense supprimée'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
