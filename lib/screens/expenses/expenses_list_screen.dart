import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense/expense_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/ads/native_ad_widget.dart';
import '../../services/ad_service.dart';

/// Écran de liste des dépenses
class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Toutes les dépenses'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _selectMonth(context, expenseProvider),
              ),
            ],
          ),
          body: Column(
            children: [
              // Sélecteur de mois
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        final newMonth = DateTime(
                          expenseProvider.selectedMonth.year,
                          expenseProvider.selectedMonth.month - 1,
                        );
                        expenseProvider.setSelectedMonth(newMonth);
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR')
                          .format(expenseProvider.selectedMonth),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final now = DateTime.now();
                        final selected = expenseProvider.selectedMonth;
                        if (selected.year < now.year ||
                            (selected.year == now.year &&
                                selected.month < now.month)) {
                          final newMonth = DateTime(
                            selected.year,
                            selected.month + 1,
                          );
                          expenseProvider.setSelectedMonth(newMonth);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Total du mois
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total du mois'),
                    Text(
                      NumberFormat.currency(locale: 'fr_FR', symbol: '€')
                          .format(expenseProvider.monthTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Liste
              Expanded(
                child: expenseProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : expenseProvider.expenses.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long,
                            title: 'Aucune dépense',
                            subtitle: 'Pas de dépenses pour ce mois',
                          )
                        : RefreshIndicator(
                            onRefresh: expenseProvider.loadExpenses,
                            child: _buildExpensesList(
                              context,
                              expenseProvider,
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construit la liste des dépenses avec des native ads intercalées
  Widget _buildExpensesList(
    BuildContext context,
    ExpenseProvider expenseProvider,
  ) {
    final expenses = expenseProvider.expenses;
    final shouldShowAds = AdService.shouldShowAds();
    final totalCount = shouldShowAds
        ? NativeAdHelper.getTotalCount(expenses.length)
        : expenses.length;

    return ListView.builder(
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Vérifier si c'est une publicité
        if (shouldShowAds && NativeAdHelper.isAdIndex(index)) {
          return NativeAdExpenseCard(
            adId: NativeAdHelper.getAdId(index),
          );
        }

        // Sinon afficher la dépense
        final realIndex = shouldShowAds
            ? NativeAdHelper.getRealIndex(index)
            : index;

        if (realIndex >= expenses.length) {
          return const SizedBox.shrink();
        }

        final expense = expenses[realIndex];
        return ExpenseCard(
          expense: expense,
          onTap: () => context.push('/expense/${expense.id}'),
        );
      },
    );
  }

  Future<void> _selectMonth(
      BuildContext context, ExpenseProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      provider.setSelectedMonth(picked);
    }
  }
}
