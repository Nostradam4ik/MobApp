import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/achievement.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Provider pour la gestion des achievements et gamification
class AchievementProvider extends ChangeNotifier {
  List<Achievement> _achievements = [];
  List<AchievementType> _achievementTypes = [];
  Streak? _streak;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Achievement> get achievements => _achievements;
  List<AchievementType> get achievementTypes => _achievementTypes;
  Streak? get streak => _streak;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Score total
  int get totalScore => _achievements.fold(0, (sum, a) => sum + a.points);

  /// Nombre de badges
  int get badgeCount => _achievements.length;

  /// Streak actuel
  int get currentStreak => _streak?.currentStreak ?? 0;

  /// Plus long streak
  int get longestStreak => _streak?.longestStreak ?? 0;

  /// Achievements non obtenus
  List<AchievementType> get lockedAchievements {
    final earnedTypes = _achievements.map((a) => a.achievementType).toSet();
    return _achievementTypes.where((t) => !earnedTypes.contains(t.id)).toList();
  }

  /// Met à jour l'ID utilisateur
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadData();
      } else {
        _achievements = [];
        _streak = null;
        notifyListeners();
      }
    }
  }

  /// Charge toutes les données
  Future<void> loadData() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadAchievements(),
        _loadAchievementTypes(),
        _loadStreak(),
      ]);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAchievements() async {
    _achievements = await SupabaseService.getAchievements();
  }

  Future<void> _loadAchievementTypes() async {
    _achievementTypes = await SupabaseService.getAchievementTypes();
  }

  Future<void> _loadStreak() async {
    _streak = await SupabaseService.getStreak();
  }

  /// Met à jour le streak (appelé après ajout de dépense)
  Future<void> updateStreak() async {
    if (_userId == null || _streak == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Si déjà actif aujourd'hui, rien à faire
    if (_streak!.isActiveToday) return;

    int newStreak;
    if (_streak!.canContinue) {
      // Continue le streak
      newStreak = _streak!.currentStreak + 1;
    } else {
      // Nouveau streak
      newStreak = 1;
    }

    final updatedStreak = Streak(
      id: _streak!.id,
      userId: _userId!,
      currentStreak: newStreak,
      longestStreak:
          newStreak > _streak!.longestStreak ? newStreak : _streak!.longestStreak,
      lastActivityDate: today,
      streakType: _streak!.streakType,
      createdAt: _streak!.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await SupabaseService.updateStreak(updatedStreak);
      _streak = updatedStreak;

      // Vérifier les achievements de streak
      await _checkStreakAchievements(newStreak);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  /// Vérifie et accorde les achievements de streak
  Future<void> _checkStreakAchievements(int streak) async {
    final streakAchievements = {
      3: 'streak_3',
      7: 'streak_7',
      30: 'streak_30',
      100: 'streak_100',
    };

    for (final entry in streakAchievements.entries) {
      if (streak >= entry.key) {
        await _awardAchievement(entry.value);
      }
    }
  }

  /// Vérifie les achievements de nombre de dépenses
  Future<void> checkExpenseAchievements(int expenseCount) async {
    final expenseAchievements = {
      1: 'expense_first',
      10: 'expense_10',
      50: 'expense_50',
      100: 'expense_100',
      500: 'expense_500',
    };

    for (final entry in expenseAchievements.entries) {
      if (expenseCount >= entry.key) {
        await _awardAchievement(entry.value);
      }
    }
  }

  /// Vérifie les achievements de budget
  Future<void> checkBudgetAchievements({
    required bool firstBudget,
    required bool budgetRespected,
    required int monthsRespected,
  }) async {
    if (firstBudget) {
      await _awardAchievement('budget_first');
    }
    if (budgetRespected) {
      await _awardAchievement('budget_respected');
    }
    if (monthsRespected >= 3) {
      await _awardAchievement('budget_master');
    }
  }

  /// Vérifie les achievements d'objectifs
  Future<void> checkGoalAchievements({
    required bool firstGoal,
    required bool reached50,
    required bool completed,
    required int totalCompleted,
  }) async {
    if (firstGoal) {
      await _awardAchievement('goal_first');
    }
    if (reached50) {
      await _awardAchievement('goal_50');
    }
    if (completed) {
      await _awardAchievement('goal_complete');
    }
    if (totalCompleted >= 5) {
      await _awardAchievement('goal_master');
    }
  }

  /// Accorde un achievement
  Future<void> _awardAchievement(String achievementTypeId) async {
    if (_userId == null) return;

    // Vérifier si déjà obtenu
    if (_achievements.any((a) => a.achievementType == achievementTypeId)) {
      return;
    }

    // Trouver le type
    final type = _achievementTypes.firstWhere(
      (t) => t.id == achievementTypeId,
      orElse: () => AchievementType(
        id: achievementTypeId,
        title: 'Achievement',
        description: '',
        icon: 'trophy',
        category: 'special',
      ),
    );

    try {
      final achievement = Achievement(
        id: const Uuid().v4(),
        userId: _userId!,
        achievementType: achievementTypeId,
        title: type.title,
        description: type.description,
        icon: type.icon,
        points: type.points,
        earnedAt: DateTime.now(),
      );

      final created = await SupabaseService.createAchievement(achievement);
      _achievements.add(created);

      // Notification
      await NotificationService.showAchievementNotification(
        title: type.title,
        description: type.description,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
