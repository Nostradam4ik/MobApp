import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/goal.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Provider pour la gestion des objectifs financiers
class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  List<Goal> _completedGoals = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Goal> get goals => _goals;
  List<Goal> get completedGoals => _completedGoals;
  List<Goal> get allGoals => [..._goals, ..._completedGoals];
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Total épargné sur tous les objectifs actifs
  double get totalSaved => _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  /// Total cible de tous les objectifs actifs
  double get totalTarget => _goals.fold(0.0, (sum, g) => sum + g.targetAmount);

  /// Met à jour l'ID utilisateur
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadGoals();
      } else {
        _goals = [];
        _completedGoals = [];
        notifyListeners();
      }
    }
  }

  /// Charge les objectifs
  Future<void> loadGoals() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allGoals = await SupabaseService.getGoals(includeCompleted: true);
      _goals = allGoals.where((g) => !g.isCompleted).toList();
      _completedGoals = allGoals.where((g) => g.isCompleted).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des objectifs';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère un objectif par ID
  Goal? getGoalById(String id) {
    try {
      return allGoals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Crée un nouvel objectif
  Future<bool> createGoal({
    required String title,
    String? description,
    required double targetAmount,
    String icon = 'savings',
    String color = '#10B981',
    DateTime? deadline,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final goal = Goal(
        id: const Uuid().v4(),
        userId: _userId!,
        title: title,
        description: description,
        targetAmount: targetAmount,
        currentAmount: 0,
        icon: icon,
        color: color,
        deadline: deadline,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await SupabaseService.createGoal(goal);
      _goals.add(created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création de l\'objectif';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour un objectif
  Future<bool> updateGoal(Goal goal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateGoal(goal);

      // Supprimer l'objectif des deux listes d'abord
      _goals.removeWhere((g) => g.id == goal.id);
      _completedGoals.removeWhere((g) => g.id == goal.id);

      // Puis l'ajouter dans la bonne liste selon son état
      if (goal.isCompleted) {
        _completedGoals.insert(0, goal);
      } else {
        _goals.insert(0, goal);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de l\'objectif';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ajoute une contribution à un objectif
  Future<bool> addContribution({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contribution = GoalContribution(
        id: const Uuid().v4(),
        goalId: goalId,
        userId: _userId!,
        amount: amount,
        note: note,
        contributionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await SupabaseService.addGoalContribution(contribution);

      // Recharger l'objectif pour avoir le montant mis à jour
      final updatedGoal = await SupabaseService.getGoal(goalId);
      if (updatedGoal != null) {
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;

          // Vérifier si l'objectif est atteint
          if (updatedGoal.isReached && !_goals[index].isReached) {
            await NotificationService.showGoalCompletedNotification(
              goalTitle: updatedGoal.title,
            );
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de la contribution';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime un objectif
  Future<bool> deleteGoal(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      _completedGoals.removeWhere((g) => g.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression de l\'objectif';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupère les contributions d'un objectif
  Future<List<GoalContribution>> getContributions(String goalId) async {
    try {
      return await SupabaseService.getGoalContributions(goalId);
    } catch (e) {
      return [];
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
