import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('app info', () {
      test('should have app name', () {
        expect(AppConfig.appName, 'SmartSpend');
      });

      test('should have version', () {
        expect(AppConfig.version, isNotEmpty);
        expect(AppConfig.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      });
    });

    group('currency', () {
      test('should have EUR as default currency', () {
        expect(AppConfig.defaultCurrency, 'EUR');
      });

      test('should have currency symbols map', () {
        expect(AppConfig.currencySymbols, isNotEmpty);
        expect(AppConfig.currencySymbols['EUR'], '€');
        expect(AppConfig.currencySymbols['USD'], '\$');
        expect(AppConfig.currencySymbols['GBP'], '£');
      });

      test('should have symbol for default currency', () {
        expect(
          AppConfig.currencySymbols[AppConfig.defaultCurrency],
          isNotNull,
        );
      });

      test('should have at least 5 supported currencies', () {
        expect(AppConfig.currencySymbols.length, greaterThanOrEqualTo(5));
      });
    });

    group('budget settings', () {
      test('should have default alert threshold between 0 and 100', () {
        expect(AppConfig.defaultBudgetAlertThreshold, greaterThan(0));
        expect(AppConfig.defaultBudgetAlertThreshold, lessThanOrEqualTo(100));
      });

      test('default alert threshold should be 80%', () {
        expect(AppConfig.defaultBudgetAlertThreshold, 80);
      });
    });

    group('free tier limits', () {
      test('should have freeMaxGoals defined', () {
        expect(AppConfig.freeMaxGoals, greaterThan(0));
      });
    });

    group('premium pricing', () {
      test('should have monthly price', () {
        expect(AppConfig.premiumMonthlyPrice, greaterThan(0));
      });

      test('should have yearly price', () {
        expect(AppConfig.premiumYearlyPrice, greaterThan(0));
      });

      test('yearly price should be less than 12x monthly', () {
        final yearlyFromMonthly = AppConfig.premiumMonthlyPrice * 12;
        expect(AppConfig.premiumYearlyPrice, lessThan(yearlyFromMonthly));
      });
    });

    group('animation durations', () {
      test('should have fast animation duration', () {
        expect(AppConfig.animationFast, greaterThan(0));
        expect(AppConfig.animationFast, lessThan(500));
      });

      test('should have normal animation duration', () {
        expect(AppConfig.animationNormal, greaterThan(AppConfig.animationFast));
        expect(AppConfig.animationNormal, lessThan(1000));
      });

      test('should have slow animation duration', () {
        expect(AppConfig.animationSlow, greaterThan(AppConfig.animationNormal));
      });

      test('animation durations should be in order', () {
        expect(AppConfig.animationFast, lessThan(AppConfig.animationNormal));
        expect(AppConfig.animationNormal, lessThan(AppConfig.animationSlow));
      });
    });

    group('URLs', () {
      test('should have privacy policy URL', () {
        expect(AppConfig.privacyPolicyUrl, isNotEmpty);
        expect(AppConfig.privacyPolicyUrl, startsWith('https://'));
      });

      test('should have terms of service URL', () {
        expect(AppConfig.termsOfServiceUrl, isNotEmpty);
        expect(AppConfig.termsOfServiceUrl, startsWith('https://'));
      });

      test('should have support URL', () {
        expect(AppConfig.supportUrl, isNotEmpty);
        expect(AppConfig.supportUrl, startsWith('https://'));
      });

      test('should have support email', () {
        expect(AppConfig.supportEmail, isNotEmpty);
        expect(AppConfig.supportEmail, contains('@'));
      });
    });
  });
}
