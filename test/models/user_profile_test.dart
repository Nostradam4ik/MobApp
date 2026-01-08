import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/user_profile.dart';
import 'package:smartspend/core/constants/app_constants.dart';

void main() {
  group('IncomeType (from app_constants)', () {
    test('should have correct values', () {
      expect(IncomeType.fixed.value, 'fixed');
      expect(IncomeType.variable.value, 'variable');
    });

    test('should have correct labels', () {
      expect(IncomeType.fixed.label, 'Fixe');
      expect(IncomeType.variable.label, 'Variable');
    });

    test('fromString should return correct type', () {
      expect(IncomeType.fromString('fixed'), IncomeType.fixed);
      expect(IncomeType.fromString('variable'), IncomeType.variable);
    });

    test('fromString should return fixed for unknown value', () {
      expect(IncomeType.fromString('unknown'), IncomeType.fixed);
      expect(IncomeType.fromString(''), IncomeType.fixed);
    });
  });

  group('UserProfile', () {
    final now = DateTime.now();
    final testProfile = UserProfile(
      id: 'user-123',
      name: 'Jean Dupont',
      email: 'jean@example.com',
      avatarUrl: 'https://example.com/avatar.jpg',
      currency: 'EUR',
      incomeType: IncomeType.fixed,
      monthlyIncome: 3000.0,
      notificationEnabled: true,
      isPremium: true,
      premiumExpiresAt: DateTime.now().add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create UserProfile from valid JSON', () {
        final json = {
          'id': 'user-123',
          'name': 'Jean Dupont',
          'email': 'jean@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'currency': 'EUR',
          'income_type': 'fixed',
          'monthly_income': 3000.0,
          'notification_enabled': true,
          'is_premium': true,
          'premium_expires_at': '2025-01-15T10:00:00.000Z',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'user-123');
        expect(profile.name, 'Jean Dupont');
        expect(profile.email, 'jean@example.com');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.currency, 'EUR');
        expect(profile.incomeType, IncomeType.fixed);
        expect(profile.monthlyIncome, 3000.0);
        expect(profile.notificationEnabled, true);
        expect(profile.isPremium, true);
        expect(profile.premiumExpiresAt, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'user-123',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.name, isNull);
        expect(profile.email, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.currency, 'EUR');
        expect(profile.incomeType, IncomeType.fixed);
        expect(profile.monthlyIncome, 0);
        expect(profile.notificationEnabled, true);
        expect(profile.isPremium, false);
        expect(profile.premiumExpiresAt, isNull);
      });

      test('should handle integer monthly income', () {
        final json = {
          'id': 'user-123',
          'monthly_income': 3000,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.monthlyIncome, 3000.0);
        expect(profile.monthlyIncome, isA<double>());
      });
    });

    group('toJson', () {
      test('should convert UserProfile to JSON', () {
        final json = testProfile.toJson();

        expect(json['id'], 'user-123');
        expect(json['name'], 'Jean Dupont');
        expect(json['email'], 'jean@example.com');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['currency'], 'EUR');
        expect(json['income_type'], 'fixed');
        expect(json['monthly_income'], 3000.0);
        expect(json['notification_enabled'], true);
        expect(json['is_premium'], true);
        expect(json['premium_expires_at'], isA<String>());
      });

      test('should handle null premiumExpiresAt', () {
        final profileWithoutPremium = UserProfile(
          id: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final json = profileWithoutPremium.toJson();
        expect(json['premium_expires_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testProfile.copyWith(name: 'Pierre Martin');

        expect(copy.name, 'Pierre Martin');
        expect(copy.id, testProfile.id);
        expect(copy.email, testProfile.email);
      });

      test('should create copy with updated premium status', () {
        final copy = testProfile.copyWith(isPremium: false);

        expect(copy.isPremium, false);
        expect(copy.name, testProfile.name);
      });

      test('should create copy with multiple updates', () {
        final copy = testProfile.copyWith(
          currency: 'USD',
          monthlyIncome: 5000.0,
          notificationEnabled: false,
        );

        expect(copy.currency, 'USD');
        expect(copy.monthlyIncome, 5000.0);
        expect(copy.notificationEnabled, false);
        expect(copy.id, testProfile.id);
      });
    });

    group('isPremiumActive', () {
      test('should return false when not premium', () {
        final nonPremium = UserProfile(
          id: 'user-1',
          isPremium: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(nonPremium.isPremiumActive, false);
      });

      test('should return true when premium without expiry', () {
        final premiumForever = UserProfile(
          id: 'user-1',
          isPremium: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(premiumForever.isPremiumActive, true);
      });

      test('should return true when premium not expired', () {
        final activePremium = UserProfile(
          id: 'user-1',
          isPremium: true,
          premiumExpiresAt: DateTime.now().add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        );

        expect(activePremium.isPremiumActive, true);
      });

      test('should return false when premium expired', () {
        final expiredPremium = UserProfile(
          id: 'user-1',
          isPremium: true,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        );

        expect(expiredPremium.isPremiumActive, false);
      });
    });

    group('initials', () {
      test('should return initials from full name', () {
        expect(testProfile.initials, 'JD');
      });

      test('should return single initial for single name', () {
        final singleName = testProfile.copyWith(name: 'Jean');
        expect(singleName.initials, 'J');
      });

      test('should return first letter of email when no name', () {
        final noName = UserProfile(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        );

        expect(noName.initials, 'T');
      });

      test('should return ? when no name or email', () {
        final noInfo = UserProfile(
          id: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(noInfo.initials, '?');
      });

      test('should handle empty name', () {
        final emptyName = UserProfile(
          id: 'user-1',
          name: '',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        );

        expect(emptyName.initials, 'T');
      });

      test('should uppercase initials', () {
        final lowercase = testProfile.copyWith(name: 'jean dupont');
        expect(lowercase.initials, 'JD');
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final profile1 = UserProfile(
          id: 'user-1',
          name: 'Test',
          email: 'test@example.com',
          currency: 'EUR',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final profile2 = UserProfile(
          id: 'user-1',
          name: 'Test',
          email: 'test@example.com',
          currency: 'EUR',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(profile1, equals(profile2));
      });

      test('should not be equal for different currencies', () {
        final profile1 = UserProfile(
          id: 'user-1',
          currency: 'EUR',
          createdAt: now,
          updatedAt: now,
        );

        final profile2 = UserProfile(
          id: 'user-1',
          currency: 'USD',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile1, isNot(equals(profile2)));
      });
    });
  });
}
