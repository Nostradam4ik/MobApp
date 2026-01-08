import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/goal/goal_card.dart';
import '../../widgets/common/empty_state.dart';

/// Écran de liste des objectifs
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.goalForm),
          ),
        ],
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, _) {
          if (goalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (goalProvider.allGoals.isEmpty) {
            return EmptyState(
              icon: Icons.flag,
              title: 'Aucun objectif',
              subtitle: 'Créez un objectif d\'épargne pour commencer',
              buttonText: 'Créer un objectif',
              onButtonPressed: () => context.push(AppRoutes.goalForm),
            );
          }

          return RefreshIndicator(
            onRefresh: goalProvider.loadGoals,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Objectifs actifs
                if (goalProvider.goals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'En cours',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...goalProvider.goals.map((goal) {
                    return GoalCard(
                      goal: goal,
                      onTap: () => context.push('/goal/${goal.id}'),
                      onAddContribution: () => _showAddContribution(
                        context,
                        goalProvider,
                        goal.id,
                      ),
                    );
                  }),
                ],

                // Objectifs complétés
                if (goalProvider.completedGoals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Complétés',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...goalProvider.completedGoals.map((goal) {
                    return GoalCard(
                      goal: goal,
                      onTap: () => context.push('/goal/${goal.id}'),
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

  void _showAddContribution(
    BuildContext context,
    GoalProvider provider,
    String goalId,
  ) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter une contribution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '50,00',
                  suffixText: '€',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(controller.text.replaceAll(',', '.'));
                    if (amount != null && amount > 0) {
                      await provider.addContribution(
                        goalId: goalId,
                        amount: amount,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
