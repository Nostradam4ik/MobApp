import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/insight.dart';
import 'package:smartspend/core/constants/app_constants.dart';

void main() {
  group('InsightType', () {
    test('should have correct values', () {
      expect(InsightType.warning.value, 'warning');
      expect(InsightType.tip.value, 'tip');
      expect(InsightType.achievement.value, 'achievement');
      expect(InsightType.prediction.value, 'prediction');
    });

    test('should have 4 types', () {
      expect(InsightType.values.length, 4);
    });
  });

  group('Insight', () {
    final now = DateTime.now();
    final testInsight = Insight(
      id: 'insight-123',
      userId: 'user-456',
      insightType: InsightType.tip,
      title: 'Conseil du jour',
      message: 'Économisez 10% de vos revenus chaque mois',
      data: {'category': 'savings'},
      isRead: false,
      isDismissed: false,
      priority: 5,
      validUntil: DateTime.now().add(const Duration(days: 7)),
      createdAt: now,
    );

    group('fromJson', () {
      test('should create Insight from valid JSON', () {
        final json = {
          'id': 'insight-123',
          'user_id': 'user-456',
          'insight_type': 'tip',
          'title': 'Conseil du jour',
          'message': 'Un message important',
          'data': {'key': 'value'},
          'is_read': false,
          'is_dismissed': false,
          'priority': 5,
          'valid_until': '2025-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final insight = Insight.fromJson(json);

        expect(insight.id, 'insight-123');
        expect(insight.userId, 'user-456');
        expect(insight.insightType, InsightType.tip);
        expect(insight.title, 'Conseil du jour');
        expect(insight.message, 'Un message important');
        expect(insight.data, {'key': 'value'});
        expect(insight.isRead, false);
        expect(insight.isDismissed, false);
        expect(insight.priority, 5);
        expect(insight.validUntil, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'insight-123',
          'user_id': 'user-456',
          'insight_type': 'warning',
          'title': 'Alerte',
          'message': 'Attention',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final insight = Insight.fromJson(json);

        expect(insight.data, isNull);
        expect(insight.isRead, false);
        expect(insight.isDismissed, false);
        expect(insight.priority, 0);
        expect(insight.validUntil, isNull);
      });

      test('should parse all insight types', () {
        for (final type in InsightType.values) {
          final json = {
            'id': 'insight-1',
            'user_id': 'user-1',
            'insight_type': type.value,
            'title': 'Test',
            'message': 'Test',
            'created_at': '2024-01-15T10:00:00.000Z',
          };

          final insight = Insight.fromJson(json);
          expect(insight.insightType, type);
        }
      });

      test('should default to tip for unknown type', () {
        final json = {
          'id': 'insight-1',
          'user_id': 'user-1',
          'insight_type': 'unknown_type',
          'title': 'Test',
          'message': 'Test',
          'created_at': '2024-01-15T10:00:00.000Z',
        };

        final insight = Insight.fromJson(json);
        expect(insight.insightType, InsightType.tip);
      });
    });

    group('toJson', () {
      test('should convert Insight to JSON', () {
        final json = testInsight.toJson();

        expect(json['id'], 'insight-123');
        expect(json['user_id'], 'user-456');
        expect(json['insight_type'], 'tip');
        expect(json['title'], 'Conseil du jour');
        expect(json['message'], 'Économisez 10% de vos revenus chaque mois');
        expect(json['data'], {'category': 'savings'});
        expect(json['is_read'], false);
        expect(json['is_dismissed'], false);
        expect(json['priority'], 5);
        expect(json['valid_until'], isA<String>());
      });

      test('should handle null validUntil', () {
        final insightNoExpiry = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test',
          createdAt: now,
        );

        final json = insightNoExpiry.toJson();
        expect(json['valid_until'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated isRead', () {
        final copy = testInsight.copyWith(isRead: true);

        expect(copy.isRead, true);
        expect(copy.id, testInsight.id);
        expect(copy.title, testInsight.title);
      });

      test('should create copy with updated isDismissed', () {
        final copy = testInsight.copyWith(isDismissed: true);

        expect(copy.isDismissed, true);
        expect(copy.isRead, testInsight.isRead);
      });

      test('should create copy with multiple updates', () {
        final copy = testInsight.copyWith(
          isRead: true,
          isDismissed: true,
          priority: 10,
        );

        expect(copy.isRead, true);
        expect(copy.isDismissed, true);
        expect(copy.priority, 10);
        expect(copy.id, testInsight.id);
      });
    });

    group('isValid', () {
      test('should return false when dismissed', () {
        final dismissed = testInsight.copyWith(isDismissed: true);
        expect(dismissed.isValid, false);
      });

      test('should return true when no expiry date', () {
        final noExpiry = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test',
          createdAt: now,
        );

        expect(noExpiry.isValid, true);
      });

      test('should return true when not expired', () {
        final notExpired = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test',
          validUntil: DateTime.now().add(const Duration(days: 1)),
          createdAt: now,
        );

        expect(notExpired.isValid, true);
      });

      test('should return false when expired', () {
        final expired = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test',
          validUntil: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: now,
        );

        expect(expired.isValid, false);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final insight1 = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime(2024, 1, 1),
        );

        final insight2 = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test message',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(insight1, equals(insight2));
      });

      test('should not be equal for different types', () {
        final insight1 = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.tip,
          title: 'Test',
          message: 'Test',
          createdAt: now,
        );

        final insight2 = Insight(
          id: 'insight-1',
          userId: 'user-1',
          insightType: InsightType.warning,
          title: 'Test',
          message: 'Test',
          createdAt: now,
        );

        expect(insight1, isNot(equals(insight2)));
      });
    });
  });

  group('StatsPeriod', () {
    test('should have correct labels', () {
      expect(StatsPeriod.day.label, 'Jour');
      expect(StatsPeriod.week.label, 'Semaine');
      expect(StatsPeriod.month.label, 'Mois');
      expect(StatsPeriod.year.label, 'Année');
    });

    test('should have 4 periods', () {
      expect(StatsPeriod.values.length, 4);
    });
  });
}
