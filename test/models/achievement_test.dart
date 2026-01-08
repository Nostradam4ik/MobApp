import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/achievement.dart';

void main() {
  group('Achievement', () {
    final now = DateTime.now();
    final testAchievement = Achievement(
      id: 'ach-123',
      userId: 'user-456',
      achievementType: 'first_expense',
      title: 'Première dépense',
      description: 'Vous avez enregistré votre première dépense',
      icon: 'trophy',
      points: 100,
      earnedAt: now,
    );

    group('fromJson', () {
      test('should create Achievement from valid JSON', () {
        final json = {
          'id': 'ach-123',
          'user_id': 'user-456',
          'achievement_type': 'first_expense',
          'title': 'Première dépense',
          'description': 'Description test',
          'icon': 'star',
          'points': 50,
          'earned_at': '2024-01-15T10:00:00.000Z',
        };

        final achievement = Achievement.fromJson(json);

        expect(achievement.id, 'ach-123');
        expect(achievement.userId, 'user-456');
        expect(achievement.achievementType, 'first_expense');
        expect(achievement.title, 'Première dépense');
        expect(achievement.description, 'Description test');
        expect(achievement.icon, 'star');
        expect(achievement.points, 50);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'ach-123',
          'user_id': 'user-456',
          'achievement_type': 'test',
          'title': 'Test',
          'earned_at': '2024-01-15T10:00:00.000Z',
        };

        final achievement = Achievement.fromJson(json);

        expect(achievement.description, isNull);
        expect(achievement.icon, 'trophy');
        expect(achievement.points, 0);
      });
    });

    group('toJson', () {
      test('should convert Achievement to JSON', () {
        final json = testAchievement.toJson();

        expect(json['id'], 'ach-123');
        expect(json['user_id'], 'user-456');
        expect(json['achievement_type'], 'first_expense');
        expect(json['title'], 'Première dépense');
        expect(json['description'], isNotNull);
        expect(json['icon'], 'trophy');
        expect(json['points'], 100);
        expect(json['earned_at'], isA<String>());
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final ach1 = Achievement(
          id: 'ach-1',
          userId: 'user-1',
          achievementType: 'test',
          title: 'Test',
          earnedAt: now,
        );

        final ach2 = Achievement(
          id: 'ach-1',
          userId: 'user-1',
          achievementType: 'test',
          title: 'Test',
          earnedAt: now,
        );

        expect(ach1, equals(ach2));
      });
    });
  });

  group('AchievementType', () {
    group('fromJson', () {
      test('should create AchievementType from JSON', () {
        final json = {
          'id': 'type-123',
          'title': 'Premier pas',
          'description': 'Ajoutez votre première dépense',
          'icon': 'star',
          'points': 50,
          'requirement_value': 1,
          'category': 'beginner',
        };

        final type = AchievementType.fromJson(json);

        expect(type.id, 'type-123');
        expect(type.title, 'Premier pas');
        expect(type.description, 'Ajoutez votre première dépense');
        expect(type.icon, 'star');
        expect(type.points, 50);
        expect(type.requirementValue, 1);
        expect(type.category, 'beginner');
      });

      test('should handle null requirementValue', () {
        final json = {
          'id': 'type-1',
          'title': 'Test',
          'description': 'Test',
          'icon': 'star',
          'category': 'test',
        };

        final type = AchievementType.fromJson(json);

        expect(type.requirementValue, isNull);
        expect(type.points, 0);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        const type1 = AchievementType(
          id: 'type-1',
          title: 'Test',
          description: 'Desc',
          icon: 'star',
          category: 'cat',
        );

        const type2 = AchievementType(
          id: 'type-1',
          title: 'Test',
          description: 'Desc',
          icon: 'star',
          category: 'cat',
        );

        expect(type1, equals(type2));
      });
    });
  });

  group('Streak', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final testStreak = Streak(
      id: 'streak-123',
      userId: 'user-456',
      currentStreak: 5,
      longestStreak: 10,
      lastActivityDate: today,
      streakType: 'daily_tracking',
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create Streak from valid JSON', () {
        final json = {
          'id': 'streak-123',
          'user_id': 'user-456',
          'current_streak': 5,
          'longest_streak': 10,
          'last_activity_date': '2024-01-15',
          'streak_type': 'daily_tracking',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final streak = Streak.fromJson(json);

        expect(streak.id, 'streak-123');
        expect(streak.userId, 'user-456');
        expect(streak.currentStreak, 5);
        expect(streak.longestStreak, 10);
        expect(streak.streakType, 'daily_tracking');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'streak-123',
          'user_id': 'user-456',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final streak = Streak.fromJson(json);

        expect(streak.currentStreak, 0);
        expect(streak.longestStreak, 0);
        expect(streak.lastActivityDate, isNull);
        expect(streak.streakType, 'daily_tracking');
      });
    });

    group('toJson', () {
      test('should convert Streak to JSON', () {
        final json = testStreak.toJson();

        expect(json['id'], 'streak-123');
        expect(json['user_id'], 'user-456');
        expect(json['current_streak'], 5);
        expect(json['longest_streak'], 10);
        expect(json['streak_type'], 'daily_tracking');
        expect(json['last_activity_date'], isA<String>());
      });

      test('should handle null lastActivityDate', () {
        final noActivity = Streak(
          id: 'streak-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final json = noActivity.toJson();
        expect(json['last_activity_date'], isNull);
      });
    });

    group('isActiveToday', () {
      test('should return true when last activity is today', () {
        expect(testStreak.isActiveToday, true);
      });

      test('should return false when last activity is yesterday', () {
        final yesterdayStreak = Streak(
          id: 'streak-1',
          userId: 'user-1',
          lastActivityDate: yesterday,
          createdAt: now,
          updatedAt: now,
        );

        expect(yesterdayStreak.isActiveToday, false);
      });

      test('should return false when no activity', () {
        final noActivity = Streak(
          id: 'streak-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(noActivity.isActiveToday, false);
      });
    });

    group('canContinue', () {
      test('should return true when no previous activity', () {
        final noActivity = Streak(
          id: 'streak-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(noActivity.canContinue, true);
      });

      test('should return true when last activity was yesterday', () {
        final yesterdayStreak = Streak(
          id: 'streak-1',
          userId: 'user-1',
          lastActivityDate: yesterday,
          createdAt: now,
          updatedAt: now,
        );

        expect(yesterdayStreak.canContinue, true);
      });

      test('should return false when last activity was today', () {
        // Activity today means canContinue should be false (already active today)
        expect(testStreak.canContinue, false);
      });

      test('should return false when last activity was 2+ days ago', () {
        final oldStreak = Streak(
          id: 'streak-1',
          userId: 'user-1',
          lastActivityDate: today.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
        );

        expect(oldStreak.canContinue, false);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final streak1 = Streak(
          id: 'streak-1',
          userId: 'user-1',
          currentStreak: 5,
          longestStreak: 10,
          createdAt: now,
          updatedAt: now,
        );

        final streak2 = Streak(
          id: 'streak-1',
          userId: 'user-1',
          currentStreak: 5,
          longestStreak: 10,
          createdAt: now,
          updatedAt: now,
        );

        expect(streak1, equals(streak2));
      });
    });
  });
}
