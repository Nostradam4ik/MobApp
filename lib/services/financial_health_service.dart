import '../data/models/financial_health.dart';
import '../data/models/expense.dart';
import '../data/models/budget.dart';
import '../data/models/goal.dart';
import '../data/models/bill_reminder.dart';
import 'local_storage_service.dart';

/// Service pour calculer le score de santé financière
class FinancialHealthService {
  FinancialHealthService._();

  static const String _keyPreviousScore = 'financial_health_previous_score';
  static const String _keyLastCalculation = 'financial_health_last_calc';

  /// Calcule le score de santé financière complet
  static FinancialHealth calculateHealth({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<BillReminder> billReminders,
    double? monthlyIncome,
  }) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    // Filtrer les dépenses du mois
    final monthExpenses = expenses.where((e) =>
      e.expenseDate.year == now.year && e.expenseDate.month == now.month
    ).toList();

    // Calculer chaque composant
    final budgetScore = _calculateBudgetScore(monthExpenses, budgets);
    final savingsScore = _calculateSavingsScore(monthExpenses, monthlyIncome, goals);
    final consistencyScore = _calculateConsistencyScore(expenses);
    final goalsScore = _calculateGoalsScore(goals);
    final billsScore = _calculateBillsScore(billReminders);

    // Score global pondéré
    final overallScore = _calculateOverallScore(
      budgetScore: budgetScore.score,
      savingsScore: savingsScore.score,
      consistencyScore: consistencyScore.score,
      goalsScore: goalsScore.score,
      billsScore: billsScore.score,
    );

    // Récupérer le score précédent pour le trend
    final previousScore = LocalStorageService.getInt(_keyPreviousScore) ?? overallScore;
    final trend = overallScore > previousScore ? 1 : (overallScore < previousScore ? -1 : 0);

    // Sauvegarder le score actuel
    LocalStorageService.setInt(_keyPreviousScore, overallScore);
    LocalStorageService.setString(_keyLastCalculation, now.toIso8601String());

    return FinancialHealth(
      overallScore: overallScore,
      level: FinancialHealth.getLevelFromScore(overallScore),
      budgetScore: budgetScore,
      savingsScore: savingsScore,
      consistencyScore: consistencyScore,
      goalsScore: goalsScore,
      billsScore: billsScore,
      calculatedAt: now,
      trend: trend,
      previousScore: previousScore,
    );
  }

  /// Score de respect des budgets (25 points max)
  static HealthComponent _calculateBudgetScore(
    List<Expense> monthExpenses,
    List<Budget> budgets,
  ) {
    if (budgets.isEmpty) {
      return const HealthComponent(
        name: 'Budgets',
        description: 'Respect de vos budgets mensuels',
        score: 50, // Score neutre si pas de budget
        icon: '💰',
        tips: ['Créez des budgets pour mieux contrôler vos dépenses'],
      );
    }

    int totalScore = 0;
    int budgetCount = 0;
    List<String> tips = [];

    for (final budget in budgets) {
      final spent = monthExpenses
          .where((e) => budget.categoryId == null || e.categoryId == budget.categoryId)
          .fold(0.0, (sum, e) => sum + e.amount);

      final percentage = (spent / budget.monthlyLimit) * 100;

      if (percentage <= 80) {
        totalScore += 100;
      } else if (percentage <= 100) {
        totalScore += 70;
      } else if (percentage <= 120) {
        totalScore += 40;
        tips.add('Budget "${budget.displayName}" proche de la limite');
      } else {
        totalScore += 10;
        tips.add('Budget "${budget.displayName}" dépassé !');
      }
      budgetCount++;
    }

    final score = budgetCount > 0 ? (totalScore ~/ budgetCount) : 50;

    return HealthComponent(
      name: 'Budgets',
      description: 'Respect de vos budgets mensuels',
      score: score,
      icon: '💰',
      tips: tips.isEmpty ? ['Continuez à respecter vos budgets !'] : tips,
    );
  }

  /// Score d'épargne (25 points max)
  static HealthComponent _calculateSavingsScore(
    List<Expense> monthExpenses,
    double? monthlyIncome,
    List<Goal> goals,
  ) {
    List<String> tips = [];

    if (monthlyIncome == null || monthlyIncome <= 0) {
      // Estimer basé sur les objectifs
      final activeGoals = goals.where((g) => !g.isCompleted).toList();
      if (activeGoals.isEmpty) {
        return HealthComponent(
          name: 'Épargne',
          description: 'Votre capacité d\'épargne',
          score: 50,
          icon: '🐷',
          tips: ['Renseignez votre revenu pour un score plus précis'],
        );
      }

      // Score basé sur la progression des objectifs
      final avgProgress = activeGoals.fold(0.0, (sum, g) => sum + g.progress) / activeGoals.length;
      return HealthComponent(
        name: 'Épargne',
        description: 'Progression vers vos objectifs',
        score: (avgProgress * 100).round().clamp(0, 100),
        icon: '🐷',
        tips: ['Continuez à épargner pour vos objectifs !'],
      );
    }

    final totalSpent = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final savingsRate = ((monthlyIncome - totalSpent) / monthlyIncome * 100);

    int score;
    if (savingsRate >= 30) {
      score = 100;
      tips.add('Excellent taux d\'épargne de ${savingsRate.toStringAsFixed(0)}% !');
    } else if (savingsRate >= 20) {
      score = 85;
      tips.add('Bon taux d\'épargne de ${savingsRate.toStringAsFixed(0)}%');
    } else if (savingsRate >= 10) {
      score = 65;
      tips.add('Taux d\'épargne de ${savingsRate.toStringAsFixed(0)}% - Visez 20%');
    } else if (savingsRate >= 0) {
      score = 40;
      tips.add('Épargne faible - Essayez de réduire les dépenses non essentielles');
    } else {
      score = 15;
      tips.add('Attention : Vous dépensez plus que vos revenus !');
    }

    return HealthComponent(
      name: 'Épargne',
      description: 'Votre capacité d\'épargne',
      score: score,
      icon: '🐷',
      tips: tips,
    );
  }

  /// Score de régularité (20 points max)
  static HealthComponent _calculateConsistencyScore(List<Expense> allExpenses) {
    List<String> tips = [];

    if (allExpenses.isEmpty) {
      return const HealthComponent(
        name: 'Régularité',
        description: 'Suivi régulier de vos dépenses',
        score: 50,
        icon: '📊',
        tips: ['Commencez à enregistrer vos dépenses quotidiennement'],
      );
    }

    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    // Compter les jours avec au moins une dépense enregistrée
    final daysWithExpenses = <int>{};
    for (final expense in allExpenses) {
      if (expense.expenseDate.isAfter(last30Days)) {
        final dayKey = expense.expenseDate.year * 10000 + expense.expenseDate.month * 100 + expense.expenseDate.day;
        daysWithExpenses.add(dayKey);
      }
    }

    // Calculer la régularité (sur 30 jours)
    final consistencyRate = (daysWithExpenses.length / 30 * 100).clamp(0, 100);

    int score;
    if (consistencyRate >= 80) {
      score = 100;
      tips.add('Excellent suivi ! ${daysWithExpenses.length} jours actifs ce mois');
    } else if (consistencyRate >= 60) {
      score = 75;
      tips.add('Bon suivi, essayez d\'enregistrer chaque jour');
    } else if (consistencyRate >= 40) {
      score = 50;
      tips.add('Suivi irrégulier - N\'oubliez pas d\'enregistrer vos dépenses');
    } else {
      score = 25;
      tips.add('Prenez l\'habitude d\'enregistrer vos dépenses quotidiennement');
    }

    return HealthComponent(
      name: 'Régularité',
      description: 'Suivi régulier de vos dépenses',
      score: score,
      icon: '📊',
      tips: tips,
    );
  }

  /// Score des objectifs (15 points max)
  static HealthComponent _calculateGoalsScore(List<Goal> goals) {
    List<String> tips = [];

    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    if (goals.isEmpty) {
      return HealthComponent(
        name: 'Objectifs',
        description: 'Progression vers vos objectifs',
        score: 50,
        icon: '🎯',
        tips: ['Créez un objectif d\'épargne pour vous motiver !'],
      );
    }

    int score = 0;

    // Bonus pour objectifs complétés
    score += (completedGoals.length * 10).clamp(0, 30);

    // Score basé sur la progression moyenne
    if (activeGoals.isNotEmpty) {
      final avgProgress = activeGoals.fold(0.0, (sum, g) => sum + g.progress) / activeGoals.length;
      score += (avgProgress * 70).round();

      // Vérifier les objectifs en retard
      final now = DateTime.now();
      final behindSchedule = activeGoals.where((g) {
        if (g.deadline == null) return false;
        final expectedProgress = now.difference(g.createdAt).inDays /
            g.deadline!.difference(g.createdAt).inDays;
        return g.progress < expectedProgress - 0.1;
      }).toList();

      if (behindSchedule.isNotEmpty) {
        tips.add('${behindSchedule.length} objectif(s) en retard');
      }
    }

    score = score.clamp(0, 100);

    if (tips.isEmpty) {
      if (score >= 80) {
        tips.add('Excellente progression vers vos objectifs !');
      } else {
        tips.add('Continuez vos efforts pour atteindre vos objectifs');
      }
    }

    return HealthComponent(
      name: 'Objectifs',
      description: 'Progression vers vos objectifs',
      score: score,
      icon: '🎯',
      tips: tips,
    );
  }

  /// Score des factures (15 points max)
  static HealthComponent _calculateBillsScore(List<BillReminder> billReminders) {
    List<String> tips = [];

    final activeReminders = billReminders.where((b) => b.isActive && !b.isPaid).toList();

    if (billReminders.isEmpty) {
      return const HealthComponent(
        name: 'Factures',
        description: 'Gestion de vos factures récurrentes',
        score: 80,
        icon: '📋',
        tips: ['Ajoutez vos factures récurrentes pour ne rien oublier'],
      );
    }

    final overdueCount = activeReminders.where((b) => b.isOverdue).length;
    final upcomingCount = activeReminders.where((b) => b.daysUntilDue <= 7 && !b.isOverdue).length;
    final paidThisMonth = billReminders.where((b) => b.isPaid).length;

    int score = 100;

    // Pénalités pour factures en retard
    score -= overdueCount * 25;

    // Légère pénalité pour factures à venir
    score -= upcomingCount * 5;

    // Bonus pour factures payées
    score += (paidThisMonth * 2).clamp(0, 10);

    score = score.clamp(0, 100);

    if (overdueCount > 0) {
      tips.add('$overdueCount facture(s) en retard !');
    }
    if (upcomingCount > 0) {
      tips.add('$upcomingCount facture(s) à payer cette semaine');
    }
    if (tips.isEmpty) {
      tips.add('Toutes vos factures sont à jour 👍');
    }

    return HealthComponent(
      name: 'Factures',
      description: 'Gestion de vos factures récurrentes',
      score: score,
      icon: '📋',
      tips: tips,
    );
  }

  /// Calcule le score global pondéré
  static int _calculateOverallScore({
    required int budgetScore,
    required int savingsScore,
    required int consistencyScore,
    required int goalsScore,
    required int billsScore,
  }) {
    // Pondération:
    // - Budgets: 25%
    // - Épargne: 25%
    // - Régularité: 20%
    // - Objectifs: 15%
    // - Factures: 15%

    final weighted =
        budgetScore * 0.25 +
        savingsScore * 0.25 +
        consistencyScore * 0.20 +
        goalsScore * 0.15 +
        billsScore * 0.15;

    return weighted.round().clamp(0, 100);
  }

  /// Récupère les conseils prioritaires basés sur le score
  static List<String> getPriorityTips(FinancialHealth health) {
    final tips = <String>[];

    // Ajouter les conseils du composant le plus faible
    tips.addAll(health.weakestComponent.tips);

    // Ajouter des conseils généraux basés sur le niveau
    switch (health.level) {
      case HealthLevel.critical:
        tips.add('Établissez un budget d\'urgence pour vos dépenses essentielles');
        break;
      case HealthLevel.poor:
        tips.add('Identifiez 3 dépenses que vous pourriez réduire ce mois');
        break;
      case HealthLevel.fair:
        tips.add('Automatisez un virement épargne le jour de paie');
        break;
      case HealthLevel.good:
        tips.add('Augmentez progressivement votre taux d\'épargne');
        break;
      case HealthLevel.excellent:
        tips.add('Envisagez d\'investir votre épargne excédentaire');
        break;
    }

    return tips.take(3).toList();
  }
}
