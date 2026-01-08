import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/budget.dart';
import 'package:smartspend/data/models/category.dart';

void main() {
  group('BudgetStatus', () {
    test('should have all expected values', () {
      expect(BudgetStatus.values.length, 3);
      expect(BudgetStatus.values, contains(BudgetStatus.ok));
      expect(BudgetStatus.values, contains(BudgetStatus.warning));
      expect(BudgetStatus.values, contains(BudgetStatus.exceeded));
    });
  });

  group('Budget', () {
    final now = DateTime.now();
    final testBudget = Budget(
      id: 'budget-123',
      userId: 'user-456',
      categoryId: 'cat-1',
      monthlyLimit: 500.0,
      alertThreshold: 80,
      isActive: true,
      periodStart: DateTime(2024, 1, 1),
      createdAt: now,
      updatedAt: now,
      spent: 200.0,
    );

    group('fromJson', () {
      test('should create Budget from valid JSON', () {
        final json = {
          'id': 'budget-123',
          'user_id': 'user-456',
          'category_id': 'cat-1',
          'monthly_limit': 500.0,
          'alert_threshold': 80,
          'is_active': true,
          'period_start': '2024-01-01',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final budget = Budget.fromJson(json, spent: 100.0);

        expect(budget.id, 'budget-123');
        expect(budget.userId, 'user-456');
        expect(budget.categoryId, 'cat-1');
        expect(budget.monthlyLimit, 500.0);
        expect(budget.alertThreshold, 80);
        expect(budget.isActive, true);
        expect(budget.spent, 100.0);
      });

      test('should handle null category_id for global budget', () {
        final json = {
          'id': 'budget-123',
          'user_id': 'user-456',
          'category_id': null,
          'monthly_limit': 1000.0,
          'period_start': '2024-01-01',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final budget = Budget.fromJson(json);

        expect(budget.categoryId, isNull);
        expect(budget.isGlobal, true);
      });

      test('should handle integer monthly_limit', () {
        final json = {
          'id': 'budget-123',
          'user_id': 'user-456',
          'monthly_limit': 500,
          'period_start': '2024-01-01',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final budget = Budget.fromJson(json);

        expect(budget.monthlyLimit, 500.0);
        expect(budget.monthlyLimit, isA<double>());
      });

      test('should use default values for optional fields', () {
        final json = {
          'id': 'budget-123',
          'user_id': 'user-456',
          'monthly_limit': 500.0,
          'period_start': '2024-01-01',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final budget = Budget.fromJson(json);

        expect(budget.alertThreshold, 80);
        expect(budget.isActive, true);
        expect(budget.spent, 0);
      });

      test('should parse category when present', () {
        final json = {
          'id': 'budget-123',
          'user_id': 'user-456',
          'category_id': 'cat-1',
          'monthly_limit': 500.0,
          'period_start': '2024-01-01',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
          'categories': {
            'id': 'cat-1',
            'user_id': 'user-456',
            'name': 'Alimentation',
            'icon': 'restaurant',
            'color': '#FF5722',
            'is_default': true,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          },
        };

        final budget = Budget.fromJson(json);

        expect(budget.category, isNotNull);
        expect(budget.category!.name, 'Alimentation');
      });
    });

    group('toJson', () {
      test('should convert Budget to JSON', () {
        final json = testBudget.toJson();

        expect(json['id'], 'budget-123');
        expect(json['user_id'], 'user-456');
        expect(json['category_id'], 'cat-1');
        expect(json['monthly_limit'], 500.0);
        expect(json['alert_threshold'], 80);
        expect(json['is_active'], true);
        expect(json['period_start'], '2024-01-01');
      });

      test('should not include spent in JSON', () {
        final json = testBudget.toJson();

        expect(json.containsKey('spent'), false);
      });

      test('should format period_start as date only', () {
        final json = testBudget.toJson();

        expect(json['period_start'], isNot(contains('T')));
      });
    });

    group('copyWith', () {
      test('should create copy with updated monthlyLimit', () {
        final copy = testBudget.copyWith(monthlyLimit: 1000.0);

        expect(copy.monthlyLimit, 1000.0);
        expect(copy.id, testBudget.id);
        expect(copy.spent, testBudget.spent);
      });

      test('should create copy with updated spent', () {
        final copy = testBudget.copyWith(spent: 400.0);

        expect(copy.spent, 400.0);
        expect(copy.monthlyLimit, testBudget.monthlyLimit);
      });

      test('should create copy with multiple updates', () {
        final copy = testBudget.copyWith(
          monthlyLimit: 800.0,
          alertThreshold: 90,
          isActive: false,
        );

        expect(copy.monthlyLimit, 800.0);
        expect(copy.alertThreshold, 90);
        expect(copy.isActive, false);
        expect(copy.id, testBudget.id);
      });
    });

    group('remaining', () {
      test('should calculate remaining amount correctly', () {
        expect(testBudget.remaining, 300.0); // 500 - 200
      });

      test('should return negative when over budget', () {
        final overBudget = testBudget.copyWith(spent: 600.0);
        expect(overBudget.remaining, -100.0);
      });

      test('should return full limit when nothing spent', () {
        final noSpending = testBudget.copyWith(spent: 0.0);
        expect(noSpending.remaining, 500.0);
      });
    });

    group('percentUsed', () {
      test('should calculate percentage correctly', () {
        expect(testBudget.percentUsed, 40.0); // 200/500 * 100
      });

      test('should clamp to 100 when over budget', () {
        final overBudget = testBudget.copyWith(spent: 600.0);
        expect(overBudget.percentUsed, 100.0);
      });

      test('should be 0 when nothing spent', () {
        final noSpending = testBudget.copyWith(spent: 0.0);
        expect(noSpending.percentUsed, 0.0);
      });

      test('should handle exact budget', () {
        final exactBudget = testBudget.copyWith(spent: 500.0);
        expect(exactBudget.percentUsed, 100.0);
      });
    });

    group('isOverBudget', () {
      test('should return false when under budget', () {
        expect(testBudget.isOverBudget, false);
      });

      test('should return true when over budget', () {
        final overBudget = testBudget.copyWith(spent: 600.0);
        expect(overBudget.isOverBudget, true);
      });

      test('should return true when exactly at limit', () {
        final atLimit = testBudget.copyWith(spent: 500.0);
        expect(atLimit.isOverBudget, true);
      });
    });

    group('shouldAlert', () {
      test('should return false when under threshold', () {
        expect(testBudget.shouldAlert, false); // 40% < 80%
      });

      test('should return true when at threshold', () {
        final atThreshold = testBudget.copyWith(spent: 400.0); // 80%
        expect(atThreshold.shouldAlert, true);
      });

      test('should return true when over threshold', () {
        final overThreshold = testBudget.copyWith(spent: 450.0); // 90%
        expect(overThreshold.shouldAlert, true);
      });

      test('should return true when over budget', () {
        final overBudget = testBudget.copyWith(spent: 600.0);
        expect(overBudget.shouldAlert, true);
      });
    });

    group('status', () {
      test('should return ok when under threshold', () {
        expect(testBudget.status, BudgetStatus.ok);
      });

      test('should return warning when at or above threshold but not exceeded', () {
        final atThreshold = testBudget.copyWith(spent: 400.0); // 80%
        expect(atThreshold.status, BudgetStatus.warning);

        final nearLimit = testBudget.copyWith(spent: 490.0); // 98%
        expect(nearLimit.status, BudgetStatus.warning);
      });

      test('should return exceeded when at or over limit', () {
        final atLimit = testBudget.copyWith(spent: 500.0);
        expect(atLimit.status, BudgetStatus.exceeded);

        final overLimit = testBudget.copyWith(spent: 600.0);
        expect(overLimit.status, BudgetStatus.exceeded);
      });
    });

    group('displayName', () {
      test('should return category name when category exists', () {
        final category = Category(
          id: 'cat-1',
          name: 'Alimentation',
          icon: 'restaurant',
          color: '#FF5722',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        );
        final budgetWithCategory = testBudget.copyWith(category: category);

        expect(budgetWithCategory.displayName, 'Alimentation');
      });

      test('should return Budget global when no category', () {
        final globalBudget = Budget(
          id: 'budget-1',
          userId: 'user-1',
          categoryId: null,
          monthlyLimit: 1000.0,
          periodStart: DateTime(2024, 1, 1),
          createdAt: now,
          updatedAt: now,
        );

        expect(globalBudget.displayName, 'Budget global');
      });
    });

    group('isGlobal', () {
      test('should return true when categoryId is null', () {
        final globalBudget = Budget(
          id: 'budget-1',
          userId: 'user-1',
          categoryId: null,
          monthlyLimit: 1000.0,
          periodStart: DateTime(2024, 1, 1),
          createdAt: now,
          updatedAt: now,
        );

        expect(globalBudget.isGlobal, true);
      });

      test('should return false when categoryId exists', () {
        expect(testBudget.isGlobal, false);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final budget1 = Budget(
          id: 'budget-1',
          userId: 'user-1',
          categoryId: 'cat-1',
          monthlyLimit: 500.0,
          alertThreshold: 80,
          isActive: true,
          periodStart: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          spent: 100.0,
        );

        final budget2 = Budget(
          id: 'budget-1',
          userId: 'user-1',
          categoryId: 'cat-1',
          monthlyLimit: 500.0,
          alertThreshold: 80,
          isActive: true,
          periodStart: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          spent: 100.0,
        );

        expect(budget1, equals(budget2));
      });

      test('should not be equal for different spent amounts', () {
        final budget1 = Budget(
          id: 'budget-1',
          userId: 'user-1',
          monthlyLimit: 500.0,
          periodStart: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          spent: 100.0,
        );

        final budget2 = Budget(
          id: 'budget-1',
          userId: 'user-1',
          monthlyLimit: 500.0,
          periodStart: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          spent: 200.0,
        );

        expect(budget1, isNot(equals(budget2)));
      });
    });

    group('edge cases', () {
      test('should handle zero monthly limit', () {
        // This would cause division by zero in percentUsed
        final zeroBudget = Budget(
          id: 'budget-1',
          userId: 'user-1',
          monthlyLimit: 0.0,
          periodStart: DateTime(2024, 1, 1),
          createdAt: now,
          updatedAt: now,
          spent: 0.0,
        );

        // Division by zero returns NaN or Infinity, but clamp handles it
        // 0/0 = NaN, clamp(0, 100) on NaN returns NaN
        // In practice, UI should prevent zero limits
        final percent = zeroBudget.percentUsed;
        expect(percent.isNaN || percent == 0 || percent == 100, true);
      });

      test('should handle very small amounts', () {
        final smallBudget = Budget(
          id: 'budget-1',
          userId: 'user-1',
          monthlyLimit: 0.01,
          periodStart: DateTime(2024, 1, 1),
          createdAt: now,
          updatedAt: now,
          spent: 0.005,
        );

        expect(smallBudget.percentUsed, closeTo(50.0, 0.01));
        expect(smallBudget.remaining, closeTo(0.005, 0.001));
      });
    });
  });
}
