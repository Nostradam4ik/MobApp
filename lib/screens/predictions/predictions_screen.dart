import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/prediction_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  PredictionResult? _prediction;
  TrendAnalysis? _trends;
  List<UpcomingExpense> _upcomingExpenses = [];
  List<String> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  void _loadPredictions() {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final expenses = expenseProvider.expenses;

    final prediction = PredictionService.predictMonthEndTotal(expenses);
    final trends = PredictionService.analyzeTrends(expenses);
    final upcoming = PredictionService.predictUpcomingExpenses(expenses);

    // Obtenir le budget mensuel global
    final globalBudget = budgetProvider.budgets
        .where((b) => b.categoryId == null)
        .fold(0.0, (sum, b) => sum + b.monthlyLimit);

    final recommendations = PredictionService.generateRecommendations(
      prediction,
      trends,
      globalBudget > 0 ? globalBudget : null,
    );

    setState(() {
      _prediction = prediction;
      _trends = trends;
      _upcomingExpenses = upcoming;
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prédictions IA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadPredictions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadPredictions(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prédiction principale
                    _buildMainPredictionCard(theme),
                    const SizedBox(height: 24),

                    // Tendance
                    _buildTrendCard(theme),
                    const SizedBox(height: 24),

                    // Graphique par jour de la semaine
                    _buildDayOfWeekChart(theme),
                    const SizedBox(height: 24),

                    // Recommandations
                    if (_recommendations.isNotEmpty) ...[
                      _buildRecommendationsCard(theme),
                      const SizedBox(height: 24),
                    ],

                    // Dépenses prévues
                    if (_upcomingExpenses.isNotEmpty) ...[
                      _buildUpcomingExpensesCard(theme),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainPredictionCard(ThemeData theme) {
    final prediction = _prediction!;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  prediction.confidenceEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prédiction fin de mois',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confiance: ${prediction.confidenceLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Montant prédit
            Text(
              '${prediction.predictedTotal.toStringAsFixed(0)}€',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'dépenses estimées',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Statistiques
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  theme,
                  label: 'Actuel',
                  value: '${prediction.currentTotal.toStringAsFixed(0)}€',
                  icon: Icons.account_balance_wallet,
                ),
                _buildStatColumn(
                  theme,
                  label: 'Moy./jour',
                  value: '${prediction.dailyAverage.toStringAsFixed(0)}€',
                  icon: Icons.today,
                ),
                _buildStatColumn(
                  theme,
                  label: 'Jours restants',
                  value: '${prediction.remainingDays}',
                  icon: Icons.calendar_month,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de progression du mois
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jour ${now.day}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Jour $daysInMonth',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: now.day / daysInMonth,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTrendCard(ThemeData theme) {
    final trends = _trends!;
    final isUp = trends.generalTrend > 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isUp ? Colors.red : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? Colors.red : Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tendance générale',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isUp
                        ? 'En hausse de ${trends.generalTrend.abs().toStringAsFixed(0)}%'
                        : 'En baisse de ${trends.generalTrend.abs().toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUp ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    'par rapport aux mois précédents',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart(ThemeData theme) {
    final trends = _trends!;
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final maxValue = trends.dayOfWeekAverages.values.isEmpty
        ? 100.0
        : trends.dayOfWeekAverages.values.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_view_week, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Dépenses par jour',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jour le plus dépensier: ${trends.mostExpensiveDay}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)}€',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const Text('');
                          }
                          return Text(
                            days[index],
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final value = trends.dayOfWeekAverages[days[index]] ?? 0;
                    final isMax = days[index] == trends.mostExpensiveDay;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: isMax ? Colors.red : AppColors.primary,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(ThemeData theme) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Recommandations IA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    rec,
                    style: theme.textTheme.bodyMedium,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExpensesCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Dépenses prévues',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Basé sur vos habitudes',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ..._upcomingExpenses.take(5).map((expense) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      '${expense.daysUntil}j',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Prévu le ${_formatDate(expense.predictedDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '~${expense.predictedAmount.toStringAsFixed(0)}€',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
