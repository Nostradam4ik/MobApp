import '../data/models/expense.dart';
import '../data/models/income.dart';
import '../data/models/category.dart';

/// Service pour les graphiques et analyses avancées
class AdvancedChartsService {
  // ==================== TENDANCES ANNUELLES ====================

  /// Calcule les dépenses mensuelles sur une année
  YearlyTrend calculateYearlyExpenseTrend({
    required List<Expense> expenses,
    required int year,
  }) {
    final monthlyData = List<double>.filled(12, 0);
    final monthlyCount = List<int>.filled(12, 0);

    for (final expense in expenses) {
      if (expense.expenseDate.year == year) {
        final month = expense.expenseDate.month - 1;
        monthlyData[month] += expense.amount;
        monthlyCount[month]++;
      }
    }

    // Calculer la tendance (régression linéaire simple)
    final trend = _calculateLinearTrend(monthlyData);

    // Calculer les variations mensuelles
    final variations = <double>[];
    for (int i = 1; i < 12; i++) {
      if (monthlyData[i - 1] > 0) {
        variations.add((monthlyData[i] - monthlyData[i - 1]) / monthlyData[i - 1] * 100);
      } else {
        variations.add(0);
      }
    }

    return YearlyTrend(
      year: year,
      monthlyAmounts: monthlyData,
      monthlyTransactionCounts: monthlyCount,
      totalAmount: monthlyData.reduce((a, b) => a + b),
      averageMonthly: monthlyData.reduce((a, b) => a + b) / 12,
      trendSlope: trend.slope,
      trendDirection: trend.slope > 0 ? TrendDirection.up : TrendDirection.down,
      monthlyVariations: variations,
    );
  }

  /// Calcule les revenus mensuels sur une année
  YearlyTrend calculateYearlyIncomeTrend({
    required List<Income> incomes,
    required int year,
  }) {
    final monthlyData = List<double>.filled(12, 0);
    final monthlyCount = List<int>.filled(12, 0);

    for (final income in incomes) {
      if (income.date.year == year) {
        final month = income.date.month - 1;
        monthlyData[month] += income.amount;
        monthlyCount[month]++;
      }
    }

    final trend = _calculateLinearTrend(monthlyData);

    return YearlyTrend(
      year: year,
      monthlyAmounts: monthlyData,
      monthlyTransactionCounts: monthlyCount,
      totalAmount: monthlyData.reduce((a, b) => a + b),
      averageMonthly: monthlyData.reduce((a, b) => a + b) / 12,
      trendSlope: trend.slope,
      trendDirection: trend.slope > 0 ? TrendDirection.up : TrendDirection.down,
      monthlyVariations: [],
    );
  }

  // ==================== COMPARAISONS PÉRIODES ====================

  /// Compare deux périodes (ex: ce mois vs mois dernier)
  PeriodComparison comparePeriods({
    required List<Expense> currentPeriodExpenses,
    required List<Expense> previousPeriodExpenses,
    required String currentLabel,
    required String previousLabel,
  }) {
    final currentTotal = currentPeriodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final previousTotal = previousPeriodExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final difference = currentTotal - previousTotal;
    final percentChange = previousTotal > 0
        ? (difference / previousTotal * 100)
        : (currentTotal > 0 ? 100 : 0);

    // Comparaison par catégorie
    final currentByCategory = _groupByCategory(currentPeriodExpenses);
    final previousByCategory = _groupByCategory(previousPeriodExpenses);

    final categoryComparisons = <CategoryComparison>[];
    final allCategories = {...currentByCategory.keys, ...previousByCategory.keys};

    for (final category in allCategories) {
      final current = currentByCategory[category] ?? 0.0;
      final previous = previousByCategory[category] ?? 0.0;
      final diff = current - previous;
      final pctChange = previous > 0 ? (diff / previous * 100) : (current > 0 ? 100.0 : 0.0);

      categoryComparisons.add(CategoryComparison(
        categoryName: category,
        currentAmount: current,
        previousAmount: previous,
        difference: diff,
        percentChange: pctChange.toDouble(),
      ));
    }

    // Trier par différence absolue décroissante
    categoryComparisons.sort((a, b) => b.difference.abs().compareTo(a.difference.abs()));

    return PeriodComparison(
      currentPeriodLabel: currentLabel,
      previousPeriodLabel: previousLabel,
      currentTotal: currentTotal,
      previousTotal: previousTotal,
      difference: difference,
      percentChange: percentChange.toDouble(),
      isIncrease: difference > 0,
      currentTransactionCount: currentPeriodExpenses.length,
      previousTransactionCount: previousPeriodExpenses.length,
      categoryComparisons: categoryComparisons,
    );
  }

  /// Compare année sur année
  YearOverYearComparison compareYearOverYear({
    required List<Expense> expenses,
    required int currentYear,
  }) {
    final previousYear = currentYear - 1;

    final currentYearExpenses = expenses.where((e) => e.expenseDate.year == currentYear).toList();
    final previousYearExpenses = expenses.where((e) => e.expenseDate.year == previousYear).toList();

    final currentTotal = currentYearExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final previousTotal = previousYearExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Comparaison par mois
    final monthlyComparisons = <MonthComparison>[];
    for (int month = 1; month <= 12; month++) {
      final currentMonthExpenses = currentYearExpenses
          .where((e) => e.expenseDate.month == month)
          .fold(0.0, (sum, e) => sum + e.amount);
      final previousMonthExpenses = previousYearExpenses
          .where((e) => e.expenseDate.month == month)
          .fold(0.0, (sum, e) => sum + e.amount);

      final diff = currentMonthExpenses - previousMonthExpenses;
      final pctChange = previousMonthExpenses > 0
          ? (diff / previousMonthExpenses * 100)
          : (currentMonthExpenses > 0 ? 100 : 0);

      monthlyComparisons.add(MonthComparison(
        month: month,
        currentYearAmount: currentMonthExpenses,
        previousYearAmount: previousMonthExpenses,
        difference: diff,
        percentChange: pctChange.toDouble(),
      ));
    }

    return YearOverYearComparison(
      currentYear: currentYear,
      previousYear: previousYear,
      currentYearTotal: currentTotal,
      previousYearTotal: previousTotal,
      difference: currentTotal - previousTotal,
      percentChange: previousTotal > 0
          ? ((currentTotal - previousTotal) / previousTotal * 100).toDouble()
          : 0.0,
      monthlyComparisons: monthlyComparisons,
    );
  }

  // ==================== ANALYSES PAR CATÉGORIE ====================

  /// Analyse détaillée par catégorie
  List<CategoryAnalysis> analyzeCategoriesDetailed({
    required List<Expense> expenses,
    required List<Category> categories,
  }) {
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final analyses = <CategoryAnalysis>[];

    for (final category in categories) {
      final categoryExpenses = expenses.where((e) => e.categoryId == category.id).toList();

      if (categoryExpenses.isEmpty) continue;

      final amount = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final count = categoryExpenses.length;

      // Calculer les statistiques
      final amounts = categoryExpenses.map((e) => e.amount).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      final average = amount / count;

      // Jour le plus dépensier
      final byDayOfWeek = <int, double>{};
      for (final expense in categoryExpenses) {
        final day = expense.expenseDate.weekday;
        byDayOfWeek[day] = (byDayOfWeek[day] ?? 0) + expense.amount;
      }
      final topDay = byDayOfWeek.entries.reduce((a, b) => a.value > b.value ? a : b);

      analyses.add(CategoryAnalysis(
        category: category,
        totalAmount: amount,
        transactionCount: count,
        percentOfTotal: totalAmount > 0 ? (amount / totalAmount * 100) : 0,
        averageTransaction: average,
        medianTransaction: median,
        minTransaction: amounts.first,
        maxTransaction: amounts.last,
        topDayOfWeek: topDay.key,
        topDayAmount: topDay.value,
      ));
    }

    // Trier par montant décroissant
    analyses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return analyses;
  }

  // ==================== PATTERNS DE DÉPENSES ====================

  /// Analyse les patterns hebdomadaires
  WeeklyPattern analyzeWeeklyPattern(List<Expense> expenses) {
    final byDayOfWeek = List<double>.filled(7, 0);
    final countByDay = List<int>.filled(7, 0);

    for (final expense in expenses) {
      final day = expense.expenseDate.weekday - 1; // 0 = Lundi
      byDayOfWeek[day] += expense.amount;
      countByDay[day]++;
    }

    // Moyennes
    final averageByDay = <double>[];
    for (int i = 0; i < 7; i++) {
      averageByDay.add(countByDay[i] > 0 ? byDayOfWeek[i] / countByDay[i] : 0);
    }

    // Trouver le jour le plus/moins dépensier
    int peakDay = 0;
    int lowDay = 0;
    for (int i = 1; i < 7; i++) {
      if (byDayOfWeek[i] > byDayOfWeek[peakDay]) peakDay = i;
      if (byDayOfWeek[i] < byDayOfWeek[lowDay]) lowDay = i;
    }

    // Calcul weekend vs semaine
    final weekdayTotal = byDayOfWeek.sublist(0, 5).reduce((a, b) => a + b);
    final weekendTotal = byDayOfWeek.sublist(5).reduce((a, b) => a + b);

    return WeeklyPattern(
      totalByDay: byDayOfWeek,
      averageByDay: averageByDay,
      transactionCountByDay: countByDay,
      peakDay: peakDay + 1, // Retour à 1-7
      peakDayAmount: byDayOfWeek[peakDay],
      lowDay: lowDay + 1,
      lowDayAmount: byDayOfWeek[lowDay],
      weekdayTotal: weekdayTotal,
      weekendTotal: weekendTotal,
      weekdayAverage: weekdayTotal / 5,
      weekendAverage: weekendTotal / 2,
    );
  }

  /// Analyse les patterns horaires (si l'heure est disponible)
  HourlyPattern analyzeHourlyPattern(List<Expense> expenses) {
    final byHour = List<double>.filled(24, 0);
    final countByHour = List<int>.filled(24, 0);

    for (final expense in expenses) {
      final hour = expense.expenseDate.hour;
      byHour[hour] += expense.amount;
      countByHour[hour]++;
    }

    int peakHour = 0;
    for (int i = 1; i < 24; i++) {
      if (byHour[i] > byHour[peakHour]) peakHour = i;
    }

    return HourlyPattern(
      totalByHour: byHour,
      transactionCountByHour: countByHour,
      peakHour: peakHour,
      peakHourAmount: byHour[peakHour],
    );
  }

  // ==================== PRÉVISIONS ====================

  /// Prévoit les dépenses pour les mois suivants
  List<MonthlyForecast> forecastExpenses({
    required List<Expense> historicalExpenses,
    required int monthsToForecast,
  }) {
    // Grouper par mois
    final monthlyTotals = <DateTime, double>{};
    for (final expense in historicalExpenses) {
      final monthKey = DateTime(expense.expenseDate.year, expense.expenseDate.month);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + expense.amount;
    }

    if (monthlyTotals.isEmpty) return [];

    // Convertir en liste ordonnée
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final values = sortedMonths.map((m) => monthlyTotals[m]!).toList();

    // Utiliser moyenne mobile exponentielle pour la prévision
    final forecasts = <MonthlyForecast>[];
    final alpha = 0.3; // Facteur de lissage
    double ema = values.first;

    for (final value in values) {
      ema = alpha * value + (1 - alpha) * ema;
    }

    // Calculer l'écart-type pour l'intervalle de confiance
    double variance = 0;
    for (final value in values) {
      variance += (value - ema) * (value - ema);
    }
    final stdDev = values.length > 1
        ? (variance / (values.length - 1)).abs()
        : 0.0;
    final stdDevSqrt = stdDev > 0 ? _sqrt(stdDev) : 0.0;

    final lastMonth = sortedMonths.last;
    for (int i = 1; i <= monthsToForecast; i++) {
      final forecastMonth = DateTime(lastMonth.year, lastMonth.month + i);
      final confidenceInterval = 1.96 * stdDevSqrt; // 95% de confiance

      forecasts.add(MonthlyForecast(
        month: forecastMonth,
        predictedAmount: ema,
        lowerBound: (ema - confidenceInterval).clamp(0, double.infinity),
        upperBound: ema + confidenceInterval,
        confidence: 0.95,
      ));
    }

    return forecasts;
  }

  // ==================== UTILITAIRES PRIVÉS ====================

  Map<String, double> _groupByCategory(List<Expense> expenses) {
    final result = <String, double>{};
    for (final expense in expenses) {
      final category = expense.category?.name ?? 'Sans catégorie';
      result[category] = (result[category] ?? 0) + expense.amount;
    }
    return result;
  }

  _LinearTrend _calculateLinearTrend(List<double> values) {
    final n = values.length;
    if (n < 2) return _LinearTrend(slope: 0, intercept: values.isNotEmpty ? values.first : 0);

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    return _LinearTrend(slope: slope, intercept: intercept);
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double x = value;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }
    return x;
  }
}

// ==================== CLASSES DE DONNÉES ====================

class _LinearTrend {
  final double slope;
  final double intercept;
  _LinearTrend({required this.slope, required this.intercept});
}

enum TrendDirection { up, down, stable }

class YearlyTrend {
  final int year;
  final List<double> monthlyAmounts;
  final List<int> monthlyTransactionCounts;
  final double totalAmount;
  final double averageMonthly;
  final double trendSlope;
  final TrendDirection trendDirection;
  final List<double> monthlyVariations;

  const YearlyTrend({
    required this.year,
    required this.monthlyAmounts,
    required this.monthlyTransactionCounts,
    required this.totalAmount,
    required this.averageMonthly,
    required this.trendSlope,
    required this.trendDirection,
    required this.monthlyVariations,
  });
}

class PeriodComparison {
  final String currentPeriodLabel;
  final String previousPeriodLabel;
  final double currentTotal;
  final double previousTotal;
  final double difference;
  final double percentChange;
  final bool isIncrease;
  final int currentTransactionCount;
  final int previousTransactionCount;
  final List<CategoryComparison> categoryComparisons;

  const PeriodComparison({
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
    required this.currentTotal,
    required this.previousTotal,
    required this.difference,
    required this.percentChange,
    required this.isIncrease,
    required this.currentTransactionCount,
    required this.previousTransactionCount,
    required this.categoryComparisons,
  });
}

class CategoryComparison {
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double difference;
  final double percentChange;

  const CategoryComparison({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
    required this.percentChange,
  });
}

class YearOverYearComparison {
  final int currentYear;
  final int previousYear;
  final double currentYearTotal;
  final double previousYearTotal;
  final double difference;
  final double percentChange;
  final List<MonthComparison> monthlyComparisons;

  const YearOverYearComparison({
    required this.currentYear,
    required this.previousYear,
    required this.currentYearTotal,
    required this.previousYearTotal,
    required this.difference,
    required this.percentChange,
    required this.monthlyComparisons,
  });
}

class MonthComparison {
  final int month;
  final double currentYearAmount;
  final double previousYearAmount;
  final double difference;
  final double percentChange;

  const MonthComparison({
    required this.month,
    required this.currentYearAmount,
    required this.previousYearAmount,
    required this.difference,
    required this.percentChange,
  });
}

class CategoryAnalysis {
  final Category category;
  final double totalAmount;
  final int transactionCount;
  final double percentOfTotal;
  final double averageTransaction;
  final double medianTransaction;
  final double minTransaction;
  final double maxTransaction;
  final int topDayOfWeek;
  final double topDayAmount;

  const CategoryAnalysis({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentOfTotal,
    required this.averageTransaction,
    required this.medianTransaction,
    required this.minTransaction,
    required this.maxTransaction,
    required this.topDayOfWeek,
    required this.topDayAmount,
  });
}

class WeeklyPattern {
  final List<double> totalByDay;
  final List<double> averageByDay;
  final List<int> transactionCountByDay;
  final int peakDay;
  final double peakDayAmount;
  final int lowDay;
  final double lowDayAmount;
  final double weekdayTotal;
  final double weekendTotal;
  final double weekdayAverage;
  final double weekendAverage;

  const WeeklyPattern({
    required this.totalByDay,
    required this.averageByDay,
    required this.transactionCountByDay,
    required this.peakDay,
    required this.peakDayAmount,
    required this.lowDay,
    required this.lowDayAmount,
    required this.weekdayTotal,
    required this.weekendTotal,
    required this.weekdayAverage,
    required this.weekendAverage,
  });

  String get peakDayName => _dayName(peakDay);
  String get lowDayName => _dayName(lowDay);

  String _dayName(int day) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[day - 1];
  }
}

class HourlyPattern {
  final List<double> totalByHour;
  final List<int> transactionCountByHour;
  final int peakHour;
  final double peakHourAmount;

  const HourlyPattern({
    required this.totalByHour,
    required this.transactionCountByHour,
    required this.peakHour,
    required this.peakHourAmount,
  });
}

class MonthlyForecast {
  final DateTime month;
  final double predictedAmount;
  final double lowerBound;
  final double upperBound;
  final double confidence;

  const MonthlyForecast({
    required this.month,
    required this.predictedAmount,
    required this.lowerBound,
    required this.upperBound,
    required this.confidence,
  });
}
