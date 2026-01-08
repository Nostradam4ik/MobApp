import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/budget.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Provider pour la gestion des budgets
class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  DateTime _currentMonth = DateTime.now();

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Budget global (sans catégorie)
  Budget? get globalBudget {
    try {
      return _budgets.firstWhere((b) => b.isGlobal);
    } catch (e) {
      return null;
    }
  }

  /// Budgets par catégorie
  List<Budget> get categoryBudgets =>
      _budgets.where((b) => !b.isGlobal).toList();

  /// Met à jour l'ID utilisateur
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadBudgets();
      } else {
        _budgets = [];
        notifyListeners();
      }
    }
  }

  /// Charge les budgets
  Future<void> loadBudgets() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await SupabaseService.getBudgets(month: _currentMonth);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des budgets';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour les montants dépensés
  Future<void> updateSpentAmounts(Map<String, double> expensesByCategory, double totalSpent) async {
    final updatedBudgets = <Budget>[];

    for (final budget in _budgets) {
      double spent;
      if (budget.isGlobal) {
        spent = totalSpent;
      } else {
        spent = expensesByCategory[budget.categoryId] ?? 0;
      }

      final updated = budget.copyWith(spent: spent);
      updatedBudgets.add(updated);

      // Vérifier les alertes
      if (updated.shouldAlert && !budget.shouldAlert) {
        await NotificationService.showBudgetAlert(
          categoryName: updated.displayName,
          percentage: updated.percentUsed.toInt(),
        );
      }
    }

    _budgets = updatedBudgets;
    notifyListeners();
  }

  /// Récupère un budget par ID
  Budget? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère le budget d'une catégorie
  Budget? getBudgetByCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Crée un nouveau budget
  Future<bool> createBudget({
    required double monthlyLimit,
    String? categoryId,
    int alertThreshold = 80,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final budget = Budget(
        id: const Uuid().v4(),
        userId: _userId!,
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        alertThreshold: alertThreshold,
        isActive: true,
        periodStart: DateTime(_currentMonth.year, _currentMonth.month, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await SupabaseService.createBudget(budget);
      _budgets.add(created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création du budget';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour un budget
  Future<bool> updateBudget(Budget budget) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du budget';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime un budget
  Future<bool> deleteBudget(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression du budget';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
