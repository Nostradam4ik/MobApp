import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'category.dart';

/// Modèle d'achievement (badge)
class Achievement extends Equatable {
  final String id;
  final String userId;
  final String achievementType;
  final String title;
  final String? description;
  final String icon;
  final int points;
  final DateTime earnedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.achievementType,
    required this.title,
    this.description,
    this.icon = 'trophy',
    this.points = 0,
    required this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementType: json['achievement_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'trophy',
      points: json['points'] as int? ?? 0,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_type': achievementType,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  IconData get iconData => Category.getIconData(icon);

  @override
  List<Object?> get props => [
        id,
        userId,
        achievementType,
        title,
        description,
        icon,
        points,
        earnedAt,
      ];
}

/// Type d'achievement disponible
class AchievementType extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final int? requirementValue;
  final String category;

  const AchievementType({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.points = 0,
    this.requirementValue,
    required this.category,
  });

  factory AchievementType.fromJson(Map<String, dynamic> json) {
    return AchievementType(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      points: json['points'] as int? ?? 0,
      requirementValue: json['requirement_value'] as int?,
      category: json['category'] as String,
    );
  }

  IconData get iconData => Category.getIconData(icon);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        points,
        requirementValue,
        category,
      ];
}

/// Modèle de streak
class Streak extends Equatable {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final String streakType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Streak({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.streakType = 'daily_tracking',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'] as String)
          : null,
      streakType: json['streak_type'] as String? ?? 'daily_tracking',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate?.toIso8601String().split('T')[0],
      'streak_type': streakType,
    };
  }

  /// Vérifie si le streak est actif aujourd'hui
  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    return lastActivityDate!.year == now.year &&
        lastActivityDate!.month == now.month &&
        lastActivityDate!.day == now.day;
  }

  /// Vérifie si le streak peut être continué (activité hier)
  bool get canContinue {
    if (lastActivityDate == null) return true;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastActivityDate!.year == yesterday.year &&
        lastActivityDate!.month == yesterday.month &&
        lastActivityDate!.day == yesterday.day;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        currentStreak,
        longestStreak,
        lastActivityDate,
        streakType,
        createdAt,
        updatedAt,
      ];
}
