import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/income.dart';

void main() {
  group('IncomeType', () {
    test('should have correct values for all types', () {
      expect(IncomeType.salary.value, 'salary');
      expect(IncomeType.freelance.value, 'freelance');
      expect(IncomeType.rental.value, 'rental');
      expect(IncomeType.investment.value, 'investment');
      expect(IncomeType.gift.value, 'gift');
      expect(IncomeType.refund.value, 'refund');
      expect(IncomeType.bonus.value, 'bonus');
      expect(IncomeType.pension.value, 'pension');
      expect(IncomeType.allowance.value, 'allowance');
      expect(IncomeType.other.value, 'other');
    });

    test('should have labels for all types', () {
      expect(IncomeType.salary.label, 'Salaire');
      expect(IncomeType.freelance.label, 'Freelance');
      expect(IncomeType.rental.label, 'Location');
      expect(IncomeType.bonus.label, 'Prime');
    });

    test('should have emojis for all types', () {
      for (final type in IncomeType.values) {
        expect(type.emoji, isNotEmpty);
      }
    });

    test('fromString should return correct type', () {
      expect(IncomeType.fromString('salary'), IncomeType.salary);
      expect(IncomeType.fromString('freelance'), IncomeType.freelance);
      expect(IncomeType.fromString('rental'), IncomeType.rental);
      expect(IncomeType.fromString('investment'), IncomeType.investment);
      expect(IncomeType.fromString('gift'), IncomeType.gift);
      expect(IncomeType.fromString('bonus'), IncomeType.bonus);
    });

    test('fromString should return other for unknown value', () {
      expect(IncomeType.fromString('unknown'), IncomeType.other);
      expect(IncomeType.fromString(''), IncomeType.other);
      expect(IncomeType.fromString('invalid'), IncomeType.other);
    });
  });

  group('IncomeFrequency', () {
    test('should have correct values for all frequencies', () {
      expect(IncomeFrequency.once.value, 'once');
      expect(IncomeFrequency.weekly.value, 'weekly');
      expect(IncomeFrequency.biweekly.value, 'biweekly');
      expect(IncomeFrequency.monthly.value, 'monthly');
      expect(IncomeFrequency.quarterly.value, 'quarterly');
      expect(IncomeFrequency.yearly.value, 'yearly');
    });

    test('should have labels for all frequencies', () {
      expect(IncomeFrequency.once.label, 'Unique');
      expect(IncomeFrequency.weekly.label, 'Hebdomadaire');
      expect(IncomeFrequency.monthly.label, 'Mensuel');
      expect(IncomeFrequency.yearly.label, 'Annuel');
    });

    test('fromString should return correct frequency', () {
      expect(IncomeFrequency.fromString('once'), IncomeFrequency.once);
      expect(IncomeFrequency.fromString('weekly'), IncomeFrequency.weekly);
      expect(IncomeFrequency.fromString('monthly'), IncomeFrequency.monthly);
      expect(IncomeFrequency.fromString('yearly'), IncomeFrequency.yearly);
    });

    test('fromString should return once for unknown value', () {
      expect(IncomeFrequency.fromString('unknown'), IncomeFrequency.once);
      expect(IncomeFrequency.fromString(''), IncomeFrequency.once);
    });
  });

  group('Income', () {
    final now = DateTime.now();
    final testIncome = Income(
      id: 'income-123',
      userId: 'user-456',
      accountId: 'acc-789',
      amount: 3000.0,
      type: IncomeType.salary,
      source: 'Mon Entreprise',
      note: 'Salaire mensuel',
      date: DateTime(2024, 1, 15),
      isRecurring: true,
      frequency: IncomeFrequency.monthly,
      isConfirmed: true,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create Income from valid JSON', () {
        final json = {
          'id': 'income-123',
          'user_id': 'user-456',
          'account_id': 'acc-789',
          'amount': 3000.0,
          'type': 'salary',
          'source': 'Mon Entreprise',
          'note': 'Salaire mensuel',
          'date': '2024-01-15',
          'is_recurring': true,
          'frequency': 'monthly',
          'next_occurrence': '2024-02-15',
          'is_confirmed': true,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final income = Income.fromJson(json);

        expect(income.id, 'income-123');
        expect(income.userId, 'user-456');
        expect(income.accountId, 'acc-789');
        expect(income.amount, 3000.0);
        expect(income.type, IncomeType.salary);
        expect(income.source, 'Mon Entreprise');
        expect(income.isRecurring, true);
        expect(income.frequency, IncomeFrequency.monthly);
        expect(income.nextOccurrence, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'income-123',
          'user_id': 'user-456',
          'amount': 500.0,
          'date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final income = Income.fromJson(json);

        expect(income.accountId, isNull);
        expect(income.source, isNull);
        expect(income.note, isNull);
        expect(income.nextOccurrence, isNull);
        expect(income.isRecurring, false);
        expect(income.frequency, IncomeFrequency.once);
        expect(income.type, IncomeType.other);
        expect(income.isConfirmed, true);
      });

      test('should handle integer amount', () {
        final json = {
          'id': 'income-123',
          'user_id': 'user-456',
          'amount': 2500,
          'date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final income = Income.fromJson(json);

        expect(income.amount, 2500.0);
        expect(income.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('should convert Income to JSON', () {
        final json = testIncome.toJson();

        expect(json['id'], 'income-123');
        expect(json['user_id'], 'user-456');
        expect(json['account_id'], 'acc-789');
        expect(json['amount'], 3000.0);
        expect(json['type'], 'salary');
        expect(json['source'], 'Mon Entreprise');
        expect(json['note'], 'Salaire mensuel');
        expect(json['is_recurring'], true);
        expect(json['frequency'], 'monthly');
        expect(json['is_confirmed'], true);
      });

      test('should format date as date only', () {
        final json = testIncome.toJson();

        expect(json['date'], '2024-01-15');
        expect(json['date'], isNot(contains('T')));
      });

      test('should handle null nextOccurrence', () {
        final incomeWithoutNext = testIncome.copyWith(isRecurring: false);
        final json = incomeWithoutNext.toJson();

        expect(json['next_occurrence'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated amount', () {
        final copy = testIncome.copyWith(amount: 3500.0);

        expect(copy.amount, 3500.0);
        expect(copy.id, testIncome.id);
        expect(copy.type, testIncome.type);
      });

      test('should create copy with updated type', () {
        final copy = testIncome.copyWith(type: IncomeType.bonus);

        expect(copy.type, IncomeType.bonus);
        expect(copy.amount, testIncome.amount);
      });

      test('should create copy with multiple updates', () {
        final copy = testIncome.copyWith(
          amount: 5000.0,
          type: IncomeType.freelance,
          source: 'Client XYZ',
          isRecurring: false,
        );

        expect(copy.amount, 5000.0);
        expect(copy.type, IncomeType.freelance);
        expect(copy.source, 'Client XYZ');
        expect(copy.isRecurring, false);
        expect(copy.id, testIncome.id);
      });
    });

    group('displayName', () {
      test('should return source when available', () {
        expect(testIncome.displayName, 'Mon Entreprise');
      });

      test('should return type label when no source', () {
        final incomeWithoutSource = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 1000.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          createdAt: now,
          updatedAt: now,
        );

        expect(incomeWithoutSource.displayName, 'Salaire');
      });
    });

    group('monthlyAmount', () {
      test('should return amount for monthly frequency', () {
        expect(testIncome.monthlyAmount, 3000.0);
      });

      test('should calculate for weekly frequency', () {
        final weeklyIncome = testIncome.copyWith(
          frequency: IncomeFrequency.weekly,
          amount: 500.0,
        );
        // 500 * 4.33 = 2165
        expect(weeklyIncome.monthlyAmount, closeTo(2165.0, 1.0));
      });

      test('should calculate for biweekly frequency', () {
        final biweeklyIncome = testIncome.copyWith(
          frequency: IncomeFrequency.biweekly,
          amount: 1500.0,
        );
        // 1500 * 2.17 = 3255
        expect(biweeklyIncome.monthlyAmount, closeTo(3255.0, 1.0));
      });

      test('should calculate for quarterly frequency', () {
        final quarterlyIncome = testIncome.copyWith(
          frequency: IncomeFrequency.quarterly,
          amount: 3000.0,
        );
        // 3000 / 3 = 1000
        expect(quarterlyIncome.monthlyAmount, 1000.0);
      });

      test('should calculate for yearly frequency', () {
        final yearlyIncome = testIncome.copyWith(
          frequency: IncomeFrequency.yearly,
          amount: 12000.0,
        );
        // 12000 / 12 = 1000
        expect(yearlyIncome.monthlyAmount, 1000.0);
      });

      test('should return 0 for once frequency', () {
        final onceIncome = testIncome.copyWith(
          frequency: IncomeFrequency.once,
          isRecurring: false,
        );
        expect(onceIncome.monthlyAmount, 0.0);
      });
    });

    group('calculateNextOccurrence', () {
      test('should return null for non-recurring income', () {
        final nonRecurring = testIncome.copyWith(isRecurring: false);
        expect(nonRecurring.calculateNextOccurrence(), isNull);
      });

      test('should return null for once frequency', () {
        final onceIncome = testIncome.copyWith(
          frequency: IncomeFrequency.once,
        );
        expect(onceIncome.calculateNextOccurrence(), isNull);
      });

      test('should calculate next occurrence for monthly', () {
        // Create income with date in the past
        final pastDate = DateTime.now().subtract(const Duration(days: 45));
        final monthlyIncome = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.salary,
          date: pastDate,
          isRecurring: true,
          frequency: IncomeFrequency.monthly,
          createdAt: now,
          updatedAt: now,
        );

        final next = monthlyIncome.calculateNextOccurrence();

        expect(next, isNotNull);
        expect(next!.isAfter(DateTime.now()) || next.isAtSameMomentAs(DateTime.now()), true);
      });

      test('should calculate next occurrence for weekly', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final weeklyIncome = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 500.0,
          type: IncomeType.freelance,
          date: pastDate,
          isRecurring: true,
          frequency: IncomeFrequency.weekly,
          createdAt: now,
          updatedAt: now,
        );

        final next = weeklyIncome.calculateNextOccurrence();

        expect(next, isNotNull);
        expect(next!.isAfter(DateTime.now()) || next.isAtSameMomentAs(DateTime.now()), true);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final income1 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          isRecurring: true,
          frequency: IncomeFrequency.monthly,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final income2 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          isRecurring: true,
          frequency: IncomeFrequency.monthly,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(income1, equals(income2));
      });

      test('should not be equal for different amounts', () {
        final income1 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final income2 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3500.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(income1, isNot(equals(income2)));
      });

      test('should not be equal for different types', () {
        final income1 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.salary,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final income2 = Income(
          id: 'income-1',
          userId: 'user-1',
          amount: 3000.0,
          type: IncomeType.bonus,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(income1, isNot(equals(income2)));
      });
    });
  });
}
