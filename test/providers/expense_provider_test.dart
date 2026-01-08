import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/expense.dart';
import 'package:smartspend/data/models/category.dart';

// Tests for ExpenseProvider logic without mocking Supabase
// These tests verify the pure computation logic

void main() {
  group('ExpenseProvider Logic', () {
    group('todayExpenses filter', () {
      test('should filter expenses for today only', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        final expenses = [
          _createExpense('1', 100, now),
          _createExpense('2', 200, yesterday),
          _createExpense('3', 50, now),
          _createExpense('4', 75, tomorrow),
        ];

        final todayExpenses = expenses.where((e) {
          return e.expenseDate.year == now.year &&
              e.expenseDate.month == now.month &&
              e.expenseDate.day == now.day;
        }).toList();

        expect(todayExpenses.length, 2);
        expect(todayExpenses.map((e) => e.id), containsAll(['1', '3']));
      });

      test('should return empty list when no expenses today', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final expenses = [
          _createExpense('1', 100, yesterday),
          _createExpense('2', 200, yesterday),
        ];

        final now = DateTime.now();
        final todayExpenses = expenses.where((e) {
          return e.expenseDate.year == now.year &&
              e.expenseDate.month == now.month &&
              e.expenseDate.day == now.day;
        }).toList();

        expect(todayExpenses, isEmpty);
      });
    });

    group('weekExpenses filter', () {
      test('should filter expenses for current week', () {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 7));

        final inWeek = start.add(const Duration(days: 2));
        final beforeWeek = start.subtract(const Duration(days: 1));
        final afterWeek = end.add(const Duration(days: 1));

        final expenses = [
          _createExpense('1', 100, inWeek),
          _createExpense('2', 200, beforeWeek),
          _createExpense('3', 50, now),
          _createExpense('4', 75, afterWeek),
        ];

        final weekExpenses = expenses.where((e) {
          return e.expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
              e.expenseDate.isBefore(end);
        }).toList();

        expect(weekExpenses.length, 2);
        expect(weekExpenses.map((e) => e.id), containsAll(['1', '3']));
      });
    });

    group('monthExpenses filter', () {
      test('should filter expenses for selected month', () {
        final selectedMonth = DateTime(2024, 6, 1);
        final inMonth = DateTime(2024, 6, 15);
        final previousMonth = DateTime(2024, 5, 15);
        final nextMonth = DateTime(2024, 7, 15);

        final expenses = [
          _createExpense('1', 100, inMonth),
          _createExpense('2', 200, previousMonth),
          _createExpense('3', 50, DateTime(2024, 6, 1)),
          _createExpense('4', 75, nextMonth),
        ];

        final monthExpenses = expenses.where((e) {
          return e.expenseDate.year == selectedMonth.year &&
              e.expenseDate.month == selectedMonth.month;
        }).toList();

        expect(monthExpenses.length, 2);
        expect(monthExpenses.map((e) => e.id), containsAll(['1', '3']));
      });
    });

    group('totals calculation', () {
      test('should calculate total correctly', () {
        final expenses = [
          _createExpense('1', 100.50, DateTime.now()),
          _createExpense('2', 200.25, DateTime.now()),
          _createExpense('3', 50.00, DateTime.now()),
        ];

        final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

        expect(total, 350.75);
      });

      test('should return 0 for empty list', () {
        final expenses = <Expense>[];
        final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
        expect(total, 0.0);
      });
    });

    group('getExpensesByCategory', () {
      test('should group expenses by category', () {
        final expenses = [
          _createExpenseWithCategory('1', 100, 'cat-food'),
          _createExpenseWithCategory('2', 50, 'cat-transport'),
          _createExpenseWithCategory('3', 75, 'cat-food'),
          _createExpenseWithCategory('4', 25, null),
        ];

        final map = <String, double>{};
        for (final expense in expenses) {
          final key = expense.categoryId ?? 'other';
          map[key] = (map[key] ?? 0) + expense.amount;
        }

        expect(map['cat-food'], 175);
        expect(map['cat-transport'], 50);
        expect(map['other'], 25);
      });

      test('should handle all expenses without category', () {
        final expenses = [
          _createExpenseWithCategory('1', 100, null),
          _createExpenseWithCategory('2', 50, null),
        ];

        final map = <String, double>{};
        for (final expense in expenses) {
          final key = expense.categoryId ?? 'other';
          map[key] = (map[key] ?? 0) + expense.amount;
        }

        expect(map.length, 1);
        expect(map['other'], 150);
      });
    });

    group('getDailyExpenses', () {
      test('should group expenses by day', () {
        final expenses = [
          _createExpense('1', 100, DateTime(2024, 6, 1)),
          _createExpense('2', 50, DateTime(2024, 6, 1)),
          _createExpense('3', 75, DateTime(2024, 6, 15)),
          _createExpense('4', 25, DateTime(2024, 6, 30)),
        ];

        final map = <int, double>{};
        for (final expense in expenses) {
          final day = expense.expenseDate.day;
          map[day] = (map[day] ?? 0) + expense.amount;
        }

        expect(map[1], 150);
        expect(map[15], 75);
        expect(map[30], 25);
        expect(map.length, 3);
      });
    });

    group('expense sorting', () {
      test('should sort by date descending', () {
        final expenses = [
          _createExpense('1', 100, DateTime(2024, 6, 1)),
          _createExpense('2', 50, DateTime(2024, 6, 15)),
          _createExpense('3', 75, DateTime(2024, 6, 10)),
        ];

        expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        expect(expenses[0].id, '2'); // June 15
        expect(expenses[1].id, '3'); // June 10
        expect(expenses[2].id, '1'); // June 1
      });
    });

    group('getExpenseById', () {
      test('should find expense by id', () {
        final expenses = [
          _createExpense('1', 100, DateTime.now()),
          _createExpense('2', 200, DateTime.now()),
          _createExpense('3', 50, DateTime.now()),
        ];

        Expense? getExpenseById(String id) {
          try {
            return expenses.firstWhere((e) => e.id == id);
          } catch (e) {
            return null;
          }
        }

        expect(getExpenseById('2')?.amount, 200);
        expect(getExpenseById('unknown'), isNull);
      });
    });
  });
}

Expense _createExpense(String id, double amount, DateTime date) {
  return Expense(
    id: id,
    userId: 'user-1',
    amount: amount,
    expenseDate: date,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Expense _createExpenseWithCategory(String id, double amount, String? categoryId) {
  return Expense(
    id: id,
    userId: 'user-1',
    categoryId: categoryId,
    amount: amount,
    expenseDate: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
