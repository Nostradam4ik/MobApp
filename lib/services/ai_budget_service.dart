// ============================================================================
// SmartSpend - Service IA pour suggestions de budget intelligentes
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:math';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../data/models/budget.dart';

/// Types de suggestions IA
enum SuggestionType {
  budgetOptimization,
  savingOpportunity,
  spendingAlert,
  categoryInsight,
  trendAnalysis,
  goalRecommendation,
  recurringExpenseAlert,
  unusualSpending,
  seasonalTrend,
  smartSaving,
}

/// Priorité de la suggestion
enum SuggestionPriority {
  low,
  medium,
  high,
  critical,
}

/// Modèle de suggestion IA
class AISuggestion {
  final String id;
  final SuggestionType type;
  final SuggestionPriority priority;
  final String title;
  final String description;
  final String? actionText;
  final double? potentialSaving;
  final String? categoryId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  AISuggestion({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    this.actionText,
    this.potentialSaving,
    this.categoryId,
    this.metadata,
    DateTime? createdAt,
    this.isRead = false,
    this.isDismissed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Icône pour le type de suggestion
  String get icon {
    switch (type) {
      case SuggestionType.budgetOptimization:
        return '📊';
      case SuggestionType.savingOpportunity:
        return '💰';
      case SuggestionType.spendingAlert:
        return '⚠️';
      case SuggestionType.categoryInsight:
        return '📈';
      case SuggestionType.trendAnalysis:
        return '📉';
      case SuggestionType.goalRecommendation:
        return '🎯';
      case SuggestionType.recurringExpenseAlert:
        return '🔄';
      case SuggestionType.unusualSpending:
        return '❗';
      case SuggestionType.seasonalTrend:
        return '📅';
      case SuggestionType.smartSaving:
        return '🧠';
    }
  }

  /// Couleur pour la priorité
  int get priorityColor {
    switch (priority) {
      case SuggestionPriority.low:
        return 0xFF4CAF50; // Vert
      case SuggestionPriority.medium:
        return 0xFF2196F3; // Bleu
      case SuggestionPriority.high:
        return 0xFFFF9800; // Orange
      case SuggestionPriority.critical:
        return 0xFFF44336; // Rouge
    }
  }
}

/// Service d'IA pour les suggestions de budget intelligentes
class AIBudgetService {
  /// Analyser les dépenses et générer des suggestions
  static List<AISuggestion> analyzeAndSuggest({
    required List<Expense> expenses,
    required List<Category> categories,
    required List<Budget> budgets,
    double? monthlyIncome,
  }) {
    final suggestions = <AISuggestion>[];

    // Analyse des tendances de dépenses
    suggestions.addAll(_analyzeSpendingTrends(expenses, categories));

    // Détection des dépenses inhabituelles
    suggestions.addAll(_detectUnusualSpending(expenses, categories));

    // Optimisation des budgets
    suggestions.addAll(_optimizeBudgets(expenses, budgets, categories));

    // Opportunités d'économies
    suggestions.addAll(_findSavingOpportunities(expenses, categories, monthlyIncome));

    // Détection des dépenses récurrentes
    suggestions.addAll(_detectRecurringExpenses(expenses));

    // Analyse saisonnière
    suggestions.addAll(_analyzeSeasonalTrends(expenses));

    // Recommandations d'objectifs
    suggestions.addAll(_recommendGoals(expenses, monthlyIncome));

    // Trier par priorité
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return suggestions;
  }

  /// Analyser les tendances de dépenses
  static List<AISuggestion> _analyzeSpendingTrends(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final suggestions = <AISuggestion>[];
    if (expenses.isEmpty) return suggestions;

    final now = DateTime.now();
    final thisMonth = expenses.where((e) =>
        e.expenseDate.month == now.month && e.expenseDate.year == now.year).toList();
    final lastMonth = expenses.where((e) =>
        e.expenseDate.month == now.month - 1 ||
        (now.month == 1 && e.expenseDate.month == 12 && e.expenseDate.year == now.year - 1)).toList();

    if (thisMonth.isNotEmpty && lastMonth.isNotEmpty) {
      final thisMonthTotal = thisMonth.fold<double>(0, (sum, e) => sum + e.amount);
      final lastMonthTotal = lastMonth.fold<double>(0, (sum, e) => sum + e.amount);

      final percentChange = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100);

      if (percentChange > 20) {
        suggestions.add(AISuggestion(
          id: 'trend_increase_${now.millisecondsSinceEpoch}',
          type: SuggestionType.trendAnalysis,
          priority: percentChange > 50 ? SuggestionPriority.high : SuggestionPriority.medium,
          title: 'Augmentation des dépenses',
          description: 'Vos dépenses ont augmenté de ${percentChange.toStringAsFixed(0)}% par rapport au mois dernier. '
              'Analysez vos habitudes pour identifier les causes.',
          actionText: 'Voir les détails',
          metadata: {
            'thisMonth': thisMonthTotal,
            'lastMonth': lastMonthTotal,
            'percentChange': percentChange,
          },
        ));
      } else if (percentChange < -15) {
        suggestions.add(AISuggestion(
          id: 'trend_decrease_${now.millisecondsSinceEpoch}',
          type: SuggestionType.trendAnalysis,
          priority: SuggestionPriority.low,
          title: 'Bravo ! Économies réalisées 🎉',
          description: 'Vos dépenses ont diminué de ${(-percentChange).toStringAsFixed(0)}% par rapport au mois dernier. '
              'Continuez ainsi !',
          potentialSaving: lastMonthTotal - thisMonthTotal,
        ));
      }
    }

    return suggestions;
  }

  /// Détecter les dépenses inhabituelles
  static List<AISuggestion> _detectUnusualSpending(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final suggestions = <AISuggestion>[];
    if (expenses.length < 10) return suggestions;

    // Calculer la moyenne et l'écart-type
    final amounts = expenses.map((e) => e.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = sqrt(variance);

    // Détecter les dépenses anormalement élevées (> 2 écarts-types)
    final threshold = mean + 2 * stdDev;
    final unusualExpenses = expenses.where((e) => e.amount > threshold).toList();

    for (final expense in unusualExpenses.take(3)) {
      final category = categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => Category(
          id: '',
          userId: '',
          name: 'Autre',
          icon: 'help',
          color: '#9E9E9E',
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      suggestions.add(AISuggestion(
        id: 'unusual_${expense.id}',
        type: SuggestionType.unusualSpending,
        priority: expense.amount > mean + 3 * stdDev
            ? SuggestionPriority.high
            : SuggestionPriority.medium,
        title: 'Dépense inhabituelle détectée',
        description: 'Une dépense de ${expense.amount.toStringAsFixed(2)}€ en ${category.name} '
            'est ${(expense.amount / mean).toStringAsFixed(1)}x plus élevée que votre moyenne.',
        categoryId: expense.categoryId,
        metadata: {
          'expenseId': expense.id,
          'amount': expense.amount,
          'mean': mean,
          'multiplier': expense.amount / mean,
        },
      ));
    }

    return suggestions;
  }

  /// Optimiser les budgets
  static List<AISuggestion> _optimizeBudgets(
    List<Expense> expenses,
    List<Budget> budgets,
    List<Category> categories,
  ) {
    final suggestions = <AISuggestion>[];

    for (final budget in budgets) {
      if (budget.percentUsed >= 90 && budget.percentUsed < 100) {
        suggestions.add(AISuggestion(
          id: 'budget_warning_${budget.id}',
          type: SuggestionType.budgetOptimization,
          priority: SuggestionPriority.high,
          title: 'Budget presque épuisé',
          description: 'Votre budget ${budget.displayName} est utilisé à ${budget.percentUsed.toStringAsFixed(0)}%. '
              'Il reste ${budget.remaining.toStringAsFixed(2)}€.',
          actionText: 'Ajuster le budget',
          categoryId: budget.categoryId,
          metadata: {
            'budgetId': budget.id,
            'percentUsed': budget.percentUsed,
            'remaining': budget.remaining,
          },
        ));
      } else if (budget.isOverBudget) {
        suggestions.add(AISuggestion(
          id: 'budget_exceeded_${budget.id}',
          type: SuggestionType.spendingAlert,
          priority: SuggestionPriority.critical,
          title: 'Budget dépassé !',
          description: 'Votre budget ${budget.displayName} est dépassé de '
              '${(budget.spent - budget.monthlyLimit).toStringAsFixed(2)}€.',
          actionText: 'Voir les solutions',
          categoryId: budget.categoryId,
          potentialSaving: budget.spent - budget.monthlyLimit,
        ));
      } else if (budget.percentUsed < 50 && budget.spent > 0) {
        // Budget sous-utilisé - suggérer de le réduire
        final suggestedBudget = budget.spent * 1.2; // 20% de marge
        if (suggestedBudget < budget.monthlyLimit * 0.7) {
          suggestions.add(AISuggestion(
            id: 'budget_optimize_${budget.id}',
            type: SuggestionType.budgetOptimization,
            priority: SuggestionPriority.low,
            title: 'Optimisation possible',
            description: 'Votre budget ${budget.displayName} pourrait être réduit à '
                '${suggestedBudget.toStringAsFixed(0)}€ basé sur vos habitudes.',
            actionText: 'Optimiser',
            potentialSaving: budget.monthlyLimit - suggestedBudget,
            metadata: {
              'currentBudget': budget.monthlyLimit,
              'suggestedBudget': suggestedBudget,
            },
          ));
        }
      }
    }

    return suggestions;
  }

  /// Trouver des opportunités d'économies
  static List<AISuggestion> _findSavingOpportunities(
    List<Expense> expenses,
    List<Category> categories,
    double? monthlyIncome,
  ) {
    final suggestions = <AISuggestion>[];
    if (expenses.isEmpty) return suggestions;

    // Grouper par catégorie
    final byCategory = <String, List<Expense>>{};
    for (final expense in expenses) {
      final catId = expense.categoryId ?? 'other';
      byCategory.putIfAbsent(catId, () => []).add(expense);
    }

    // Analyser chaque catégorie
    for (final entry in byCategory.entries) {
      final categoryExpenses = entry.value;
      final total = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final count = categoryExpenses.length;
      final average = total / count;

      // Suggérer des économies pour les catégories avec beaucoup de petites dépenses
      if (count > 10 && average < 20) {
        final potentialSaving = total * 0.2; // 20% d'économies potentielles
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => Category(
            id: '',
            userId: '',
            name: 'Autre',
            icon: 'help',
            color: '#9E9E9E',
            sortOrder: 0,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        suggestions.add(AISuggestion(
          id: 'saving_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          type: SuggestionType.savingOpportunity,
          priority: potentialSaving > 50 ? SuggestionPriority.medium : SuggestionPriority.low,
          title: 'Économies possibles en ${category.name}',
          description: 'Vous avez $count dépenses en ${category.name} ce mois. '
              'En réduisant de 20%, vous économiseriez ${potentialSaving.toStringAsFixed(2)}€.',
          actionText: 'Voir les détails',
          potentialSaving: potentialSaving,
          categoryId: entry.key,
          metadata: {
            'totalSpent': total,
            'expenseCount': count,
            'averageExpense': average,
          },
        ));
      }
    }

    // Si revenu mensuel fourni, suggérer un taux d'épargne
    if (monthlyIncome != null && monthlyIncome > 0) {
      final now = DateTime.now();
      final thisMonthExpenses = expenses.where((e) =>
          e.expenseDate.month == now.month && e.expenseDate.year == now.year).toList();
      final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

      final savingRate = ((monthlyIncome - thisMonthTotal) / monthlyIncome * 100);

      if (savingRate < 10) {
        suggestions.add(AISuggestion(
          id: 'saving_rate_${now.millisecondsSinceEpoch}',
          type: SuggestionType.smartSaving,
          priority: savingRate < 0 ? SuggestionPriority.critical : SuggestionPriority.high,
          title: savingRate < 0 ? 'Dépenses supérieures aux revenus' : 'Taux d\'épargne faible',
          description: savingRate < 0
              ? 'Vous dépensez plus que vos revenus. Revoyez vos habitudes.'
              : 'Votre taux d\'épargne est de ${savingRate.toStringAsFixed(1)}%. '
                  'L\'idéal serait d\'atteindre 20%.',
          actionText: 'Créer un objectif d\'épargne',
          potentialSaving: monthlyIncome * 0.2 - (monthlyIncome - thisMonthTotal),
          metadata: {
            'income': monthlyIncome,
            'expenses': thisMonthTotal,
            'savingRate': savingRate,
          },
        ));
      }
    }

    return suggestions;
  }

  /// Détecter les dépenses récurrentes
  static List<AISuggestion> _detectRecurringExpenses(List<Expense> expenses) {
    final suggestions = <AISuggestion>[];
    if (expenses.length < 20) return suggestions;

    // Grouper par note/description similaire
    final byNote = <String, List<Expense>>{};
    for (final expense in expenses) {
      if (expense.note != null && expense.note!.length > 3) {
        final key = expense.note!.toLowerCase().trim();
        byNote.putIfAbsent(key, () => []).add(expense);
      }
    }

    // Détecter les patterns récurrents
    for (final entry in byNote.entries) {
      if (entry.value.length >= 3) {
        // Au moins 3 occurrences
        final amounts = entry.value.map((e) => e.amount).toList();
        final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;

        // Vérifier si les montants sont similaires (±10%)
        final allSimilar = amounts.every((a) => (a - avgAmount).abs() / avgAmount < 0.1);

        if (allSimilar) {
          final monthlyEstimate = avgAmount; // Simplification

          suggestions.add(AISuggestion(
            id: 'recurring_${entry.key.hashCode}',
            type: SuggestionType.recurringExpenseAlert,
            priority: monthlyEstimate > 50 ? SuggestionPriority.medium : SuggestionPriority.low,
            title: 'Dépense récurrente détectée',
            description: '"${entry.key}" apparaît ${entry.value.length} fois avec un montant moyen de '
                '${avgAmount.toStringAsFixed(2)}€. Pensez à négocier ou chercher des alternatives.',
            actionText: 'Analyser',
            potentialSaving: monthlyEstimate * 0.1, // 10% d'économies potentielles
            metadata: {
              'note': entry.key,
              'occurrences': entry.value.length,
              'averageAmount': avgAmount,
            },
          ));
        }
      }
    }

    return suggestions;
  }

  /// Analyser les tendances saisonnières
  static List<AISuggestion> _analyzeSeasonalTrends(List<Expense> expenses) {
    final suggestions = <AISuggestion>[];
    if (expenses.length < 60) return suggestions; // Besoin de plusieurs mois de données

    final now = DateTime.now();
    final currentMonth = now.month;

    // Calculer les dépenses moyennes par mois
    final byMonth = <int, List<double>>{};
    for (final expense in expenses) {
      byMonth.putIfAbsent(expense.expenseDate.month, () => []).add(expense.amount);
    }

    final monthlyAverages = <int, double>{};
    for (final entry in byMonth.entries) {
      monthlyAverages[entry.key] = entry.value.reduce((a, b) => a + b);
    }

    // Identifier les mois coûteux
    final overallAvg = monthlyAverages.values.reduce((a, b) => a + b) / monthlyAverages.length;
    final expensiveMonths = monthlyAverages.entries
        .where((e) => e.value > overallAvg * 1.3)
        .map((e) => e.key)
        .toList();

    // Si le mois actuel ou le mois prochain est historiquement coûteux
    if (expensiveMonths.contains(currentMonth) || expensiveMonths.contains((currentMonth % 12) + 1)) {
      final targetMonth = expensiveMonths.contains(currentMonth) ? currentMonth : (currentMonth % 12) + 1;
      final monthName = _getMonthName(targetMonth);

      suggestions.add(AISuggestion(
        id: 'seasonal_${targetMonth}_${now.year}',
        type: SuggestionType.seasonalTrend,
        priority: SuggestionPriority.medium,
        title: 'Préparation pour $monthName',
        description: 'Historiquement, $monthName est un mois plus coûteux pour vous. '
            'Préparez un budget supplémentaire.',
        actionText: 'Ajuster le budget',
        metadata: {
          'month': targetMonth,
          'historicalAverage': monthlyAverages[targetMonth],
          'overallAverage': overallAvg,
        },
      ));
    }

    return suggestions;
  }

  /// Recommander des objectifs
  static List<AISuggestion> _recommendGoals(
    List<Expense> expenses,
    double? monthlyIncome,
  ) {
    final suggestions = <AISuggestion>[];
    if (expenses.isEmpty) return suggestions;

    final now = DateTime.now();
    final thisMonthExpenses = expenses.where((e) =>
        e.expenseDate.month == now.month && e.expenseDate.year == now.year).toList();
    final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Suggérer un objectif d'épargne basé sur les dépenses
    final suggestedGoal = thisMonthTotal * 0.1; // 10% des dépenses comme objectif d'épargne

    if (suggestedGoal > 20) {
      suggestions.add(AISuggestion(
        id: 'goal_recommendation_${now.millisecondsSinceEpoch}',
        type: SuggestionType.goalRecommendation,
        priority: SuggestionPriority.low,
        title: 'Créer un objectif d\'épargne',
        description: 'Basé sur vos dépenses, économisez ${suggestedGoal.toStringAsFixed(0)}€/mois '
            'pour atteindre ${(suggestedGoal * 12).toStringAsFixed(0)}€ en un an.',
        actionText: 'Créer l\'objectif',
        potentialSaving: suggestedGoal * 12,
        metadata: {
          'monthlyTarget': suggestedGoal,
          'yearlyTarget': suggestedGoal * 12,
        },
      ));
    }

    return suggestions;
  }

  /// Obtenir le nom du mois
  static String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  /// Générer un résumé textuel pour l'assistant IA
  static String generateAISummary({
    required List<Expense> expenses,
    required List<Category> categories,
    required List<Budget> budgets,
    double? monthlyIncome,
  }) {
    final buffer = StringBuffer();
    final suggestions = analyzeAndSuggest(
      expenses: expenses,
      categories: categories,
      budgets: budgets,
      monthlyIncome: monthlyIncome,
    );

    if (suggestions.isEmpty) {
      return 'Vos finances sont en bon état ! Continuez ainsi.';
    }

    buffer.writeln('📊 Analyse de vos finances:\n');

    // Résumé des suggestions critiques
    final critical = suggestions.where((s) => s.priority == SuggestionPriority.critical);
    if (critical.isNotEmpty) {
      buffer.writeln('⚠️ Actions urgentes:');
      for (final s in critical) {
        buffer.writeln('  • ${s.title}: ${s.description}');
      }
      buffer.writeln();
    }

    // Économies potentielles
    final totalSavings = suggestions
        .where((s) => s.potentialSaving != null)
        .fold<double>(0, (sum, s) => sum + s.potentialSaving!);

    if (totalSavings > 0) {
      buffer.writeln('💰 Économies potentielles: ${totalSavings.toStringAsFixed(2)}€/mois');
      buffer.writeln();
    }

    // Top 3 suggestions
    buffer.writeln('💡 Recommandations:');
    for (final s in suggestions.take(3)) {
      buffer.writeln('  ${s.icon} ${s.title}');
    }

    return buffer.toString();
  }
}
