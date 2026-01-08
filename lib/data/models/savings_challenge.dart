import 'package:equatable/equatable.dart';

/// Type de challenge
enum ChallengeType {
  noSpend,        // Pas de dépense dans une catégorie
  savingsTarget,  // Objectif d'épargne
  spendingLimit,  // Limite de dépense
  streak,         // Série de jours sans dépense
  weekly52,       // Challenge 52 semaines
  roundUp,        // Arrondir et épargner
  custom;         // Personnalisé

  String get label {
    switch (this) {
      case ChallengeType.noSpend:
        return 'Sans dépense';
      case ChallengeType.savingsTarget:
        return 'Objectif épargne';
      case ChallengeType.spendingLimit:
        return 'Limite dépense';
      case ChallengeType.streak:
        return 'Série';
      case ChallengeType.weekly52:
        return '52 semaines';
      case ChallengeType.roundUp:
        return 'Arrondi';
      case ChallengeType.custom:
        return 'Personnalisé';
    }
  }

  String get icon {
    switch (this) {
      case ChallengeType.noSpend:
        return '🚫';
      case ChallengeType.savingsTarget:
        return '🎯';
      case ChallengeType.spendingLimit:
        return '💵';
      case ChallengeType.streak:
        return '🔥';
      case ChallengeType.weekly52:
        return '📅';
      case ChallengeType.roundUp:
        return '🔄';
      case ChallengeType.custom:
        return '⭐';
    }
  }

  String get description {
    switch (this) {
      case ChallengeType.noSpend:
        return 'Évitez de dépenser dans une catégorie pendant X jours';
      case ChallengeType.savingsTarget:
        return 'Épargnez un montant spécifique';
      case ChallengeType.spendingLimit:
        return 'Ne dépassez pas un budget quotidien/hebdo';
      case ChallengeType.streak:
        return 'Enchaînez X jours sans dépenses superflues';
      case ChallengeType.weekly52:
        return 'Épargnez chaque semaine (1€, 2€, 3€...)';
      case ChallengeType.roundUp:
        return 'Arrondissez chaque dépense et épargnez la différence';
      case ChallengeType.custom:
        return 'Créez votre propre défi';
    }
  }
}

/// Difficulté du challenge
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  extreme;

  String get label {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'Facile';
      case ChallengeDifficulty.medium:
        return 'Moyen';
      case ChallengeDifficulty.hard:
        return 'Difficile';
      case ChallengeDifficulty.extreme:
        return 'Extrême';
    }
  }

  String get emoji {
    switch (this) {
      case ChallengeDifficulty.easy:
        return '🌱';
      case ChallengeDifficulty.medium:
        return '🌿';
      case ChallengeDifficulty.hard:
        return '🌳';
      case ChallengeDifficulty.extreme:
        return '🔥';
    }
  }

  int get xpMultiplier {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 1;
      case ChallengeDifficulty.medium:
        return 2;
      case ChallengeDifficulty.hard:
        return 3;
      case ChallengeDifficulty.extreme:
        return 5;
    }
  }
}

/// Statut du challenge
enum ChallengeStatus {
  notStarted,
  active,
  completed,
  failed,
  abandoned;

  String get label {
    switch (this) {
      case ChallengeStatus.notStarted:
        return 'Non commencé';
      case ChallengeStatus.active:
        return 'En cours';
      case ChallengeStatus.completed:
        return 'Terminé';
      case ChallengeStatus.failed:
        return 'Échoué';
      case ChallengeStatus.abandoned:
        return 'Abandonné';
    }
  }
}

/// Modèle de challenge d'épargne
class SavingsChallenge extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double targetAmount;
  final double currentAmount;
  final String? categoryId; // Pour les challenges par catégorie
  final int targetDays;
  final int currentDays;
  final int xpReward;
  final List<String> badges;
  final Map<String, dynamic> rules;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsChallenge({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.targetAmount = 0,
    this.currentAmount = 0,
    this.categoryId,
    this.targetDays = 0,
    this.currentDays = 0,
    this.xpReward = 100,
    this.badges = const [],
    this.rules = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progression (0.0 à 1.0)
  double get progress {
    if (type == ChallengeType.streak || type == ChallengeType.noSpend) {
      if (targetDays == 0) return 0;
      return (currentDays / targetDays).clamp(0.0, 1.0);
    }
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Pourcentage de progression
  int get progressPercent => (progress * 100).round();

  /// Jours restants
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Jours écoulés depuis le début
  int get daysElapsed {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    return now.difference(startDate).inDays;
  }

  /// Est-ce que le challenge est actif ?
  bool get isActive => status == ChallengeStatus.active;

  /// Est-ce que le challenge est terminé avec succès ?
  bool get isCompleted => status == ChallengeStatus.completed;

  /// Est-ce que le challenge est en retard ?
  bool get isBehindSchedule {
    if (!isActive) return false;
    final expectedProgress = daysElapsed / (targetDays > 0 ? targetDays : 1);
    return progress < expectedProgress - 0.1;
  }

  /// XP total (avec multiplicateur de difficulté)
  int get totalXp => xpReward * difficulty.xpMultiplier;

  /// Montant restant à épargner
  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  SavingsChallenge copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? targetAmount,
    double? currentAmount,
    String? categoryId,
    int? targetDays,
    int? currentDays,
    int? xpReward,
    List<String>? badges,
    Map<String, dynamic>? rules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      categoryId: categoryId ?? this.categoryId,
      targetDays: targetDays ?? this.targetDays,
      currentDays: currentDays ?? this.currentDays,
      xpReward: xpReward ?? this.xpReward,
      badges: badges ?? this.badges,
      rules: rules ?? this.rules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'category_id': categoryId,
      'target_days': targetDays,
      'current_days': currentDays,
      'xp_reward': xpReward,
      'badges': badges,
      'rules': rules,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SavingsChallenge.fromJson(Map<String, dynamic> json) {
    return SavingsChallenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.custom,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ChallengeDifficulty.medium,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.notStarted,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      categoryId: json['category_id'] as String?,
      targetDays: json['target_days'] as int? ?? 0,
      currentDays: json['current_days'] as int? ?? 0,
      xpReward: json['xp_reward'] as int? ?? 100,
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
      rules: json['rules'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, status, currentAmount, currentDays];
}

/// Templates de challenges prédéfinis
class ChallengeTemplates {
  static List<Map<String, dynamic>> get templates => [
    {
      'title': 'Semaine sans resto',
      'description': 'Évitez les restaurants pendant 7 jours',
      'type': ChallengeType.noSpend,
      'difficulty': ChallengeDifficulty.medium,
      'targetDays': 7,
      'categoryName': 'Restaurant',
      'xpReward': 150,
    },
    {
      'title': 'Défi 52 semaines',
      'description': 'Épargnez 1€ semaine 1, 2€ semaine 2, etc.',
      'type': ChallengeType.weekly52,
      'difficulty': ChallengeDifficulty.hard,
      'targetDays': 365,
      'targetAmount': 1378, // 1+2+3+...+52
      'xpReward': 500,
    },
    {
      'title': 'Mois sans achats impulsifs',
      'description': 'Aucun achat non planifié pendant 30 jours',
      'type': ChallengeType.streak,
      'difficulty': ChallengeDifficulty.hard,
      'targetDays': 30,
      'xpReward': 300,
    },
    {
      'title': 'Budget café',
      'description': 'Maximum 20€ en café ce mois',
      'type': ChallengeType.spendingLimit,
      'difficulty': ChallengeDifficulty.easy,
      'targetDays': 30,
      'targetAmount': 20,
      'xpReward': 100,
    },
    {
      'title': 'Arrondi épargne',
      'description': 'Arrondissez chaque dépense et épargnez',
      'type': ChallengeType.roundUp,
      'difficulty': ChallengeDifficulty.easy,
      'targetDays': 30,
      'xpReward': 120,
    },
    {
      'title': 'Semaine minimaliste',
      'description': 'Dépensez moins de 50€ cette semaine',
      'type': ChallengeType.spendingLimit,
      'difficulty': ChallengeDifficulty.extreme,
      'targetDays': 7,
      'targetAmount': 50,
      'xpReward': 250,
    },
    {
      'title': 'Épargne express',
      'description': 'Épargnez 100€ en 2 semaines',
      'type': ChallengeType.savingsTarget,
      'difficulty': ChallengeDifficulty.medium,
      'targetDays': 14,
      'targetAmount': 100,
      'xpReward': 200,
    },
    {
      'title': 'Weekend gratuit',
      'description': 'Passez un weekend sans dépenser',
      'type': ChallengeType.noSpend,
      'difficulty': ChallengeDifficulty.easy,
      'targetDays': 2,
      'xpReward': 80,
    },
  ];
}
