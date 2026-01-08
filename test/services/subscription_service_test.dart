import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/subscription_service.dart';

void main() {
  group('SubscriptionType', () {
    test('should have correct values', () {
      expect(SubscriptionType.free.value, 'free');
      expect(SubscriptionType.premium.value, 'premium');
    });

    test('should have correct labels', () {
      expect(SubscriptionType.free.label, 'Gratuit');
      expect(SubscriptionType.premium.label, 'Premium');
    });

    test('fromString should return correct type', () {
      expect(SubscriptionType.fromString('free'), SubscriptionType.free);
      expect(SubscriptionType.fromString('premium'), SubscriptionType.premium);
    });

    test('fromString should return free for unknown value', () {
      expect(SubscriptionType.fromString('unknown'), SubscriptionType.free);
      expect(SubscriptionType.fromString(''), SubscriptionType.free);
    });
  });

  group('FreeLimits', () {
    test('should have correct limits', () {
      expect(FreeLimits.maxCategories, 5);
      expect(FreeLimits.maxBudgets, 1);
      expect(FreeLimits.maxGoals, 1);
      expect(FreeLimits.maxNotificationReminders, 1);
    });
  });

  group('PremiumFeature', () {
    test('should have 11 features', () {
      expect(PremiumFeature.values.length, 11);
    });

    test('should have correct values and labels', () {
      expect(PremiumFeature.unlimitedCategories.value, 'unlimited_categories');
      expect(PremiumFeature.unlimitedCategories.label, 'Catégories illimitées');

      expect(PremiumFeature.unlimitedBudgets.value, 'unlimited_budgets');
      expect(PremiumFeature.unlimitedBudgets.label, 'Budgets illimités');

      expect(PremiumFeature.noAds.value, 'no_ads');
      expect(PremiumFeature.noAds.label, 'Sans publicités');
    });

    test('all features should have non-empty values and labels', () {
      for (final feature in PremiumFeature.values) {
        expect(feature.value.isNotEmpty, true);
        expect(feature.label.isNotEmpty, true);
      }
    });
  });

  group('SubscriptionService', () {
    group('trialDays', () {
      test('should be 7 days', () {
        expect(SubscriptionService.trialDays, 7);
      });
    });

    group('getLimitMessage', () {
      test('should return correct message for categories', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.unlimitedCategories,
        );
        expect(message, contains('${FreeLimits.maxCategories}'));
        expect(message, contains('catégories'));
        expect(message, contains('Premium'));
      });

      test('should return correct message for budgets', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.unlimitedBudgets,
        );
        expect(message, contains('${FreeLimits.maxBudgets}'));
        expect(message, contains('budget'));
        expect(message, contains('Premium'));
      });

      test('should return correct message for goals', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.unlimitedGoals,
        );
        expect(message, contains('${FreeLimits.maxGoals}'));
        expect(message, contains('objectif'));
        expect(message, contains('Premium'));
      });

      test('should return correct message for all premium features', () {
        for (final feature in PremiumFeature.values) {
          final message = SubscriptionService.getLimitMessage(feature);
          expect(message.isNotEmpty, true);
          expect(message.toLowerCase(), contains('premium'));
        }
      });

      test('should mention Premium for advancedStats', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.advancedStats,
        );
        expect(message, contains('graphiques avancés'));
        expect(message, contains('Premium'));
      });

      test('should mention Premium for importCsv', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.importCsv,
        );
        expect(message.toLowerCase(), contains('import csv'));
        expect(message, contains('Premium'));
      });

      test('should mention Premium for exportData', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.exportData,
        );
        expect(message, contains('export'));
        expect(message, contains('Premium'));
      });

      test('should mention Premium for cloudSync', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.cloudSync,
        );
        expect(message, contains('synchronisation'));
        expect(message, contains('Premium'));
      });

      test('should mention Premium for noAds', () {
        final message = SubscriptionService.getLimitMessage(
          PremiumFeature.noAds,
        );
        expect(message, contains('publicités'));
        expect(message, contains('Premium'));
      });
    });
  });
}
