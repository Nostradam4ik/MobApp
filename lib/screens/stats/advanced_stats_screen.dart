import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../data/models/expense.dart';

/// Écran de graphiques avancés
class AdvancedStatsScreen extends StatefulWidget {
  const AdvancedStatsScreen({super.key});

  @override
  State<AdvancedStatsScreen> createState() => _AdvancedStatsScreenState();
}

class _AdvancedStatsScreenState extends State<AdvancedStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final _monthFormat = DateFormat('MMM', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        title: Text(
          'Graphiques avancés',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Évolution'),
            Tab(text: 'Comparaison'),
            Tab(text: 'Tendances'),
          ],
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, _) {
          final allExpenses = expenseProvider.expenses;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEvolutionTab(allExpenses, isDark),
              _buildComparisonTab(allExpenses, isDark),
              _buildTrendsTab(allExpenses, isDark),
            ],
          );
        },
      ),
    );
  }

  /// Onglet Évolution mensuelle
  Widget _buildEvolutionTab(List<Expense> expenses, bool isDark) {
    final monthlyData = _getMonthlyData(expenses);

    if (monthlyData.isEmpty) {
      return _buildEmptyState('Pas assez de données', isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphique linéaire d'évolution
          _buildSectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Évolution des dépenses',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxAmount(monthlyData) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _monthFormat.format(monthlyData[index].month),
                              style: TextStyle(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k€',
                          style: TextStyle(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.amount);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistiques mensuelles
          _buildSectionHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Détails par mois',
            color: AppColors.secondary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          ...monthlyData.reversed.take(6).map((data) => _buildMonthCard(data, isDark)),
        ],
      ),
    );
  }

  /// Onglet Comparaison mois vs mois
  Widget _buildComparisonTab(List<Expense> expenses, bool isDark) {
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) =>
      e.expenseDate.year == now.year && e.expenseDate.month == now.month
    ).toList();

    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthExpenses = expenses.where((e) =>
      e.expenseDate.year == lastMonth.year && e.expenseDate.month == lastMonth.month
    ).toList();

    final currentTotal = currentMonthExpenses.fold<double>(0, (s, e) => s + e.amount);
    final lastTotal = lastMonthExpenses.fold<double>(0, (s, e) => s + e.amount);
    final difference = currentTotal - lastTotal;
    final percentChange = lastTotal > 0 ? (difference / lastTotal * 100) : 0.0;

    // Par catégorie
    final currentByCategory = _groupByCategory(currentMonthExpenses);
    final lastByCategory = _groupByCategory(lastMonthExpenses);

    // Fusionner les catégories
    final allCategories = {...currentByCategory.keys, ...lastByCategory.keys}.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Comparaison globale
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildComparisonColumn(
                      'Mois dernier',
                      lastTotal,
                      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: isDark ? AppColors.dividerDark : AppColors.divider,
                    ),
                    _buildComparisonColumn(
                      'Ce mois',
                      currentTotal,
                      AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: difference > 0
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        difference > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: difference > 0 ? AppColors.error : AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: difference > 0 ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        difference > 0 ? 'de plus' : 'd\'économies',
                        style: TextStyle(
                          color: difference > 0 ? AppColors.error : AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Comparaison par catégorie
          _buildSectionHeader(
            icon: Icons.compare_arrows_rounded,
            title: 'Par catégorie',
            color: AppColors.accent,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          if (allCategories.isEmpty)
            _buildEmptyState('Pas de données', isDark)
          else
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxCategoryAmount(currentByCategory, lastByCategory) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = allCategories[groupIndex];
                        final label = rodIndex == 0 ? 'Dernier' : 'Ce mois';
                        return BarTooltipItem(
                          '$category\n$label: ${rod.toY.toStringAsFixed(0)}€',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < allCategories.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  allCategories[index].substring(0, allCategories[index].length > 8 ? 8 : allCategories[index].length),
                                  style: TextStyle(
                                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 60,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}€',
                            style: TextStyle(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: allCategories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: lastByCategory[entry.value] ?? 0,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: currentByCategory[entry.value] ?? 0,
                          color: AppColors.primary,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Mois dernier', isDark ? AppColors.textTertiaryDark : AppColors.textTertiary, isDark),
              const SizedBox(width: 24),
              _buildLegendItem('Ce mois', AppColors.primary, isDark),
            ],
          ),
        ],
      ),
    );
  }

  /// Onglet Tendances
  Widget _buildTrendsTab(List<Expense> expenses, bool isDark) {
    // Calculer les moyennes mobiles et tendances
    final monthlyData = _getMonthlyData(expenses);
    if (monthlyData.length < 2) {
      return _buildEmptyState('Pas assez de données pour analyser les tendances', isDark);
    }

    // Moyenne des 3 derniers mois
    final recentMonths = monthlyData.take(3).toList();
    final recentAverage = recentMonths.fold<double>(0, (s, m) => s + m.amount) / recentMonths.length;

    // Moyenne globale
    final overallAverage = monthlyData.fold<double>(0, (s, m) => s + m.amount) / monthlyData.length;

    // Tendance
    final trend = recentAverage - overallAverage;
    final trendPercent = overallAverage > 0 ? (trend / overallAverage * 100) : 0.0;

    // Top catégories en croissance
    final categoryTrends = _getCategoryTrends(expenses);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Résumé tendance
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            ),
            child: Column(
              children: [
                Icon(
                  trend > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 48,
                  color: trend > 0 ? AppColors.error : AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  trend > 0 ? 'Dépenses en hausse' : 'Dépenses en baisse',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${trendPercent.abs().toStringAsFixed(1)}% par rapport à la moyenne',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrendStat(
                      'Moyenne récente',
                      _currencyFormat.format(recentAverage),
                      AppColors.primary,
                      isDark,
                    ),
                    _buildTrendStat(
                      'Moyenne globale',
                      _currencyFormat.format(overallAverage),
                      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Catégories en croissance
          _buildSectionHeader(
            icon: Icons.insights_rounded,
            title: 'Évolution par catégorie',
            color: AppColors.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          ...categoryTrends.take(5).map((trend) => _buildCategoryTrendCard(trend, isDark)),
        ],
      ),
    );
  }

  // Helpers
  List<MonthlyData> _getMonthlyData(List<Expense> expenses) {
    final Map<String, double> monthlyTotals = {};

    for (final expense in expenses) {
      final key = '${expense.expenseDate.year}-${expense.expenseDate.month.toString().padLeft(2, '0')}';
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + expense.amount;
    }

    final sorted = monthlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) {
      final parts = e.key.split('-');
      final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return MonthlyData(month: month, amount: e.value);
    }).toList();
  }

  Map<String, double> _groupByCategory(List<Expense> expenses) {
    final Map<String, double> result = {};
    for (final expense in expenses) {
      final name = expense.category?.name ?? 'Autre';
      result[name] = (result[name] ?? 0) + expense.amount;
    }
    return result;
  }

  double _getMaxAmount(List<MonthlyData> data) {
    if (data.isEmpty) return 1000;
    return data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
  }

  double _getMaxCategoryAmount(Map<String, double> current, Map<String, double> last) {
    double max = 0;
    for (final v in [...current.values, ...last.values]) {
      if (v > max) max = v;
    }
    return max > 0 ? max : 100;
  }

  List<CategoryTrend> _getCategoryTrends(List<Expense> expenses) {
    final now = DateTime.now();

    // 3 derniers mois
    final recent = expenses.where((e) {
      final diff = now.difference(e.expenseDate).inDays;
      return diff <= 90;
    }).toList();

    // 3 mois précédents
    final previous = expenses.where((e) {
      final diff = now.difference(e.expenseDate).inDays;
      return diff > 90 && diff <= 180;
    }).toList();

    final recentByCategory = _groupByCategory(recent);
    final previousByCategory = _groupByCategory(previous);

    final allCategories = {...recentByCategory.keys, ...previousByCategory.keys};

    return allCategories.map((cat) {
      final recentAmount = recentByCategory[cat] ?? 0;
      final previousAmount = previousByCategory[cat] ?? 0;
      final change = recentAmount - previousAmount;
      final percentChange = previousAmount > 0 ? (change / previousAmount * 100) : 0.0;

      return CategoryTrend(
        name: cat,
        recentAmount: recentAmount,
        previousAmount: previousAmount,
        change: change,
        percentChange: percentChange,
      );
    }).toList()..sort((a, b) => b.change.abs().compareTo(a.change.abs()));
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(MonthlyData data, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(data.month),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _currencyFormat.format(data.amount),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTrendCard(CategoryTrend trend, bool isDark) {
    final isUp = trend.change > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.name,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(trend.recentAmount),
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUp
                  ? AppColors.error.withOpacity(0.2)
                  : AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isUp ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trend.percentChange.abs().toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isUp ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyData {
  final DateTime month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}

class CategoryTrend {
  final String name;
  final double recentAmount;
  final double previousAmount;
  final double change;
  final double percentChange;

  CategoryTrend({
    required this.name,
    required this.recentAmount,
    required this.previousAmount,
    required this.change,
    required this.percentChange,
  });
}
