import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/budget/budget_card.dart';
import '../../widgets/common/empty_state.dart';

/// Écran de gestion des budgets
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.budgetForm),
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetProvider.budgets.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet,
              title: 'Aucun budget',
              subtitle: 'Créez un budget pour mieux gérer vos dépenses',
              buttonText: 'Créer un budget',
              onButtonPressed: () => context.push(AppRoutes.budgetForm),
            );
          }

          return RefreshIndicator(
            onRefresh: budgetProvider.loadBudgets,
            child: ListView(
              children: [
                // Budget global
                if (budgetProvider.globalBudget != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Budget global',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  BudgetCard(
                    budget: budgetProvider.globalBudget!,
                    onTap: () => context.push(
                      AppRoutes.budgetForm,
                      extra: budgetProvider.globalBudget!.toJson(),
                    ),
                  ),
                ],

                // Budgets par catégorie
                if (budgetProvider.categoryBudgets.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Par catégorie',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...budgetProvider.categoryBudgets.map((budget) {
                    return BudgetCard(
                      budget: budget,
                      onTap: () => context.push(
                        AppRoutes.budgetForm,
                        extra: budget.toJson(),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
