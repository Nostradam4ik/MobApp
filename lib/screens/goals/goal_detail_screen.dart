import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/goal.dart';
import '../../providers/goal_provider.dart';

/// Écran de détail d'un objectif
class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  List<GoalContribution> _contributions = [];
  bool _loadingContributions = true;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    final provider = context.read<GoalProvider>();
    final contributions = await provider.getContributions(widget.goalId);
    setState(() {
      _contributions = contributions;
      _loadingContributions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Consumer<GoalProvider>(
      builder: (context, goalProvider, _) {
        final goal = goalProvider.getGoalById(widget.goalId);

        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Objectif')),
            body: const Center(child: Text('Objectif non trouvé')),
          );
        }

        final goalColor = AppColors.fromHex(goal.color);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détail'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push(
                  AppRoutes.goalForm,
                  extra: goal.toJson(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, goalProvider),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getIconData(goal.icon),
                          size: 40,
                          color: goalColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (goal.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          goal.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Progression
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: goalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyFormat.format(goal.currentAmount),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: goalColor,
                                ),
                          ),
                          Text(
                            '${goal.progress.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: goalColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: goal.progress / 100,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Restant: ${currencyFormat.format(goal.remaining)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Objectif: ${currencyFormat.format(goal.targetAmount)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Infos
                if (goal.deadline != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date limite',
                    value: DateFormat('dd MMMM yyyy', 'fr_FR')
                        .format(goal.deadline!),
                    isWarning: goal.isOverdue,
                  ),
                if (goal.dailyTargetAmount != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.trending_up,
                    label: 'Épargne conseillée/jour',
                    value: currencyFormat.format(goal.dailyTargetAmount),
                  ),
                const SizedBox(height: 24),

                // Historique
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Historique',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!goal.isReached)
                      TextButton.icon(
                        onPressed: () => _showAddContribution(context, goalProvider),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_loadingContributions)
                  const Center(child: CircularProgressIndicator())
                else if (_contributions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Aucune contribution pour le moment'),
                    ),
                  )
                else
                  ..._contributions.map((c) => _buildContributionTile(context, c)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isWarning ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isWarning ? AppColors.error : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributionTile(BuildContext context, GoalContribution c) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isPositive = c.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy', 'fr_FR').format(c.contributionDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (c.note != null)
                  Text(
                    c.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${currencyFormat.format(c.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContribution(BuildContext context, GoalProvider provider) {
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
                        goalId: widget.goalId,
                        amount: amount,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadContributions();
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

  void _showDeleteDialog(BuildContext context, GoalProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'objectif ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteGoal(widget.goalId);
              if (success && context.mounted) {
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
