import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/core/utils/formatters.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('Formatters', () {
    group('currency', () {
      test('should format amount with EUR symbol by default', () {
        final result = Formatters.currency(1234.56);
        expect(result, contains('€'));
        expect(result, contains('1'));
        expect(result, contains('234'));
      });

      test('should format amount with specified currency', () {
        final usd = Formatters.currency(100.0, currency: 'USD');
        expect(usd, contains('\$'));

        final gbp = Formatters.currency(100.0, currency: 'GBP');
        expect(gbp, contains('£'));
      });

      test('should format zero amount', () {
        final result = Formatters.currency(0);
        expect(result, contains('0'));
        expect(result, contains('€'));
      });

      test('should format negative amount', () {
        final result = Formatters.currency(-50.0);
        expect(result, contains('50'));
      });
    });

    group('currencyCompact', () {
      test('should format millions with M suffix', () {
        final result = Formatters.currencyCompact(1500000);
        expect(result, '1.5M€');
      });

      test('should format thousands with k suffix', () {
        final result = Formatters.currencyCompact(1500);
        expect(result, '1.5k€');
      });

      test('should use regular format for small amounts', () {
        final result = Formatters.currencyCompact(500);
        expect(result, contains('€'));
        expect(result, contains('500'));
      });

      test('should handle edge cases', () {
        expect(Formatters.currencyCompact(1000000), '1.0M€');
        expect(Formatters.currencyCompact(1000), '1.0k€');
        expect(Formatters.currencyCompact(999), contains('999'));
      });
    });

    group('dateShort', () {
      test('should format date as dd/MM', () {
        final date = DateTime(2024, 3, 15);
        expect(Formatters.dateShort(date), '15/03');
      });

      test('should pad single digit day and month', () {
        final date = DateTime(2024, 1, 5);
        expect(Formatters.dateShort(date), '05/01');
      });
    });

    group('dateMedium', () {
      test('should format date as dd MMM in French', () {
        final date = DateTime(2024, 3, 15);
        final result = Formatters.dateMedium(date);
        expect(result, contains('15'));
        // Month should be abbreviated in French
      });
    });

    group('dateFull', () {
      test('should format date as dd MMMM yyyy in French', () {
        final date = DateTime(2024, 3, 15);
        final result = Formatters.dateFull(date);
        expect(result, contains('15'));
        expect(result, contains('2024'));
      });
    });

    group('month', () {
      test('should format as MMMM yyyy in French', () {
        final date = DateTime(2024, 3, 15);
        final result = Formatters.month(date);
        expect(result, contains('2024'));
      });
    });

    group('dateRelative', () {
      test('should return Aujourd\'hui for today', () {
        final today = DateTime.now();
        expect(Formatters.dateRelative(today), 'Aujourd\'hui');
      });

      test('should return Hier for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(Formatters.dateRelative(yesterday), 'Hier');
      });

      test('should return dd MMM for same year dates', () {
        final now = DateTime.now();
        // Use a date from 10 days ago (same year)
        final pastDate = now.subtract(const Duration(days: 10));
        if (pastDate.year == now.year) {
          final result = Formatters.dateRelative(pastDate);
          expect(result, isNot('Aujourd\'hui'));
          expect(result, isNot('Hier'));
          // Should contain day number
          expect(result, contains(pastDate.day.toString().padLeft(2, '0')));
        }
      });

      test('should return dd/MM/yyyy for different year dates', () {
        final pastYear = DateTime(DateTime.now().year - 1, 6, 15);
        final result = Formatters.dateRelative(pastYear);
        expect(result, contains('/'));
        expect(result, contains((DateTime.now().year - 1).toString()));
      });
    });

    group('percentage', () {
      test('should format percentage without decimals by default', () {
        expect(Formatters.percentage(75.5), '76%');
        expect(Formatters.percentage(50.0), '50%');
      });

      test('should format percentage with specified decimals', () {
        expect(Formatters.percentage(75.5, decimals: 1), '75.5%');
        expect(Formatters.percentage(33.333, decimals: 2), '33.33%');
      });

      test('should handle zero percentage', () {
        expect(Formatters.percentage(0), '0%');
      });

      test('should handle 100 percentage', () {
        expect(Formatters.percentage(100), '100%');
      });
    });

    group('number', () {
      test('should format number with French separators', () {
        final result = Formatters.number(1234567);
        // French format uses space as thousands separator
        expect(result.replaceAll('\u00A0', ' '), contains('1'));
        expect(result, contains('234'));
        expect(result, contains('567'));
      });

      test('should format small numbers', () {
        expect(Formatters.number(42), '42');
        expect(Formatters.number(999), '999');
      });

      test('should format decimal numbers', () {
        final result = Formatters.number(1234.56);
        expect(result, contains('1'));
        expect(result, contains('234'));
      });
    });
  });
}
