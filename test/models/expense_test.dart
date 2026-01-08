import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/expense.dart';
import 'package:smartspend/data/models/category.dart';

void main() {
  group('Expense', () {
    final now = DateTime.now();
    final testExpense = Expense(
      id: 'test-id',
      userId: 'user-123',
      categoryId: 'cat-1',
      amount: 25.50,
      note: 'Test expense',
      expenseDate: now,
      isRecurring: false,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create Expense from valid JSON', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'category_id': 'cat-1',
          'amount': 25.50,
          'note': 'Test expense',
          'expense_date': '2024-01-15',
          'is_recurring': false,
          'recurring_frequency': null,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final expense = Expense.fromJson(json);

        expect(expense.id, 'test-id');
        expect(expense.userId, 'user-123');
        expect(expense.categoryId, 'cat-1');
        expect(expense.amount, 25.50);
        expect(expense.note, 'Test expense');
        expect(expense.isRecurring, false);
      });

      test('should handle JSON with category', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'category_id': 'cat-1',
          'amount': 50.0,
          'note': null,
          'expense_date': '2024-01-15',
          'is_recurring': false,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
          'categories': {
            'id': 'cat-1',
            'user_id': 'user-123',
            'name': 'Alimentation',
            'icon': 'restaurant',
            'color': '#FF5722',
            'is_default': true,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          },
        };

        final expense = Expense.fromJson(json);

        expect(expense.category, isNotNull);
        expect(expense.category!.name, 'Alimentation');
      });

      test('should handle integer amount', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-123',
          'amount': 100,
          'expense_date': '2024-01-15',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final expense = Expense.fromJson(json);

        expect(expense.amount, 100.0);
        expect(expense.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('should convert Expense to JSON', () {
        final expense = Expense(
          id: 'test-id',
          userId: 'user-123',
          categoryId: 'cat-1',
          amount: 25.50,
          note: 'Test note',
          expenseDate: DateTime(2024, 1, 15),
          isRecurring: true,
          recurringFrequency: 'monthly',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final json = expense.toJson();

        expect(json['user_id'], 'user-123');
        expect(json['category_id'], 'cat-1');
        expect(json['amount'], 25.50);
        expect(json['note'], 'Test note');
        expect(json['expense_date'], '2024-01-15');
        expect(json['is_recurring'], true);
        expect(json['recurring_frequency'], 'monthly');
      });
    });

    group('copyWith', () {
      test('should create copy with updated amount', () {
        final copy = testExpense.copyWith(amount: 50.0);

        expect(copy.amount, 50.0);
        expect(copy.id, testExpense.id);
        expect(copy.userId, testExpense.userId);
        expect(copy.note, testExpense.note);
      });

      test('should create copy with multiple updates', () {
        final newDate = DateTime(2024, 2, 1);
        final copy = testExpense.copyWith(
          amount: 100.0,
          note: 'Updated note',
          expenseDate: newDate,
        );

        expect(copy.amount, 100.0);
        expect(copy.note, 'Updated note');
        expect(copy.expenseDate, newDate);
        expect(copy.id, testExpense.id);
      });
    });

    group('isToday', () {
      test('should return true for today expense', () {
        final todayExpense = Expense(
          id: 'test',
          userId: 'user',
          amount: 10.0,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(todayExpense.isToday, true);
      });

      test('should return false for yesterday expense', () {
        final yesterdayExpense = Expense(
          id: 'test',
          userId: 'user',
          amount: 10.0,
          expenseDate: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(yesterdayExpense.isToday, false);
      });
    });

    group('isThisMonth', () {
      test('should return true for current month expense', () {
        final thisMonthExpense = Expense(
          id: 'test',
          userId: 'user',
          amount: 10.0,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(thisMonthExpense.isThisMonth, true);
      });

      test('should return false for last month expense', () {
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);
        final lastMonthExpense = Expense(
          id: 'test',
          userId: 'user',
          amount: 10.0,
          expenseDate: lastMonth,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(lastMonthExpense.isThisMonth, false);
      });
    });

    group('equality', () {
      test('should be equal for same id and properties', () {
        final expense1 = Expense(
          id: 'same-id',
          userId: 'user',
          amount: 10.0,
          expenseDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );
        final expense2 = Expense(
          id: 'same-id',
          userId: 'user',
          amount: 10.0,
          expenseDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        expect(expense1, equals(expense2));
      });
    });
  });
}
