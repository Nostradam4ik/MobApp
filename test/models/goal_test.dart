import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/goal.dart';

void main() {
  group('Goal', () {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 30));
    final pastDate = now.subtract(const Duration(days: 10));

    final testGoal = Goal(
      id: 'goal-123',
      userId: 'user-456',
      title: 'Vacances',
      description: 'Voyage en Espagne',
      targetAmount: 1000.0,
      currentAmount: 400.0,
      icon: 'flight',
      color: '#10B981',
      deadline: futureDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create Goal from valid JSON', () {
        final json = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'title': 'Vacances',
          'description': 'Voyage en Espagne',
          'target_amount': 1000.0,
          'current_amount': 400.0,
          'icon': 'flight',
          'color': '#10B981',
          'deadline': '2024-12-31',
          'is_completed': false,
          'completed_at': null,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final goal = Goal.fromJson(json);

        expect(goal.id, 'goal-123');
        expect(goal.userId, 'user-456');
        expect(goal.title, 'Vacances');
        expect(goal.description, 'Voyage en Espagne');
        expect(goal.targetAmount, 1000.0);
        expect(goal.currentAmount, 400.0);
        expect(goal.icon, 'flight');
        expect(goal.color, '#10B981');
        expect(goal.isCompleted, false);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'title': 'Objectif simple',
          'target_amount': 500.0,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final goal = Goal.fromJson(json);

        expect(goal.description, isNull);
        expect(goal.deadline, isNull);
        expect(goal.completedAt, isNull);
        expect(goal.currentAmount, 0.0);
        expect(goal.icon, 'savings');
        expect(goal.color, '#10B981');
        expect(goal.isCompleted, false);
      });

      test('should handle integer amounts', () {
        final json = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'title': 'Test',
          'target_amount': 1000,
          'current_amount': 500,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final goal = Goal.fromJson(json);

        expect(goal.targetAmount, 1000.0);
        expect(goal.currentAmount, 500.0);
        expect(goal.targetAmount, isA<double>());
      });

      test('should parse completed goal with completedAt', () {
        final json = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'title': 'Objectif atteint',
          'target_amount': 1000.0,
          'current_amount': 1000.0,
          'is_completed': true,
          'completed_at': '2024-06-15T10:00:00.000Z',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-06-15T10:00:00.000Z',
        };

        final goal = Goal.fromJson(json);

        expect(goal.isCompleted, true);
        expect(goal.completedAt, isNotNull);
        expect(goal.completedAt!.month, 6);
      });
    });

    group('toJson', () {
      test('should convert Goal to JSON', () {
        final json = testGoal.toJson();

        expect(json['id'], 'goal-123');
        expect(json['user_id'], 'user-456');
        expect(json['title'], 'Vacances');
        expect(json['description'], 'Voyage en Espagne');
        expect(json['target_amount'], 1000.0);
        expect(json['current_amount'], 400.0);
        expect(json['icon'], 'flight');
        expect(json['color'], '#10B981');
        expect(json['is_completed'], false);
      });

      test('should format deadline as date only', () {
        final json = testGoal.toJson();

        expect(json['deadline'], isNotNull);
        expect(json['deadline'], isNot(contains('T')));
      });

      test('should handle null deadline', () {
        final goalWithoutDeadline = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'No Deadline',
          targetAmount: 500.0,
          createdAt: now,
          updatedAt: now,
        );

        final json = goalWithoutDeadline.toJson();

        expect(json['deadline'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated currentAmount', () {
        final copy = testGoal.copyWith(currentAmount: 600.0);

        expect(copy.currentAmount, 600.0);
        expect(copy.id, testGoal.id);
        expect(copy.targetAmount, testGoal.targetAmount);
      });

      test('should create copy marking as completed', () {
        final completed = testGoal.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          currentAmount: 1000.0,
        );

        expect(completed.isCompleted, true);
        expect(completed.completedAt, isNotNull);
        expect(completed.currentAmount, 1000.0);
      });

      test('should create copy with multiple updates', () {
        final copy = testGoal.copyWith(
          title: 'Nouveau titre',
          targetAmount: 2000.0,
          color: '#FF5722',
        );

        expect(copy.title, 'Nouveau titre');
        expect(copy.targetAmount, 2000.0);
        expect(copy.color, '#FF5722');
        expect(copy.id, testGoal.id);
      });
    });

    group('remaining', () {
      test('should calculate remaining amount correctly', () {
        expect(testGoal.remaining, 600.0); // 1000 - 400
      });

      test('should return 0 when goal is reached', () {
        final reachedGoal = testGoal.copyWith(currentAmount: 1200.0);
        expect(reachedGoal.remaining, 0.0);
      });

      test('should return target when nothing saved', () {
        final noSavings = testGoal.copyWith(currentAmount: 0.0);
        expect(noSavings.remaining, 1000.0);
      });

      test('should clamp to non-negative', () {
        final overGoal = testGoal.copyWith(currentAmount: 1500.0);
        expect(overGoal.remaining, 0.0);
      });
    });

    group('progress', () {
      test('should calculate progress correctly', () {
        expect(testGoal.progress, 40.0); // 400/1000 * 100
      });

      test('should clamp to 100 when over target', () {
        final overGoal = testGoal.copyWith(currentAmount: 1500.0);
        expect(overGoal.progress, 100.0);
      });

      test('should be 0 when nothing saved', () {
        final noSavings = testGoal.copyWith(currentAmount: 0.0);
        expect(noSavings.progress, 0.0);
      });

      test('should be 100 when exactly at target', () {
        final exactGoal = testGoal.copyWith(currentAmount: 1000.0);
        expect(exactGoal.progress, 100.0);
      });
    });

    group('isReached', () {
      test('should return false when under target', () {
        expect(testGoal.isReached, false);
      });

      test('should return true when at target', () {
        final atTarget = testGoal.copyWith(currentAmount: 1000.0);
        expect(atTarget.isReached, true);
      });

      test('should return true when over target', () {
        final overTarget = testGoal.copyWith(currentAmount: 1200.0);
        expect(overTarget.isReached, true);
      });
    });

    group('isOverdue', () {
      test('should return false when deadline is in future', () {
        expect(testGoal.isOverdue, false);
      });

      test('should return true when deadline has passed', () {
        final overdueGoal = testGoal.copyWith(deadline: pastDate);
        expect(overdueGoal.isOverdue, true);
      });

      test('should return false when no deadline', () {
        final noDeadline = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'No Deadline',
          targetAmount: 1000.0,
          createdAt: now,
          updatedAt: now,
        );
        expect(noDeadline.isOverdue, false);
      });

      test('should return false when completed even if past deadline', () {
        final completedPastDeadline = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'Completed',
          targetAmount: 1000.0,
          currentAmount: 1000.0,
          deadline: pastDate,
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
        );
        expect(completedPastDeadline.isOverdue, false);
      });
    });

    group('daysRemaining', () {
      test('should return null when no deadline', () {
        final noDeadline = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'No Deadline',
          targetAmount: 1000.0,
          createdAt: now,
          updatedAt: now,
        );
        expect(noDeadline.daysRemaining, isNull);
      });

      test('should return positive days for future deadline', () {
        // Deadline is 30 days in future
        expect(testGoal.daysRemaining, greaterThanOrEqualTo(29));
        expect(testGoal.daysRemaining, lessThanOrEqualTo(30));
      });

      test('should return negative days for past deadline', () {
        final overdueGoal = testGoal.copyWith(deadline: pastDate);
        expect(overdueGoal.daysRemaining, lessThan(0));
      });
    });

    group('dailyTargetAmount', () {
      test('should calculate daily amount correctly', () {
        // 600 remaining / 30 days = 20 per day
        final daily = testGoal.dailyTargetAmount;
        expect(daily, isNotNull);
        expect(daily!, closeTo(20.0, 1.0));
      });

      test('should return null when no deadline', () {
        final noDeadline = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'No Deadline',
          targetAmount: 1000.0,
          currentAmount: 400.0,
          createdAt: now,
          updatedAt: now,
        );
        expect(noDeadline.dailyTargetAmount, isNull);
      });

      test('should return null when goal is reached', () {
        final reachedGoal = testGoal.copyWith(currentAmount: 1000.0);
        expect(reachedGoal.dailyTargetAmount, isNull);
      });

      test('should return null when deadline has passed', () {
        final overdueGoal = testGoal.copyWith(deadline: pastDate);
        expect(overdueGoal.dailyTargetAmount, isNull);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final goal1 = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'Test',
          targetAmount: 1000.0,
          currentAmount: 500.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final goal2 = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'Test',
          targetAmount: 1000.0,
          currentAmount: 500.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(goal1, equals(goal2));
      });

      test('should not be equal for different amounts', () {
        final goal1 = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'Test',
          targetAmount: 1000.0,
          currentAmount: 500.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final goal2 = Goal(
          id: 'goal-1',
          userId: 'user-1',
          title: 'Test',
          targetAmount: 1000.0,
          currentAmount: 600.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(goal1, isNot(equals(goal2)));
      });
    });
  });

  group('GoalContribution', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('should create GoalContribution from valid JSON', () {
        final json = {
          'id': 'contrib-123',
          'goal_id': 'goal-456',
          'user_id': 'user-789',
          'amount': 100.0,
          'note': 'Weekly contribution',
          'contribution_date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final contribution = GoalContribution.fromJson(json);

        expect(contribution.id, 'contrib-123');
        expect(contribution.goalId, 'goal-456');
        expect(contribution.userId, 'user-789');
        expect(contribution.amount, 100.0);
        expect(contribution.note, 'Weekly contribution');
      });

      test('should handle null note', () {
        final json = {
          'id': 'contrib-123',
          'goal_id': 'goal-456',
          'user_id': 'user-789',
          'amount': 50.0,
          'contribution_date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final contribution = GoalContribution.fromJson(json);

        expect(contribution.note, isNull);
      });

      test('should handle integer amount', () {
        final json = {
          'id': 'contrib-123',
          'goal_id': 'goal-456',
          'user_id': 'user-789',
          'amount': 100,
          'contribution_date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final contribution = GoalContribution.fromJson(json);

        expect(contribution.amount, 100.0);
        expect(contribution.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('should convert GoalContribution to JSON', () {
        final contribution = GoalContribution(
          id: 'contrib-123',
          goalId: 'goal-456',
          userId: 'user-789',
          amount: 100.0,
          note: 'Test note',
          contributionDate: DateTime(2024, 1, 15),
          createdAt: now,
        );

        final json = contribution.toJson();

        expect(json['id'], 'contrib-123');
        expect(json['goal_id'], 'goal-456');
        expect(json['user_id'], 'user-789');
        expect(json['amount'], 100.0);
        expect(json['note'], 'Test note');
        expect(json['contribution_date'], '2024-01-15');
      });

      test('should format contribution_date as date only', () {
        final contribution = GoalContribution(
          id: 'contrib-1',
          goalId: 'goal-1',
          userId: 'user-1',
          amount: 50.0,
          contributionDate: DateTime(2024, 6, 20, 14, 30, 0),
          createdAt: now,
        );

        final json = contribution.toJson();

        expect(json['contribution_date'], '2024-06-20');
        expect(json['contribution_date'], isNot(contains('T')));
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final contrib1 = GoalContribution(
          id: 'contrib-1',
          goalId: 'goal-1',
          userId: 'user-1',
          amount: 100.0,
          note: 'Test',
          contributionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final contrib2 = GoalContribution(
          id: 'contrib-1',
          goalId: 'goal-1',
          userId: 'user-1',
          amount: 100.0,
          note: 'Test',
          contributionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        expect(contrib1, equals(contrib2));
      });

      test('should not be equal for different amounts', () {
        final contrib1 = GoalContribution(
          id: 'contrib-1',
          goalId: 'goal-1',
          userId: 'user-1',
          amount: 100.0,
          contributionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final contrib2 = GoalContribution(
          id: 'contrib-1',
          goalId: 'goal-1',
          userId: 'user-1',
          amount: 200.0,
          contributionDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        expect(contrib1, isNot(equals(contrib2)));
      });
    });
  });
}
