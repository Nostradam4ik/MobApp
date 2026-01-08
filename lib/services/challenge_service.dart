import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../data/models/savings_challenge.dart';
import '../data/models/expense.dart';
import 'local_storage_service.dart';

/// Service pour gérer les challenges d'épargne
class ChallengeService {
  ChallengeService._();

  static const String _storageKey = 'savings_challenges';
  static const String _xpKey = 'user_total_xp';
  static const String _levelKey = 'user_level';
  static const String _streakKey = 'challenge_streak';

  // ============================================================
  // CRUD Operations
  // ============================================================

  /// Récupère tous les challenges
  static List<SavingsChallenge> getAllChallenges() {
    final jsonString = LocalStorageService.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => SavingsChallenge.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde tous les challenges
  static Future<void> _saveChallenges(List<SavingsChallenge> challenges) async {
    final jsonString = json.encode(challenges.map((c) => c.toJson()).toList());
    await LocalStorageService.setString(_storageKey, jsonString);
  }

  /// Ajoute un nouveau challenge
  static Future<SavingsChallenge> createChallenge({
    required String userId,
    required String title,
    required String description,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required DateTime startDate,
    required DateTime endDate,
    double targetAmount = 0,
    String? categoryId,
    int targetDays = 0,
    int xpReward = 100,
    Map<String, dynamic> rules = const {},
  }) async {
    final challenge = SavingsChallenge(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      type: type,
      difficulty: difficulty,
      status: ChallengeStatus.active,
      startDate: startDate,
      endDate: endDate,
      targetAmount: targetAmount,
      currentAmount: 0,
      categoryId: categoryId,
      targetDays: targetDays,
      currentDays: 0,
      xpReward: xpReward,
      rules: rules,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final challenges = getAllChallenges();
    challenges.add(challenge);
    await _saveChallenges(challenges);

    return challenge;
  }

  /// Crée un challenge à partir d'un template
  static Future<SavingsChallenge> createFromTemplate({
    required String userId,
    required Map<String, dynamic> template,
  }) async {
    final now = DateTime.now();
    final targetDays = template['targetDays'] as int? ?? 7;

    return createChallenge(
      userId: userId,
      title: template['title'] as String,
      description: template['description'] as String,
      type: template['type'] as ChallengeType,
      difficulty: template['difficulty'] as ChallengeDifficulty,
      startDate: now,
      endDate: now.add(Duration(days: targetDays)),
      targetAmount: (template['targetAmount'] as num?)?.toDouble() ?? 0,
      targetDays: targetDays,
      xpReward: template['xpReward'] as int? ?? 100,
    );
  }

  /// Met à jour un challenge
  static Future<void> updateChallenge(SavingsChallenge challenge) async {
    final challenges = getAllChallenges();
    final index = challenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      challenges[index] = challenge.copyWith(updatedAt: DateTime.now());
      await _saveChallenges(challenges);
    }
  }

  /// Supprime un challenge
  static Future<void> deleteChallenge(String id) async {
    final challenges = getAllChallenges();
    challenges.removeWhere((c) => c.id == id);
    await _saveChallenges(challenges);
  }

  // ============================================================
  // Challenge Progress
  // ============================================================

  /// Met à jour la progression d'un challenge
  static Future<void> updateProgress(
    String challengeId, {
    double? addAmount,
    int? addDays,
  }) async {
    final challenges = getAllChallenges();
    final index = challenges.indexWhere((c) => c.id == challengeId);

    if (index != -1) {
      var challenge = challenges[index];

      if (addAmount != null) {
        challenge = challenge.copyWith(
          currentAmount: challenge.currentAmount + addAmount,
        );
      }

      if (addDays != null) {
        challenge = challenge.copyWith(
          currentDays: challenge.currentDays + addDays,
        );
      }

      // Vérifier si le challenge est complété
      if (challenge.progress >= 1.0) {
        challenge = challenge.copyWith(status: ChallengeStatus.completed);
        await _awardXp(challenge.totalXp);
        await _incrementStreak();
      }

      challenges[index] = challenge.copyWith(updatedAt: DateTime.now());
      await _saveChallenges(challenges);
    }
  }

  /// Vérifie et met à jour les challenges basés sur les dépenses
  static Future<void> checkChallengesWithExpenses(List<Expense> todayExpenses) async {
    final challenges = getAllChallenges();
    bool updated = false;

    for (var i = 0; i < challenges.length; i++) {
      var challenge = challenges[i];
      if (!challenge.isActive) continue;

      switch (challenge.type) {
        case ChallengeType.noSpend:
          // Vérifier si des dépenses dans la catégorie
          final hasSpentInCategory = todayExpenses.any(
            (e) => challenge.categoryId == null || e.categoryId == challenge.categoryId,
          );

          if (!hasSpentInCategory) {
            // Succès pour aujourd'hui
            challenge = challenge.copyWith(
              currentDays: challenge.currentDays + 1,
            );
            updated = true;
          } else if (challenge.rules['strict'] == true) {
            // Échec strict
            challenge = challenge.copyWith(status: ChallengeStatus.failed);
            updated = true;
          }
          break;

        case ChallengeType.spendingLimit:
          final todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
          challenge = challenge.copyWith(currentAmount: todayTotal);

          if (todayTotal > challenge.targetAmount) {
            challenge = challenge.copyWith(status: ChallengeStatus.failed);
          }
          updated = true;
          break;

        case ChallengeType.roundUp:
          // Calculer les arrondis
          double roundUpTotal = 0;
          for (final expense in todayExpenses) {
            final rounded = (expense.amount.ceil()).toDouble();
            roundUpTotal += rounded - expense.amount;
          }
          challenge = challenge.copyWith(
            currentAmount: challenge.currentAmount + roundUpTotal,
          );
          updated = true;
          break;

        case ChallengeType.streak:
          if (todayExpenses.isEmpty) {
            challenge = challenge.copyWith(
              currentDays: challenge.currentDays + 1,
            );
            updated = true;
          }
          break;

        default:
          break;
      }

      // Vérifier si complété
      if (challenge.progress >= 1.0 && challenge.status == ChallengeStatus.active) {
        challenge = challenge.copyWith(status: ChallengeStatus.completed);
        await _awardXp(challenge.totalXp);
        await _incrementStreak();
      }

      // Vérifier si expiré
      if (DateTime.now().isAfter(challenge.endDate) &&
          challenge.status == ChallengeStatus.active) {
        challenge = challenge.copyWith(
          status: challenge.progress >= 1.0
              ? ChallengeStatus.completed
              : ChallengeStatus.failed,
        );
        if (challenge.status == ChallengeStatus.failed) {
          await _resetStreak();
        }
      }

      challenges[i] = challenge.copyWith(updatedAt: DateTime.now());
    }

    if (updated) {
      await _saveChallenges(challenges);
    }
  }

  /// Abandonne un challenge
  static Future<void> abandonChallenge(String id) async {
    final challenges = getAllChallenges();
    final index = challenges.indexWhere((c) => c.id == id);

    if (index != -1) {
      challenges[index] = challenges[index].copyWith(
        status: ChallengeStatus.abandoned,
        updatedAt: DateTime.now(),
      );
      await _saveChallenges(challenges);
      await _resetStreak();
    }
  }

  // ============================================================
  // XP & Level System
  // ============================================================

  /// Récupère le XP total de l'utilisateur
  static int getTotalXp() {
    return LocalStorageService.getInt(_xpKey) ?? 0;
  }

  /// Récupère le niveau actuel
  static int getLevel() {
    final xp = getTotalXp();
    return _calculateLevel(xp);
  }

  /// Calcule le niveau basé sur le XP
  static int _calculateLevel(int xp) {
    // Formule: niveau = sqrt(xp / 100)
    // Niveau 1: 0-99 XP
    // Niveau 2: 100-399 XP
    // Niveau 3: 400-899 XP
    // etc.
    if (xp < 100) return 1;
    return (xp / 100).sqrt().floor() + 1;
  }

  /// XP nécessaire pour le niveau suivant
  static int xpForNextLevel() {
    final currentLevel = getLevel();
    return (currentLevel * currentLevel) * 100;
  }

  /// XP actuel dans le niveau
  static int xpInCurrentLevel() {
    final xp = getTotalXp();
    final currentLevel = getLevel();
    final previousLevelXp = currentLevel > 1 ? ((currentLevel - 1) * (currentLevel - 1)) * 100 : 0;
    return xp - previousLevelXp;
  }

  /// Progression dans le niveau actuel (0.0 à 1.0)
  static double levelProgress() {
    final currentXp = xpInCurrentLevel();
    final neededXp = xpForNextLevel() - ((getLevel() - 1) * (getLevel() - 1) * 100);
    return (currentXp / neededXp).clamp(0.0, 1.0);
  }

  /// Ajoute du XP
  static Future<int> _awardXp(int amount) async {
    final currentXp = getTotalXp();
    final newXp = currentXp + amount;
    await LocalStorageService.setInt(_xpKey, newXp);

    final oldLevel = _calculateLevel(currentXp);
    final newLevel = _calculateLevel(newXp);

    // Retourne le nombre de niveaux gagnés
    return newLevel - oldLevel;
  }

  // ============================================================
  // Streak System
  // ============================================================

  /// Récupère la série actuelle
  static int getStreak() {
    return LocalStorageService.getInt(_streakKey) ?? 0;
  }

  /// Incrémente la série
  static Future<void> _incrementStreak() async {
    final current = getStreak();
    await LocalStorageService.setInt(_streakKey, current + 1);
  }

  /// Réinitialise la série
  static Future<void> _resetStreak() async {
    await LocalStorageService.setInt(_streakKey, 0);
  }

  // ============================================================
  // Queries
  // ============================================================

  /// Récupère les challenges actifs
  static List<SavingsChallenge> getActiveChallenges() {
    return getAllChallenges()
        .where((c) => c.status == ChallengeStatus.active)
        .toList();
  }

  /// Récupère les challenges complétés
  static List<SavingsChallenge> getCompletedChallenges() {
    return getAllChallenges()
        .where((c) => c.status == ChallengeStatus.completed)
        .toList();
  }

  /// Récupère les statistiques
  static Map<String, dynamic> getStats() {
    final all = getAllChallenges();
    final completed = all.where((c) => c.status == ChallengeStatus.completed).length;
    final failed = all.where((c) => c.status == ChallengeStatus.failed).length;
    final active = all.where((c) => c.status == ChallengeStatus.active).length;

    return {
      'total': all.length,
      'completed': completed,
      'failed': failed,
      'active': active,
      'successRate': all.isNotEmpty ? (completed / (completed + failed) * 100).round() : 0,
      'totalXp': getTotalXp(),
      'level': getLevel(),
      'streak': getStreak(),
    };
  }
}

extension on double {
  double sqrt() => this <= 0 ? 0 : this.toDouble().sqrtDouble();
  double sqrtDouble() {
    if (this <= 0) return 0;
    double x = this;
    double y = 1;
    while (x - y > 0.0001) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
