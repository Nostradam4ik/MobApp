import 'package:equatable/equatable.dart';

/// Modèle d'objectif financier
class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final String color;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.icon = 'savings',
    this.color = '#10B981',
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un Goal depuis un JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? 'savings',
      color: json['color'] as String? ?? '#10B981',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'icon': icon,
      'color': color,
      'deadline': deadline?.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    String? color,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Montant restant à atteindre
  double get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);

  /// Pourcentage de progression
  double get progress => (currentAmount / targetAmount * 100).clamp(0, 100);

  /// Vérifie si l'objectif est atteint
  bool get isReached => currentAmount >= targetAmount;

  /// Vérifie si la deadline est dépassée
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Jours restants jusqu'à la deadline
  int? get daysRemaining {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  /// Montant quotidien conseillé pour atteindre l'objectif
  double? get dailyTargetAmount {
    if (deadline == null || isReached) return null;
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    return remaining / days;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetAmount,
        currentAmount,
        icon,
        color,
        deadline,
        isCompleted,
        completedAt,
        createdAt,
        updatedAt,
      ];
}

/// Modèle de contribution à un objectif
class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final String? note;
  final DateTime contributionDate;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    this.note,
    required this.contributionDate,
    required this.createdAt,
  });

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      contributionDate: DateTime.parse(json['contribution_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'note': note,
      'contribution_date': contributionDate.toIso8601String().split('T')[0],
    };
  }

  @override
  List<Object?> get props => [
        id,
        goalId,
        userId,
        amount,
        note,
        contributionDate,
        createdAt,
      ];
}
