import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/tag.dart';

void main() {
  group('Tag', () {
    final now = DateTime.now();
    final testTag = Tag(
      id: 'tag-123',
      name: 'Urgent',
      color: '#FF6B6B',
      icon: '🔥',
      createdAt: now,
      usageCount: 5,
    );

    group('predefined data', () {
      test('should have predefined colors', () {
        expect(Tag.predefinedColors.length, 16);
        expect(Tag.predefinedColors.first, '#FF6B6B');
        for (final color in Tag.predefinedColors) {
          expect(color.startsWith('#'), true);
          expect(color.length, 7);
        }
      });

      test('should have suggested icons', () {
        expect(Tag.suggestedIcons.length, 24);
        expect(Tag.suggestedIcons, contains('🏷️'));
        expect(Tag.suggestedIcons, contains('💰'));
      });

      test('should have suggested tags', () {
        final suggested = Tag.suggestedTags;
        expect(suggested.length, 6);

        final names = suggested.map((t) => t.name).toList();
        expect(names, contains('Urgent'));
        expect(names, contains('Récurrent'));
        expect(names, contains('Essentiel'));
        expect(names, contains('Économie'));
        expect(names, contains('Plaisir'));
      });
    });

    group('fromJson', () {
      test('should create Tag from valid JSON', () {
        final json = {
          'id': 'tag-123',
          'name': 'Urgent',
          'color': '#FF6B6B',
          'icon': '🔥',
          'created_at': '2024-01-15T10:00:00.000Z',
          'usage_count': 10,
        };

        final tag = Tag.fromJson(json);

        expect(tag.id, 'tag-123');
        expect(tag.name, 'Urgent');
        expect(tag.color, '#FF6B6B');
        expect(tag.icon, '🔥');
        expect(tag.usageCount, 10);
      });

      test('should handle null icon', () {
        final json = {
          'id': 'tag-123',
          'name': 'Simple',
          'color': '#4ECDC4',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final tag = Tag.fromJson(json);

        expect(tag.icon, isNull);
        expect(tag.usageCount, 0);
      });
    });

    group('toJson', () {
      test('should convert Tag to JSON', () {
        final json = testTag.toJson();

        expect(json['id'], 'tag-123');
        expect(json['name'], 'Urgent');
        expect(json['color'], '#FF6B6B');
        expect(json['icon'], '🔥');
        expect(json['usage_count'], 5);
        expect(json['created_at'], isA<String>());
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testTag.copyWith(name: 'Nouveau nom');

        expect(copy.name, 'Nouveau nom');
        expect(copy.id, testTag.id);
        expect(copy.color, testTag.color);
      });

      test('should create copy with updated usageCount', () {
        final copy = testTag.copyWith(usageCount: 20);

        expect(copy.usageCount, 20);
        expect(copy.name, testTag.name);
      });
    });

    group('incrementUsage', () {
      test('should increment usage count by 1', () {
        final incremented = testTag.incrementUsage();

        expect(incremented.usageCount, 6);
        expect(incremented.name, testTag.name);
      });

      test('should work from zero', () {
        final zeroTag = Tag(
          id: 'tag-1',
          name: 'New',
          color: '#000000',
          createdAt: now,
          usageCount: 0,
        );

        final incremented = zeroTag.incrementUsage();
        expect(incremented.usageCount, 1);
      });
    });

    group('decrementUsage', () {
      test('should decrement usage count by 1', () {
        final decremented = testTag.decrementUsage();

        expect(decremented.usageCount, 4);
      });

      test('should not go below zero', () {
        final zeroTag = Tag(
          id: 'tag-1',
          name: 'New',
          color: '#000000',
          createdAt: now,
          usageCount: 0,
        );

        final decremented = zeroTag.decrementUsage();
        expect(decremented.usageCount, 0);
      });
    });

    group('equality', () {
      test('should be equal for same id, name, color, icon', () {
        final tag1 = Tag(
          id: 'tag-1',
          name: 'Test',
          color: '#FF0000',
          icon: '🏷️',
          createdAt: DateTime(2024, 1, 1),
          usageCount: 5,
        );

        final tag2 = Tag(
          id: 'tag-1',
          name: 'Test',
          color: '#FF0000',
          icon: '🏷️',
          createdAt: DateTime(2024, 6, 1), // Different date
          usageCount: 10, // Different count
        );

        // Equality is based on id, name, color, icon only
        expect(tag1, equals(tag2));
      });

      test('should not be equal for different names', () {
        final tag1 = Tag(
          id: 'tag-1',
          name: 'Test1',
          color: '#FF0000',
          createdAt: now,
        );

        final tag2 = Tag(
          id: 'tag-1',
          name: 'Test2',
          color: '#FF0000',
          createdAt: now,
        );

        expect(tag1, isNot(equals(tag2)));
      });
    });
  });

  group('ExpenseTag', () {
    group('fromJson', () {
      test('should create ExpenseTag from JSON', () {
        final json = {
          'expense_id': 'exp-123',
          'tag_id': 'tag-456',
        };

        final expenseTag = ExpenseTag.fromJson(json);

        expect(expenseTag.expenseId, 'exp-123');
        expect(expenseTag.tagId, 'tag-456');
      });
    });

    group('toJson', () {
      test('should convert ExpenseTag to JSON', () {
        const expenseTag = ExpenseTag(
          expenseId: 'exp-123',
          tagId: 'tag-456',
        );

        final json = expenseTag.toJson();

        expect(json['expense_id'], 'exp-123');
        expect(json['tag_id'], 'tag-456');
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        const et1 = ExpenseTag(expenseId: 'exp-1', tagId: 'tag-1');
        const et2 = ExpenseTag(expenseId: 'exp-1', tagId: 'tag-1');

        expect(et1, equals(et2));
      });
    });
  });

  group('TagStats', () {
    test('should create TagStats with all fields', () {
      final tag = Tag(
        id: 'tag-1',
        name: 'Test',
        color: '#FF0000',
        createdAt: DateTime.now(),
      );

      final stats = TagStats(
        tag: tag,
        expenseCount: 15,
        totalAmount: 500.0,
        averageAmount: 33.33,
        lastUsed: DateTime(2024, 6, 15),
      );

      expect(stats.tag.name, 'Test');
      expect(stats.expenseCount, 15);
      expect(stats.totalAmount, 500.0);
      expect(stats.averageAmount, 33.33);
      expect(stats.lastUsed, isNotNull);
    });

    test('should allow null lastUsed', () {
      final tag = Tag(
        id: 'tag-1',
        name: 'Unused',
        color: '#FF0000',
        createdAt: DateTime.now(),
      );

      final stats = TagStats(
        tag: tag,
        expenseCount: 0,
        totalAmount: 0,
        averageAmount: 0,
      );

      expect(stats.lastUsed, isNull);
    });
  });
}
