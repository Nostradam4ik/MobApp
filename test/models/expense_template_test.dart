import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/expense_template.dart';

void main() {
  group('ExpenseTemplate', () {
    final now = DateTime.now();
    final testTemplate = ExpenseTemplate(
      id: 'template-123',
      userId: 'user-456',
      name: 'Café du matin',
      amount: 3.50,
      categoryId: 'cat-coffee',
      accountId: 'acc-main',
      note: 'Café quotidien',
      tagIds: ['tag-1', 'tag-2'],
      icon: '☕',
      color: 0xFF795548,
      usageCount: 10,
      lastUsed: DateTime(2024, 1, 15),
      sortOrder: 1,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create ExpenseTemplate from valid JSON', () {
        final json = {
          'id': 'template-123',
          'user_id': 'user-456',
          'name': 'Café du matin',
          'amount': 3.50,
          'category_id': 'cat-coffee',
          'account_id': 'acc-main',
          'note': 'Café quotidien',
          'tag_ids': ['tag-1', 'tag-2'],
          'icon': '☕',
          'color': 0xFF795548,
          'usage_count': 10,
          'last_used': '2024-01-15T10:00:00.000Z',
          'sort_order': 1,
          'is_active': true,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final template = ExpenseTemplate.fromJson(json);

        expect(template.id, 'template-123');
        expect(template.userId, 'user-456');
        expect(template.name, 'Café du matin');
        expect(template.amount, 3.50);
        expect(template.categoryId, 'cat-coffee');
        expect(template.accountId, 'acc-main');
        expect(template.note, 'Café quotidien');
        expect(template.tagIds, ['tag-1', 'tag-2']);
        expect(template.icon, '☕');
        expect(template.color, 0xFF795548);
        expect(template.usageCount, 10);
        expect(template.lastUsed, isNotNull);
        expect(template.sortOrder, 1);
        expect(template.isActive, true);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'template-123',
          'user_id': 'user-456',
          'name': 'Simple',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final template = ExpenseTemplate.fromJson(json);

        expect(template.amount, isNull);
        expect(template.categoryId, isNull);
        expect(template.accountId, isNull);
        expect(template.note, isNull);
        expect(template.tagIds, isNull);
        expect(template.icon, isNull);
        expect(template.color, 0xFF2196F3); // default blue
        expect(template.usageCount, 0);
        expect(template.lastUsed, isNull);
        expect(template.sortOrder, 0);
        expect(template.isActive, true);
      });

      test('should handle integer amount', () {
        final json = {
          'id': 'template-1',
          'user_id': 'user-1',
          'name': 'Test',
          'amount': 10,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final template = ExpenseTemplate.fromJson(json);

        expect(template.amount, 10.0);
        expect(template.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('should convert ExpenseTemplate to JSON', () {
        final json = testTemplate.toJson();

        expect(json['id'], 'template-123');
        expect(json['user_id'], 'user-456');
        expect(json['name'], 'Café du matin');
        expect(json['amount'], 3.50);
        expect(json['category_id'], 'cat-coffee');
        expect(json['account_id'], 'acc-main');
        expect(json['note'], 'Café quotidien');
        expect(json['tag_ids'], ['tag-1', 'tag-2']);
        expect(json['icon'], '☕');
        expect(json['color'], 0xFF795548);
        expect(json['usage_count'], 10);
        expect(json['last_used'], isA<String>());
        expect(json['sort_order'], 1);
        expect(json['is_active'], true);
      });

      test('should handle null lastUsed', () {
        final noLastUsed = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'New',
          createdAt: now,
          updatedAt: now,
        );

        final json = noLastUsed.toJson();
        expect(json['last_used'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testTemplate.copyWith(name: 'Nouveau nom');

        expect(copy.name, 'Nouveau nom');
        expect(copy.id, testTemplate.id);
        expect(copy.amount, testTemplate.amount);
      });

      test('should create copy with updated amount', () {
        final copy = testTemplate.copyWith(amount: 5.00);

        expect(copy.amount, 5.00);
        expect(copy.name, testTemplate.name);
      });

      test('should create copy with multiple updates', () {
        final copy = testTemplate.copyWith(
          name: 'Updated',
          amount: 10.00,
          icon: '🍵',
          isActive: false,
        );

        expect(copy.name, 'Updated');
        expect(copy.amount, 10.00);
        expect(copy.icon, '🍵');
        expect(copy.isActive, false);
        expect(copy.id, testTemplate.id);
      });
    });

    group('incrementUsage', () {
      test('should increment usage count by 1', () {
        final incremented = testTemplate.incrementUsage();

        expect(incremented.usageCount, 11);
        expect(incremented.lastUsed, isNotNull);
        expect(incremented.name, testTemplate.name);
      });

      test('should update lastUsed to now', () {
        final beforeIncrement = DateTime.now();
        final incremented = testTemplate.incrementUsage();
        final afterIncrement = DateTime.now();

        expect(incremented.lastUsed!.isAfter(beforeIncrement) ||
            incremented.lastUsed!.isAtSameMomentAs(beforeIncrement), true);
        expect(incremented.lastUsed!.isBefore(afterIncrement) ||
            incremented.lastUsed!.isAtSameMomentAs(afterIncrement), true);
      });

      test('should work from zero usage', () {
        final newTemplate = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'New',
          usageCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        final incremented = newTemplate.incrementUsage();
        expect(incremented.usageCount, 1);
      });
    });

    group('hasFixedAmount', () {
      test('should return true when amount is set and positive', () {
        expect(testTemplate.hasFixedAmount, true);
      });

      test('should return false when amount is null', () {
        final noAmount = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'No amount',
          createdAt: now,
          updatedAt: now,
        );

        expect(noAmount.hasFixedAmount, false);
      });

      test('should return false when amount is zero', () {
        final zeroAmount = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Zero',
          amount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(zeroAmount.hasFixedAmount, false);
      });

      test('should return false when amount is negative', () {
        final negativeAmount = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Negative',
          amount: -5.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(negativeAmount.hasFixedAmount, false);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final template1 = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Test',
          amount: 10.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final template2 = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Test',
          amount: 10.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(template1, equals(template2));
      });

      test('should not be equal for different names', () {
        final template1 = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Test1',
          createdAt: now,
          updatedAt: now,
        );

        final template2 = ExpenseTemplate(
          id: 'template-1',
          userId: 'user-1',
          name: 'Test2',
          createdAt: now,
          updatedAt: now,
        );

        expect(template1, isNot(equals(template2)));
      });
    });
  });

  group('SuggestedTemplates', () {
    test('getDefaults should return 6 templates', () {
      final defaults = SuggestedTemplates.getDefaults();
      expect(defaults.length, 6);
    });

    test('should have Café template', () {
      final defaults = SuggestedTemplates.getDefaults();
      final cafe = defaults.firstWhere((t) => t['name'] == 'Café');

      expect(cafe['icon'], '☕');
      expect(cafe['amount'], 3.50);
      expect(cafe['color'], 0xFF795548);
    });

    test('should have Déjeuner template', () {
      final defaults = SuggestedTemplates.getDefaults();
      final dejeuner = defaults.firstWhere((t) => t['name'] == 'Déjeuner');

      expect(dejeuner['icon'], '🍽️');
      expect(dejeuner['amount'], 12.00);
    });

    test('should have Transport template', () {
      final defaults = SuggestedTemplates.getDefaults();
      final transport = defaults.firstWhere((t) => t['name'] == 'Transport');

      expect(transport['icon'], '🚇');
      expect(transport['amount'], 2.00);
    });

    test('Courses template should not have fixed amount', () {
      final defaults = SuggestedTemplates.getDefaults();
      final courses = defaults.firstWhere((t) => t['name'] == 'Courses');

      expect(courses['amount'], isNull);
      expect(courses['icon'], '🛒');
    });

    test('all templates should have name, icon and color', () {
      final defaults = SuggestedTemplates.getDefaults();

      for (final template in defaults) {
        expect(template['name'], isNotEmpty);
        expect(template['icon'], isNotEmpty);
        expect(template['color'], isA<int>());
      }
    });
  });
}
