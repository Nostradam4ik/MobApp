import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/models.dart';
import 'supabase_service.dart';

/// Service de génération d'insights intelligents
class InsightGeneratorService {
  InsightGeneratorService._();

  static const _uuid = Uuid();

  /// Génère des insights basés sur les dépenses
  static Future<List<Insight>> generateInsights({
    required String userId,
    required List<Expense> currentMonthExpenses,
    required List<Expense> lastMonthExpenses,
    required List<Budget> budgets,
    required UserProfile profile,
  }) async {
    final insights = <Insight>[];

    // 1. Analyse des dépassements de budget
    insights.addAll(_generateBudgetInsights(userId, budgets));

    // 2. Comparaison avec le mois précédent
    insights.addAll(_generateComparisonInsights(
      userId,
      currentMonthExpenses,
      lastMonthExpenses,
    ));

    // 3. Prédiction de fin de mois
    insights.addAll(_generatePredictionInsights(
      userId,
      currentMonthExpenses,
      budgets,
      profile,
    ));

    // 4. Conseils d'économie
    insights.addAll(_generateSavingsTips(
      userId,
      currentMonthExpenses,
    ));

    return insights;
  }

  /// Génère des insights sur les budgets
  static List<Insight> _generateBudgetInsights(
    String userId,
    List<Budget> budgets,
  ) {
    final insights = <Insight>[];

    for (final budget in budgets) {
      if (budget.isOverBudget) {
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.warning,
          title: 'Budget dépassé',
          message:
              'Vous avez dépassé votre budget ${budget.displayName} de ${(budget.spent - budget.monthlyLimit).toStringAsFixed(2)}€',
          data: {
            'budget_id': budget.id,
            'category_id': budget.categoryId,
            'overspent': budget.spent - budget.monthlyLimit,
          },
          priority: 10,
          createdAt: DateTime.now(),
        ));
      } else if (budget.shouldAlert) {
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.warning,
          title: 'Attention au budget',
          message:
              'Vous avez utilisé ${budget.percentUsed.toStringAsFixed(0)}% de votre budget ${budget.displayName}',
          data: {
            'budget_id': budget.id,
            'category_id': budget.categoryId,
            'percent_used': budget.percentUsed,
          },
          priority: 5,
          createdAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Génère des insights de comparaison mensuelle
  static List<Insight> _generateComparisonInsights(
    String userId,
    List<Expense> currentMonth,
    List<Expense> lastMonth,
  ) {
    final insights = <Insight>[];

    // Total par catégorie ce mois
    final currentByCategory = <String, double>{};
    for (final expense in currentMonth) {
      final catId = expense.categoryId ?? 'other';
      currentByCategory[catId] = (currentByCategory[catId] ?? 0) + expense.amount;
    }

    // Total par catégorie mois dernier
    final lastByCategory = <String, double>{};
    for (final expense in lastMonth) {
      final catId = expense.categoryId ?? 'other';
      lastByCategory[catId] = (lastByCategory[catId] ?? 0) + expense.amount;
    }

    // Comparer
    for (final entry in currentByCategory.entries) {
      final lastAmount = lastByCategory[entry.key] ?? 0;
      if (lastAmount == 0) continue;

      final change = ((entry.value - lastAmount) / lastAmount * 100);

      if (change >= 30) {
        final categoryName = currentMonth
                .firstWhere(
                  (e) => e.categoryId == entry.key,
                  orElse: () => currentMonth.first,
                )
                .category
                ?.name ??
            'cette catégorie';

        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.warning,
          title: 'Augmentation des dépenses',
          message:
              'Vous dépensez ${change.toStringAsFixed(0)}% de plus en $categoryName ce mois-ci',
          data: {
            'category_id': entry.key,
            'change_percent': change,
            'current_amount': entry.value,
            'last_amount': lastAmount,
          },
          priority: 3,
          createdAt: DateTime.now(),
        ));
      } else if (change <= -20) {
        final categoryName = currentMonth
                .firstWhere(
                  (e) => e.categoryId == entry.key,
                  orElse: () => currentMonth.first,
                )
                .category
                ?.name ??
            'cette catégorie';

        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.achievement,
          title: 'Bonne gestion',
          message:
              'Vous avez réduit vos dépenses en $categoryName de ${(-change).toStringAsFixed(0)}%',
          data: {
            'category_id': entry.key,
            'change_percent': change,
          },
          priority: 1,
          createdAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Génère des prédictions de fin de mois
  static List<Insight> _generatePredictionInsights(
    String userId,
    List<Expense> currentMonth,
    List<Budget> budgets,
    UserProfile profile,
  ) {
    final insights = <Insight>[];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;
    final daysRemaining = daysInMonth - daysElapsed;

    if (daysElapsed < 5) return insights; // Pas assez de données

    final totalSpent = currentMonth.fold(0.0, (sum, e) => sum + e.amount);
    final dailyAverage = totalSpent / daysElapsed;
    final projectedTotal = totalSpent + (dailyAverage * daysRemaining);

    // Trouver le budget global
    final globalBudget = budgets.where((b) => b.isGlobal).firstOrNull;

    if (globalBudget != null) {
      if (projectedTotal > globalBudget.monthlyLimit * 1.1) {
        final overAmount = projectedTotal - globalBudget.monthlyLimit;
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.prediction,
          title: 'Prédiction de dépassement',
          message:
              'À ce rythme, vous dépasserez votre budget de ${overAmount.toStringAsFixed(0)}€ d\'ici la fin du mois',
          data: {
            'projected_total': projectedTotal,
            'budget_limit': globalBudget.monthlyLimit,
            'daily_average': dailyAverage,
          },
          priority: 8,
          createdAt: DateTime.now(),
        ));

        // Calculer le budget journalier conseillé
        final remaining = globalBudget.monthlyLimit - totalSpent;
        final dailyBudget = remaining / daysRemaining;

        if (dailyBudget > 0) {
          insights.add(Insight(
            id: _uuid.v4(),
            userId: userId,
            insightType: InsightType.tip,
            title: 'Budget journalier conseillé',
            message:
                'Pour respecter votre budget, essayez de ne pas dépenser plus de ${dailyBudget.toStringAsFixed(2)}€/jour',
            data: {
              'daily_budget': dailyBudget,
              'days_remaining': daysRemaining,
            },
            priority: 6,
            createdAt: DateTime.now(),
          ));
        }
      }
    }

    // Pour revenus variables
    if (profile.incomeType == IncomeType.variable && profile.monthlyIncome > 0) {
      final incomeRemaining = profile.monthlyIncome - totalSpent;
      final dailyBudgetVariable = incomeRemaining / daysRemaining;

      if (incomeRemaining < 0) {
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.warning,
          title: 'Zone rouge',
          message:
              'Vos dépenses ont dépassé vos revenus de ${(-incomeRemaining).toStringAsFixed(0)}€',
          data: {
            'income': profile.monthlyIncome,
            'spent': totalSpent,
          },
          priority: 10,
          createdAt: DateTime.now(),
        ));
      } else if (dailyBudgetVariable < dailyAverage) {
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.tip,
          title: 'Ajustement recommandé',
          message:
              'Réduisez vos dépenses à ${dailyBudgetVariable.toStringAsFixed(2)}€/jour pour finir le mois sereinement',
          data: {
            'recommended_daily': dailyBudgetVariable,
            'current_daily': dailyAverage,
          },
          priority: 7,
          createdAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Génère des conseils d'économie
  static List<Insight> _generateSavingsTips(
    String userId,
    List<Expense> currentMonth,
  ) {
    final insights = <Insight>[];

    // Analyser les petites dépenses fréquentes
    final smallExpenses = currentMonth.where((e) => e.amount <= 10).toList();
    final smallTotal = smallExpenses.fold(0.0, (sum, e) => sum + e.amount);

    if (smallExpenses.length > 10 && smallTotal > 50) {
      insights.add(Insight(
        id: _uuid.v4(),
        userId: userId,
        insightType: InsightType.tip,
        title: 'Petites dépenses',
        message:
            'Vos ${smallExpenses.length} petits achats (<10€) totalisent ${smallTotal.toStringAsFixed(0)}€ ce mois',
        data: {
          'count': smallExpenses.length,
          'total': smallTotal,
        },
        priority: 2,
        createdAt: DateTime.now(),
      ));
    }

    // Identifier les dépenses récurrentes potentielles
    final expensesByNote = <String, List<Expense>>{};
    for (final expense in currentMonth) {
      if (expense.note != null && expense.note!.isNotEmpty) {
        expensesByNote[expense.note!.toLowerCase()] ??= [];
        expensesByNote[expense.note!.toLowerCase()]!.add(expense);
      }
    }

    for (final entry in expensesByNote.entries) {
      if (entry.value.length >= 3) {
        final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
        insights.add(Insight(
          id: _uuid.v4(),
          userId: userId,
          insightType: InsightType.tip,
          title: 'Dépense récurrente détectée',
          message:
              '"${entry.key}" apparaît ${entry.value.length} fois pour ${total.toStringAsFixed(0)}€ total',
          data: {
            'note': entry.key,
            'count': entry.value.length,
            'total': total,
          },
          priority: 1,
          createdAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Sauvegarde les insights générés
  static Future<void> saveInsights(List<Insight> insights) async {
    for (final insight in insights) {
      try {
        await SupabaseService.createInsight(insight);
      } catch (e) {
        // Ignorer les erreurs de doublon
      }
    }
  }
}
