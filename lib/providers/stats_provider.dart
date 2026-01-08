import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/expense.dart';

/// Provider pour les statistiques
class StatsProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  String? _userId;
  StatsPeriod _selectedPeriod = StatsPeriod.month;

  StatsPeriod get selectedPeriod => _selectedPeriod;

  /// Met à jour les données
  void updateData(String? userId, List<Expense> expenses) {
    if (_userId != userId || _expenses != expenses) {
      _userId = userId;
      _expenses = expenses;
      notifyListeners();
    }
  }

  /// Change la période sélectionnée
  void setSelectedPeriod(StatsPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  /// Total des dépenses du mois
  double get monthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total des dépenses de la semaine
  double get weekTotal {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _expenses
        .where((e) => e.expenseDate.isAfter(start.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total des dépenses du jour
  double get dayTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.expenseDate.year == now.year &&
            e.expenseDate.month == now.month &&
            e.expenseDate.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Moyenne journalière du mois
  double get dailyAverage {
    final now = DateTime.now();
    final daysElapsed = now.day;
    if (daysElapsed == 0) return 0;
    return monthTotal / daysElapsed;
  }

  /// Dépenses par catégorie
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    final now = DateTime.now();

    for (final expense in _expenses) {
      if (expense.expenseDate.year == now.year &&
          expense.expenseDate.month == now.month) {
        final key = expense.category?.name ?? 'Autre';
        map[key] = (map[key] ?? 0) + expense.amount;
      }
    }

    return map;
  }

  /// Dépenses par catégorie avec couleurs
  List<CategoryStat> get categoryStats {
    final map = <String, CategoryStat>{};
    final now = DateTime.now();

    for (final expense in _expenses) {
      if (expense.expenseDate.year == now.year &&
          expense.expenseDate.month == now.month) {
        final key = expense.categoryId ?? 'other';
        final existing = map[key];
        if (existing != null) {
          map[key] = existing.copyWith(amount: existing.amount + expense.amount);
        } else {
          map[key] = CategoryStat(
            categoryId: key,
            categoryName: expense.category?.name ?? 'Autre',
            color: expense.category?.color ?? '#6B7280',
            amount: expense.amount,
          );
        }
      }
    }

    final stats = map.values.toList();
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  /// Données pour le graphique journalier
  List<DailyStat> get dailyStats {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final map = <int, double>{};

    for (final expense in _expenses) {
      if (expense.expenseDate.year == now.year &&
          expense.expenseDate.month == now.month) {
        final day = expense.expenseDate.day;
        map[day] = (map[day] ?? 0) + expense.amount;
      }
    }

    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      return DailyStat(day: day, amount: map[day] ?? 0);
    });
  }

  /// Données pour le graphique hebdomadaire
  List<WeeklyStat> get weeklyStats {
    final now = DateTime.now();
    final stats = <WeeklyStat>[];

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

      final amount = _expenses
          .where((e) =>
              e.expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
              e.expenseDate.isBefore(end.add(const Duration(days: 1))))
          .fold(0.0, (sum, e) => sum + e.amount);

      stats.add(WeeklyStat(
        weekNumber: 4 - i,
        startDate: start,
        endDate: end,
        amount: amount,
      ));
    }

    return stats;
  }

  /// Top catégories (les plus dépensières)
  List<CategoryStat> get topCategories {
    final stats = categoryStats;
    return stats.take(5).toList();
  }

  /// Nombre de transactions ce mois
  int get transactionCount {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .length;
  }

  /// Dépense moyenne par transaction
  double get averageTransaction {
    if (transactionCount == 0) return 0;
    return monthTotal / transactionCount;
  }

  /// Jour le plus dépensier
  int? get highestSpendingDay {
    if (dailyStats.isEmpty) return null;
    final maxStat = dailyStats.reduce((a, b) => a.amount > b.amount ? a : b);
    return maxStat.amount > 0 ? maxStat.day : null;
  }
}

/// Statistique par catégorie
class CategoryStat {
  final String categoryId;
  final String categoryName;
  final String color;
  final double amount;

  const CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.amount,
  });

  CategoryStat copyWith({
    String? categoryId,
    String? categoryName,
    String? color,
    double? amount,
  }) {
    return CategoryStat(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      color: color ?? this.color,
      amount: amount ?? this.amount,
    );
  }

  double getPercentage(double total) {
    if (total == 0) return 0;
    return (amount / total * 100);
  }
}

/// Statistique journalière
class DailyStat {
  final int day;
  final double amount;

  const DailyStat({required this.day, required this.amount});
}

/// Statistique hebdomadaire
class WeeklyStat {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;

  const WeeklyStat({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.amount,
  });
}
