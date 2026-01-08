import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../services/supabase_service.dart';
import '../services/home_widget_service.dart';

/// Provider pour la gestion des dépenses
class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  DateTime _selectedMonth = DateTime.now();

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;

  /// Dépenses du jour
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month &&
          e.expenseDate.day == now.day;
    }).toList();
  }

  /// Dépenses de la semaine
  List<Expense> get weekExpenses {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    return _expenses.where((e) {
      return e.expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
          e.expenseDate.isBefore(end);
    }).toList();
  }

  /// Dépenses du mois
  List<Expense> get monthExpenses {
    return _expenses.where((e) {
      return e.expenseDate.year == _selectedMonth.year &&
          e.expenseDate.month == _selectedMonth.month;
    }).toList();
  }

  /// Total du jour
  double get todayTotal =>
      todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Total de la semaine
  double get weekTotal =>
      weekExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Total du mois
  double get monthTotal =>
      monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Met à jour l'ID utilisateur
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadExpenses();
      } else {
        _expenses = [];
        notifyListeners();
      }
    }
  }

  /// Change le mois sélectionné
  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    loadExpenses();
  }

  /// Charge les dépenses
  Future<void> loadExpenses() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await SupabaseService.getMonthlyExpenses(_selectedMonth);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des dépenses';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère une dépense par ID
  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Crée une nouvelle dépense
  Future<bool> createExpense({
    required double amount,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? date,
    Category? category,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final expense = Expense(
        id: const Uuid().v4(),
        userId: _userId!,
        categoryId: categoryId,
        accountId: accountId,
        amount: amount,
        note: note,
        expenseDate: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: category,
      );

      final created = await SupabaseService.createExpense(expense);
      _expenses.insert(0, created);
      _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour une dépense
  Future<bool> updateExpense(Expense expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }
      _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la dépense';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime une dépense
  Future<bool> deleteExpense(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression de la dépense';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtient les dépenses par catégorie
  Map<String, double> getExpensesByCategory() {
    final map = <String, double>{};
    for (final expense in monthExpenses) {
      final key = expense.categoryId ?? 'other';
      map[key] = (map[key] ?? 0) + expense.amount;
    }
    return map;
  }

  /// Obtient les dépenses par jour pour le mois
  Map<int, double> getDailyExpenses() {
    final map = <int, double>{};
    for (final expense in monthExpenses) {
      final day = expense.expenseDate.day;
      map[day] = (map[day] ?? 0) + expense.amount;
    }
    return map;
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Met à jour le widget d'accueil avec les données actuelles
  Future<void> updateHomeWidget({double? budgetLimit, int streakDays = 0}) async {
    if (!HomeWidgetService.isSupported) return;

    await HomeWidgetService.updateWidgetData(
      monthTotal: monthTotal,
      weekTotal: weekTotal,
      todayTotal: todayTotal,
      budgetLimit: budgetLimit,
      budgetPercent: budgetLimit != null && budgetLimit > 0
          ? (monthTotal / budgetLimit * 100).clamp(0, 100)
          : null,
      streakDays: streakDays,
    );
  }
}
