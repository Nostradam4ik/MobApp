import 'dart:math' as math;
import '../data/models/expense.dart';

/// Service de prédiction IA pour les dépenses
class PredictionService {
  PredictionService._();

  /// Prédit le total des dépenses pour la fin du mois
  static PredictionResult predictMonthEndTotal(List<Expense> expenses) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

    // Filtrer les dépenses du mois actuel
    final monthExpenses = expenses.where((e) =>
        e.expenseDate.year == now.year && e.expenseDate.month == now.month).toList();

    if (monthExpenses.isEmpty) {
      return PredictionResult(
        predictedTotal: 0,
        confidence: 0,
        method: 'Aucune donnée',
        breakdown: {},
      );
    }

    // Calculer le total actuel
    final currentTotal = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Méthode 1: Extrapolation linéaire simple
    final dailyAverage = currentTotal / currentDay;
    final linearPrediction = dailyAverage * daysInMonth;

    // Méthode 2: Moyenne pondérée avec tendance récente
    final recentExpenses = monthExpenses.where((e) =>
        e.expenseDate.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final recentTotal = recentExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final recentDays = math.min(7, currentDay);
    final recentDailyAvg = recentTotal / recentDays;
    final trendPrediction = currentTotal + (recentDailyAvg * (daysInMonth - currentDay));

    // Méthode 3: Comparaison avec le mois précédent
    final lastMonthExpenses = expenses.where((e) {
      final lastMonth = DateTime(now.year, now.month - 1);
      return e.expenseDate.year == lastMonth.year && e.expenseDate.month == lastMonth.month;
    }).toList();

    double historicalPrediction = linearPrediction;
    if (lastMonthExpenses.isNotEmpty) {
      final lastMonthTotal = lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final lastMonthDays = DateTime(now.year, now.month, 0).day;
      final sameDayLastMonth = lastMonthExpenses.where((e) => e.expenseDate.day <= currentDay)
          .fold(0.0, (sum, e) => sum + e.amount);

      if (sameDayLastMonth > 0) {
        final ratio = currentTotal / sameDayLastMonth;
        historicalPrediction = lastMonthTotal * ratio;
      }
    }

    // Pondérer les méthodes
    final weights = currentDay < 10
        ? [0.5, 0.3, 0.2] // Début de mois: plus d'extrapolation
        : currentDay < 20
            ? [0.3, 0.4, 0.3] // Milieu: équilibré
            : [0.2, 0.5, 0.3]; // Fin: plus de tendance récente

    final predictedTotal =
        linearPrediction * weights[0] +
        trendPrediction * weights[1] +
        historicalPrediction * weights[2];

    // Calculer la confiance
    final confidence = _calculateConfidence(
      currentDay: currentDay,
      daysInMonth: daysInMonth,
      expenseCount: monthExpenses.length,
    );

    // Prédiction par catégorie
    final categoryBreakdown = _predictByCategory(monthExpenses, currentDay, daysInMonth);

    return PredictionResult(
      predictedTotal: predictedTotal,
      currentTotal: currentTotal,
      remainingDays: daysInMonth - currentDay,
      dailyAverage: dailyAverage,
      recentDailyAverage: recentDailyAvg,
      confidence: confidence,
      method: 'Moyenne pondérée',
      breakdown: categoryBreakdown,
      trend: recentDailyAvg > dailyAverage ? 'hausse' : 'baisse',
      trendPercentage: ((recentDailyAvg - dailyAverage) / dailyAverage * 100).abs(),
    );
  }

  /// Prédit les dépenses par catégorie
  static Map<String, double> _predictByCategory(
    List<Expense> monthExpenses,
    int currentDay,
    int daysInMonth,
  ) {
    final categoryTotals = <String, double>{};

    for (final expense in monthExpenses) {
      final categoryId = expense.categoryId ?? 'other';
      categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + expense.amount;
    }

    final predictions = <String, double>{};
    for (final entry in categoryTotals.entries) {
      predictions[entry.key] = entry.value * daysInMonth / currentDay;
    }

    return predictions;
  }

  /// Calcule la confiance de la prédiction
  static double _calculateConfidence({
    required int currentDay,
    required int daysInMonth,
    required int expenseCount,
  }) {
    // Plus on avance dans le mois, plus la confiance est élevée
    final dayProgress = currentDay / daysInMonth;

    // Plus on a de données, plus la confiance est élevée
    final dataConfidence = math.min(expenseCount / 20, 1.0);

    return (dayProgress * 0.7 + dataConfidence * 0.3).clamp(0.0, 1.0);
  }

  /// Analyse les tendances de dépenses
  static TrendAnalysis analyzeTrends(List<Expense> expenses) {
    final now = DateTime.now();
    final trends = <String, double>{};
    final monthlyTotals = <int, double>{};

    // Calculer les totaux par mois (6 derniers mois)
    for (var i = 0; i < 6; i++) {
      final targetMonth = DateTime(now.year, now.month - i);
      final monthExpenses = expenses.where((e) =>
          e.expenseDate.year == targetMonth.year && e.expenseDate.month == targetMonth.month);
      monthlyTotals[i] = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    }

    // Calculer la tendance générale
    double generalTrend = 0;
    if (monthlyTotals.length >= 2) {
      final recent = monthlyTotals[0] ?? 0;
      final older = monthlyTotals[2] ?? monthlyTotals[1] ?? 0;
      if (older > 0) {
        generalTrend = (recent - older) / older * 100;
      }
    }

    // Analyser par jour de la semaine
    final dayOfWeekTotals = List<double>.filled(7, 0);
    final dayOfWeekCounts = List<int>.filled(7, 0);

    for (final expense in expenses) {
      final dayIndex = expense.expenseDate.weekday - 1;
      dayOfWeekTotals[dayIndex] += expense.amount;
      dayOfWeekCounts[dayIndex]++;
    }

    final dayOfWeekAverages = <String, double>{};
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    for (var i = 0; i < 7; i++) {
      if (dayOfWeekCounts[i] > 0) {
        dayOfWeekAverages[dayNames[i]] = dayOfWeekTotals[i] / dayOfWeekCounts[i];
      }
    }

    // Trouver le jour le plus dépensier
    String? maxDay;
    double maxAmount = 0;
    for (final entry in dayOfWeekAverages.entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
        maxDay = entry.key;
      }
    }

    return TrendAnalysis(
      generalTrend: generalTrend,
      monthlyTotals: monthlyTotals,
      dayOfWeekAverages: dayOfWeekAverages,
      mostExpensiveDay: maxDay ?? 'N/A',
      mostExpensiveDayAmount: maxAmount,
    );
  }

  /// Génère des recommandations basées sur les données
  static List<String> generateRecommendations(
    PredictionResult prediction,
    TrendAnalysis trends,
    double? monthlyBudget,
  ) {
    final recommendations = <String>[];

    // Recommandation sur le budget
    if (monthlyBudget != null && prediction.predictedTotal > monthlyBudget) {
      final overAmount = prediction.predictedTotal - monthlyBudget;
      final dailySavingsNeeded = overAmount / prediction.remainingDays;
      recommendations.add(
        '⚠️ Vous pourriez dépasser votre budget de ${overAmount.toStringAsFixed(0)}€. '
        'Essayez d\'économiser ${dailySavingsNeeded.toStringAsFixed(0)}€/jour.',
      );
    }

    // Recommandation sur la tendance
    if (trends.generalTrend > 10) {
      recommendations.add(
        '📈 Vos dépenses ont augmenté de ${trends.generalTrend.toStringAsFixed(0)}% '
        'par rapport aux mois précédents.',
      );
    } else if (trends.generalTrend < -10) {
      recommendations.add(
        '📉 Bravo ! Vos dépenses ont diminué de ${trends.generalTrend.abs().toStringAsFixed(0)}% !',
      );
    }

    // Recommandation sur le jour de la semaine
    if (trends.mostExpensiveDay.isNotEmpty) {
      recommendations.add(
        '📅 Vous dépensez le plus le ${trends.mostExpensiveDay} '
        '(~${trends.mostExpensiveDayAmount.toStringAsFixed(0)}€ en moyenne). '
        'Planifiez vos achats pour réduire les achats impulsifs.',
      );
    }

    // Recommandation sur le rythme
    if (prediction.trend == 'hausse' && prediction.trendPercentage > 20) {
      recommendations.add(
        '🔥 Attention, vos dépenses s\'accélèrent ces derniers jours. '
        'Essayez de ralentir le rythme.',
      );
    }

    // Recommandation positive
    if (monthlyBudget != null && prediction.predictedTotal < monthlyBudget * 0.8) {
      final savings = monthlyBudget - prediction.predictedTotal;
      recommendations.add(
        '🎉 Vous êtes sur la bonne voie ! Vous pourriez économiser '
        '~${savings.toStringAsFixed(0)}€ ce mois.',
      );
    }

    return recommendations;
  }

  /// Prédit les prochaines dépenses récurrentes
  static List<UpcomingExpense> predictUpcomingExpenses(List<Expense> expenses) {
    final upcoming = <UpcomingExpense>[];
    final now = DateTime.now();

    // Grouper par note pour trouver les patterns
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      if (expense.note?.isNotEmpty == true) {
        grouped.putIfAbsent(expense.note!, () => []).add(expense);
      }
    }

    for (final entry in grouped.entries) {
      if (entry.value.length >= 2) {
        // Calculer l'intervalle moyen
        final sorted = entry.value..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        final intervals = <int>[];

        for (var i = 1; i < sorted.length; i++) {
          intervals.add(sorted[i].expenseDate.difference(sorted[i - 1].expenseDate).inDays);
        }

        if (intervals.isNotEmpty) {
          final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
          final avgAmount = entry.value.fold(0.0, (sum, e) => sum + e.amount) /
              entry.value.length;

          // Prédire la prochaine occurrence
          final lastDate = sorted.last.expenseDate;
          final nextDate = lastDate.add(Duration(days: avgInterval.round()));

          if (nextDate.isAfter(now)) {
            upcoming.add(UpcomingExpense(
              description: entry.key,
              predictedAmount: avgAmount,
              predictedDate: nextDate,
              confidence: entry.value.length / 10, // Plus de data = plus confiant
              frequency: avgInterval,
            ));
          }
        }
      }
    }

    // Trier par date
    upcoming.sort((a, b) => a.predictedDate.compareTo(b.predictedDate));

    return upcoming.take(10).toList();
  }
}

/// Résultat de prédiction
class PredictionResult {
  final double predictedTotal;
  final double currentTotal;
  final int remainingDays;
  final double dailyAverage;
  final double recentDailyAverage;
  final double confidence;
  final String method;
  final Map<String, double> breakdown;
  final String trend;
  final double trendPercentage;

  const PredictionResult({
    required this.predictedTotal,
    this.currentTotal = 0,
    this.remainingDays = 0,
    this.dailyAverage = 0,
    this.recentDailyAverage = 0,
    required this.confidence,
    required this.method,
    required this.breakdown,
    this.trend = 'stable',
    this.trendPercentage = 0,
  });

  String get confidenceLabel {
    if (confidence >= 0.8) return 'Haute';
    if (confidence >= 0.5) return 'Moyenne';
    return 'Faible';
  }

  String get confidenceEmoji {
    if (confidence >= 0.8) return '🎯';
    if (confidence >= 0.5) return '📊';
    return '🔮';
  }
}

/// Analyse des tendances
class TrendAnalysis {
  final double generalTrend;
  final Map<int, double> monthlyTotals;
  final Map<String, double> dayOfWeekAverages;
  final String mostExpensiveDay;
  final double mostExpensiveDayAmount;

  const TrendAnalysis({
    required this.generalTrend,
    required this.monthlyTotals,
    required this.dayOfWeekAverages,
    required this.mostExpensiveDay,
    required this.mostExpensiveDayAmount,
  });
}

/// Dépense prédite à venir
class UpcomingExpense {
  final String description;
  final double predictedAmount;
  final DateTime predictedDate;
  final double confidence;
  final double frequency;

  const UpcomingExpense({
    required this.description,
    required this.predictedAmount,
    required this.predictedDate,
    required this.confidence,
    required this.frequency,
  });

  int get daysUntil => predictedDate.difference(DateTime.now()).inDays;
}
