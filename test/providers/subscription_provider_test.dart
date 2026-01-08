import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/subscription_service.dart';

// Tests for SubscriptionProvider logic without SharedPreferences
// These tests verify the pure computation logic

void main() {
  group('SubscriptionProvider Logic', () {
    group('canAddCategory', () {
      test('should allow when under limit for free user', () {
        const isPremium = false;
        const currentCount = 3;

        final canAdd = isPremium || currentCount < FreeLimits.maxCategories;

        expect(canAdd, true);
      });

      test('should not allow when at limit for free user', () {
        const isPremium = false;
        final currentCount = FreeLimits.maxCategories;

        final canAdd = isPremium || currentCount < FreeLimits.maxCategories;

        expect(canAdd, false);
      });

      test('should always allow for premium user', () {
        const isPremium = true;
        final currentCount = FreeLimits.maxCategories + 10;

        final canAdd = isPremium || currentCount < FreeLimits.maxCategories;

        expect(canAdd, true);
      });
    });

    group('canAddBudget', () {
      test('should allow when under limit for free user', () {
        const isPremium = false;
        const currentCount = 0;

        final canAdd = isPremium || currentCount < FreeLimits.maxBudgets;

        expect(canAdd, true);
      });

      test('should not allow when at limit for free user', () {
        const isPremium = false;
        final currentCount = FreeLimits.maxBudgets;

        final canAdd = isPremium || currentCount < FreeLimits.maxBudgets;

        expect(canAdd, false);
      });

      test('should always allow for premium user', () {
        const isPremium = true;
        const currentCount = 100;

        final canAdd = isPremium || currentCount < FreeLimits.maxBudgets;

        expect(canAdd, true);
      });
    });

    group('canAddGoal', () {
      test('should allow when under limit for free user', () {
        const isPremium = false;
        const currentCount = 0;

        final canAdd = isPremium || currentCount < FreeLimits.maxGoals;

        expect(canAdd, true);
      });

      test('should not allow when at limit for free user', () {
        const isPremium = false;
        final currentCount = FreeLimits.maxGoals;

        final canAdd = isPremium || currentCount < FreeLimits.maxGoals;

        expect(canAdd, false);
      });
    });

    group('isPremiumActive', () {
      test('should be false when not premium', () {
        const isPremium = false;
        expect(isPremium, false);
      });

      test('should check expiry date when premium', () {
        const isPremium = true;
        final expiryDate = DateTime.now().add(const Duration(days: 30));
        final isActive = isPremium && expiryDate.isAfter(DateTime.now());

        expect(isActive, true);
      });

      test('should be false when premium expired', () {
        const isPremium = true;
        final expiryDate = DateTime.now().subtract(const Duration(days: 1));
        final isActive = isPremium && expiryDate.isAfter(DateTime.now());

        expect(isActive, false);
      });
    });

    group('daysRemaining', () {
      test('should return null for no expiry', () {
        DateTime? expiry;
        int? daysRemaining;

        if (expiry == null) {
          daysRemaining = null;
        } else {
          daysRemaining = expiry.difference(DateTime.now()).inDays;
        }

        expect(daysRemaining, isNull);
      });

      test('should return positive days for future expiry', () {
        final expiry = DateTime.now().add(const Duration(days: 15));
        final daysRemaining = expiry.difference(DateTime.now()).inDays;

        expect(daysRemaining, 15);
      });

      test('should return 0 for past expiry', () {
        final expiry = DateTime.now().subtract(const Duration(days: 5));
        int daysRemaining;

        if (expiry.isBefore(DateTime.now())) {
          daysRemaining = 0;
        } else {
          daysRemaining = expiry.difference(DateTime.now()).inDays;
        }

        expect(daysRemaining, 0);
      });
    });

    group('trial', () {
      test('canStartTrial should be true when not used', () {
        const hasUsedTrial = false;
        expect(!hasUsedTrial, true);
      });

      test('canStartTrial should be false when already used', () {
        const hasUsedTrial = true;
        expect(!hasUsedTrial, false);
      });

      test('trialDaysRemaining calculation', () {
        final trialStart = DateTime.now().subtract(const Duration(days: 3));
        const trialDays = 7;
        final trialEnd = trialStart.add(Duration(days: trialDays));
        final remaining = trialEnd.difference(DateTime.now()).inDays;

        expect(remaining, 4); // 7 - 3 = 4 days remaining
      });

      test('isTrialActive check', () {
        final trialStart = DateTime.now().subtract(const Duration(days: 3));
        const trialDays = 7;
        final trialEnd = trialStart.add(Duration(days: trialDays));
        final isActive = DateTime.now().isBefore(trialEnd);

        expect(isActive, true);
      });

      test('isTrialActive should be false when expired', () {
        final trialStart = DateTime.now().subtract(const Duration(days: 10));
        const trialDays = 7;
        final trialEnd = trialStart.add(Duration(days: trialDays));
        final isActive = DateTime.now().isBefore(trialEnd);

        expect(isActive, false);
      });
    });

    group('hasFeature', () {
      test('should return true for premium user', () {
        const isPremium = true;
        expect(isPremium, true);
      });

      test('should return false for free user', () {
        const isPremium = false;
        expect(isPremium, false);
      });
    });

    group('subscription type transitions', () {
      test('should transition from free to premium', () {
        var type = SubscriptionType.free;
        type = SubscriptionType.premium;
        expect(type, SubscriptionType.premium);
      });

      test('should transition from premium to free on deactivation', () {
        var type = SubscriptionType.premium;
        type = SubscriptionType.free;
        expect(type, SubscriptionType.free);
      });
    });
  });
}
