import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('storage keys', () {
      test('should have theme mode key', () {
        expect(AppConstants.keyThemeMode, 'theme_mode');
      });

      test('should have onboarding key', () {
        expect(AppConstants.keyOnboardingComplete, 'onboarding_complete');
      });

      test('should have last sync key', () {
        expect(AppConstants.keyLastSyncDate, 'last_sync_date');
      });

      test('should have notifications key', () {
        expect(AppConstants.keyNotificationsEnabled, 'notifications_enabled');
      });
    });

    group('cache', () {
      test('should have cache duration', () {
        expect(AppConstants.cacheDuration, isA<Duration>());
        expect(AppConstants.cacheDuration.inMinutes, 5);
      });
    });

    group('pagination', () {
      test('should have default page size', () {
        expect(AppConstants.defaultPageSize, greaterThan(0));
        expect(AppConstants.defaultPageSize, 20);
      });
    });

    group('validation', () {
      test('should have max note length', () {
        expect(AppConstants.maxNoteLength, greaterThan(0));
        expect(AppConstants.maxNoteLength, 500);
      });

      test('should have max expense amount', () {
        expect(AppConstants.maxExpenseAmount, greaterThan(0));
        expect(AppConstants.maxExpenseAmount, 999999.99);
      });
    });

    group('date formats', () {
      test('should have short date format', () {
        expect(AppConstants.dateFormatShort, 'dd/MM');
      });

      test('should have medium date format', () {
        expect(AppConstants.dateFormatMedium, 'dd MMM');
      });

      test('should have full date format', () {
        expect(AppConstants.dateFormatFull, 'dd MMMM yyyy');
      });

      test('should have month format', () {
        expect(AppConstants.dateFormatMonth, 'MMMM yyyy');
      });
    });

    group('quick amounts', () {
      test('should have quick amounts list', () {
        expect(AppConstants.quickAmounts, isNotEmpty);
        expect(AppConstants.quickAmounts.length, 5);
      });

      test('should have specific quick amounts', () {
        expect(AppConstants.quickAmounts, contains(5));
        expect(AppConstants.quickAmounts, contains(10));
        expect(AppConstants.quickAmounts, contains(20));
        expect(AppConstants.quickAmounts, contains(50));
        expect(AppConstants.quickAmounts, contains(100));
      });

      test('quick amounts should be in ascending order', () {
        for (int i = 0; i < AppConstants.quickAmounts.length - 1; i++) {
          expect(
            AppConstants.quickAmounts[i],
            lessThan(AppConstants.quickAmounts[i + 1]),
          );
        }
      });
    });
  });

  group('SecurityConstants', () {
    group('password', () {
      test('should have min password length', () {
        expect(SecurityConstants.minPasswordLength, greaterThanOrEqualTo(8));
        expect(SecurityConstants.minPasswordLength, 12); // OWASP recommendation
      });

      test('should have max password length', () {
        expect(SecurityConstants.maxPasswordLength, greaterThan(SecurityConstants.minPasswordLength));
        expect(SecurityConstants.maxPasswordLength, 128);
      });

      test('should have min password strength', () {
        expect(SecurityConstants.minPasswordStrength, greaterThan(0));
        expect(SecurityConstants.minPasswordStrength, lessThanOrEqualTo(10));
      });
    });

    group('PIN', () {
      test('should have min PIN length', () {
        expect(SecurityConstants.minPinLength, greaterThanOrEqualTo(4));
      });

      test('should have max PIN length', () {
        expect(SecurityConstants.maxPinLength, greaterThan(SecurityConstants.minPinLength));
      });
    });

    group('session', () {
      test('should have session timeout', () {
        expect(SecurityConstants.sessionTimeout, isA<Duration>());
        expect(SecurityConstants.sessionTimeout.inMinutes, 30);
      });

      test('should have refresh token expiry', () {
        expect(SecurityConstants.refreshTokenExpiry, isA<Duration>());
        expect(SecurityConstants.refreshTokenExpiry.inDays, 7);
      });

      test('should have refresh threshold', () {
        expect(SecurityConstants.refreshThreshold, isA<Duration>());
        expect(SecurityConstants.refreshThreshold.inMinutes, 5);
      });
    });

    group('anti-bruteforce', () {
      test('should have max login attempts', () {
        expect(SecurityConstants.maxLoginAttempts, greaterThan(0));
        expect(SecurityConstants.maxLoginAttempts, 5);
      });

      test('should have initial lockout duration', () {
        expect(SecurityConstants.initialLockoutDuration, isA<Duration>());
        expect(SecurityConstants.initialLockoutDuration.inMinutes, 1);
      });

      test('should have max lockout duration', () {
        expect(SecurityConstants.maxLockoutDuration, isA<Duration>());
        expect(SecurityConstants.maxLockoutDuration.inMinutes, 30);
      });

      test('should have lockout multiplier', () {
        expect(SecurityConstants.lockoutMultiplier, greaterThan(1));
        expect(SecurityConstants.lockoutMultiplier, 2.0);
      });
    });

    group('encryption', () {
      test('should have AES key length', () {
        expect(SecurityConstants.aesKeyLength, 32); // 256 bits
      });

      test('should have IV length', () {
        expect(SecurityConstants.ivLength, 16); // 128 bits
      });

      test('should have salt length', () {
        expect(SecurityConstants.saltLength, greaterThan(0));
      });

      test('should have PBKDF2 iterations', () {
        expect(SecurityConstants.pbkdf2Iterations, greaterThanOrEqualTo(10000));
      });
    });

    group('tokens', () {
      test('should have secure token length', () {
        expect(SecurityConstants.secureTokenLength, greaterThanOrEqualTo(16));
      });

      test('should have verification code length', () {
        expect(SecurityConstants.verificationCodeLength, 6);
      });
    });

    group('rate limiting', () {
      test('should have max requests per minute', () {
        expect(SecurityConstants.maxRequestsPerMinute, greaterThan(0));
      });

      test('should have max auth requests per hour', () {
        expect(SecurityConstants.maxAuthRequestsPerHour, greaterThan(0));
        expect(SecurityConstants.maxAuthRequestsPerHour, lessThan(SecurityConstants.maxRequestsPerMinute * 60));
      });
    });

    group('biometrics', () {
      test('should have biometric reauth timeout', () {
        expect(SecurityConstants.biometricReauthTimeout, isA<Duration>());
      });

      test('should have sensitive operation timeout', () {
        expect(SecurityConstants.sensitiveOperationTimeout, isA<Duration>());
      });
    });

    group('storage keys', () {
      test('should have auth token key', () {
        expect(SecurityConstants.keyAuthToken, isNotEmpty);
      });

      test('should have refresh token key', () {
        expect(SecurityConstants.keyRefreshToken, isNotEmpty);
      });

      test('should have encryption key', () {
        expect(SecurityConstants.keyEncryptionKey, isNotEmpty);
      });
    });

    group('network', () {
      test('should have connection timeout', () {
        expect(SecurityConstants.connectionTimeout, isA<Duration>());
        expect(SecurityConstants.connectionTimeout.inSeconds, 30);
      });

      test('should have receive timeout', () {
        expect(SecurityConstants.receiveTimeout, isA<Duration>());
        expect(SecurityConstants.receiveTimeout.inSeconds, 60);
      });

      test('should have max retries', () {
        expect(SecurityConstants.maxRetries, greaterThan(0));
      });

      test('should have allowed domains', () {
        expect(SecurityConstants.allowedDomains, isNotEmpty);
        expect(SecurityConstants.allowedDomains, contains('supabase.co'));
      });
    });

    group('validation limits', () {
      test('should have max name length', () {
        expect(SecurityConstants.maxNameLength, greaterThan(0));
      });

      test('should have max email length', () {
        expect(SecurityConstants.maxEmailLength, greaterThan(0));
        expect(SecurityConstants.maxEmailLength, 254); // RFC 5321
      });

      test('should have max text length', () {
        expect(SecurityConstants.maxTextLength, greaterThan(0));
      });

      test('should have max URL length', () {
        expect(SecurityConstants.maxUrlLength, greaterThan(0));
        expect(SecurityConstants.maxUrlLength, 2048);
      });
    });
  });

  group('IncomeType', () {
    test('should have fixed and variable types', () {
      expect(IncomeType.values.length, 2);
      expect(IncomeType.fixed, isNotNull);
      expect(IncomeType.variable, isNotNull);
    });

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

    test('fromString should return fixed for unknown', () {
      expect(IncomeType.fromString('unknown'), IncomeType.fixed);
    });
  });

  group('StatsPeriod', () {
    test('should have 4 periods', () {
      expect(StatsPeriod.values.length, 4);
    });

    test('should have correct labels', () {
      expect(StatsPeriod.day.label, 'Jour');
      expect(StatsPeriod.week.label, 'Semaine');
      expect(StatsPeriod.month.label, 'Mois');
      expect(StatsPeriod.year.label, 'Année');
    });
  });

  group('InsightType', () {
    test('should have 4 types', () {
      expect(InsightType.values.length, 4);
    });

    test('should have correct values', () {
      expect(InsightType.warning.value, 'warning');
      expect(InsightType.tip.value, 'tip');
      expect(InsightType.achievement.value, 'achievement');
      expect(InsightType.prediction.value, 'prediction');
    });
  });
}
