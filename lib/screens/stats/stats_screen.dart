import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/expense_provider.dart';

/// Écran des statistiques
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: Consumer2<StatsProvider, ExpenseProvider>(
        builder: (context, stats, expenses, _) {
          if (expenses.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé
                _buildSummaryCards(context, stats, currencyFormat),
                const SizedBox(height: 24),

                // Graphique par catégorie
                Text(
                  'Répartition par catégorie',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildCategoryChart(context, stats),
                const SizedBox(height: 24),

                // Liste des catégories
                ...stats.categoryStats.map((cat) {
                  return _buildCategoryRow(
                    context,
                    cat,
                    stats.monthTotal,
                    currencyFormat,
                  );
                }),
                const SizedBox(height: 24),

                // Graphique journalier
                Text(
                  'Évolution ce mois',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildDailyChart(context, stats),
                const SizedBox(height: 24),

                // Statistiques détaillées
                Text(
                  'Détails',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  'Nombre de transactions',
                  '${stats.transactionCount}',
                ),
                _buildStatRow(
                  context,
                  'Moyenne par transaction',
                  currencyFormat.format(stats.averageTransaction),
                ),
                _buildStatRow(
                  context,
                  'Moyenne journalière',
                  currencyFormat.format(stats.dailyAverage),
                ),
                if (stats.highestSpendingDay != null)
                  _buildStatRow(
                    context,
                    'Jour le plus dépensier',
                    'Le ${stats.highestSpendingDay}',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    StatsProvider stats,
    NumberFormat format,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Ce mois',
            amount: stats.monthTotal,
            format: format,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Cette semaine',
            amount: stats.weekTotal,
            format: format,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Aujourd\'hui',
            amount: stats.dayTotal,
            format: format,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required NumberFormat format,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              format.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, StatsProvider stats) {
    if (stats.categoryStats.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Aucune donnée'),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: stats.categoryStats.map((cat) {
            return PieChartSectionData(
              value: cat.amount,
              color: AppColors.fromHex(cat.color),
              title: '${cat.getPercentage(stats.monthTotal).toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    CategoryStat cat,
    double total,
    NumberFormat format,
  ) {
    final percentage = cat.getPercentage(total);
    final color = AppColors.fromHex(cat.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.categoryName),
                    Text(
                      format.format(cat.amount),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(BuildContext context, StatsProvider stats) {
    final dailyStats = stats.dailyStats;
    if (dailyStats.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Aucune donnée'),
      );
    }

    final maxAmount = dailyStats
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${dailyStats[groupIndex].day}\n${rod.toY.toStringAsFixed(0)}€',
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
                  if (index % 5 == 0 && index < dailyStats.length) {
                    return Text(
                      '${dailyStats[index].day}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const SizedBox.shrink();
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
          gridData: const FlGridData(show: false),
          barGroups: dailyStats.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.amount,
                  color: AppColors.primary,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
