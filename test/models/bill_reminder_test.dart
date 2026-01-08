import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/bill_reminder.dart';

void main() {
  group('BillReminder', () {
    final now = DateTime.now();
    final testReminder = BillReminder(
      id: 'bill-1',
      userId: 'user-123',
      title: 'Electricity Bill',
      description: 'Monthly electricity',
      amount: 85.50,
      dueDate: now.add(const Duration(days: 7)),
      frequency: ReminderFrequency.monthly,
      reminderDaysBefore: 3,
      isActive: true,
      isPaid: false,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create BillReminder from valid JSON', () {
        final json = {
          'id': 'bill-1',
          'user_id': 'user-123',
          'title': 'Internet',
          'description': 'Monthly internet bill',
          'amount': 45.99,
          'due_date': '2024-02-15T00:00:00.000Z',
          'frequency': 'monthly',
          'reminder_days_before': 5,
          'is_active': true,
          'is_paid': false,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };

        final reminder = BillReminder.fromJson(json);

        expect(reminder.id, 'bill-1');
        expect(reminder.title, 'Internet');
        expect(reminder.amount, 45.99);
        expect(reminder.frequency, ReminderFrequency.monthly);
        expect(reminder.reminderDaysBefore, 5);
      });

      test('should handle all frequency types', () {
        for (final freq in ReminderFrequency.values) {
          final json = {
            'id': 'bill-1',
            'user_id': 'user-123',
            'title': 'Test',
            'amount': 10.0,
            'due_date': '2024-02-15T00:00:00.000Z',
            'frequency': freq.name,
            'reminder_days_before': 1,
            'is_active': true,
            'is_paid': false,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          };

          final reminder = BillReminder.fromJson(json);
          expect(reminder.frequency, freq);
        }
      });
    });

    group('toJson', () {
      test('should convert BillReminder to JSON', () {
        final json = testReminder.toJson();

        expect(json['title'], 'Electricity Bill');
        expect(json['description'], 'Monthly electricity');
        expect(json['amount'], 85.50);
        expect(json['frequency'], 'monthly');
        expect(json['reminder_days_before'], 3);
        expect(json['is_active'], true);
        expect(json['is_paid'], false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated amount', () {
        final copy = testReminder.copyWith(amount: 100.0);

        expect(copy.amount, 100.0);
        expect(copy.title, testReminder.title);
        expect(copy.frequency, testReminder.frequency);
      });

      test('should create copy marking as paid', () {
        final copy = testReminder.copyWith(isPaid: true);

        expect(copy.isPaid, true);
        expect(copy.title, testReminder.title);
      });
    });

    group('isOverdue', () {
      test('should return true for past due date', () {
        final overdueReminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(overdueReminder.isOverdue, true);
      });

      test('should return false for future due date', () {
        final futureReminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().add(const Duration(days: 10)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(futureReminder.isOverdue, false);
      });

      test('should return false for paid bill', () {
        final paidReminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(paidReminder.isOverdue, false);
      });
    });

    group('daysUntilDue', () {
      test('should return positive days for future date', () {
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(reminder.daysUntilDue, 5);
      });

      test('should return negative days for past date', () {
        final now = DateTime.now();
        // Créer une date à minuit pour éviter les problèmes de timing
        final pastDate = DateTime(now.year, now.month, now.day - 3);
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: pastDate,
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(reminder.daysUntilDue, -3);
      });
    });

    group('nextDueDate', () {
      test('should return same date for one-time reminder', () {
        final dueDate = DateTime.now().add(const Duration(days: 10));
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: dueDate,
          frequency: ReminderFrequency.once,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(reminder.nextDueDate.day, dueDate.day);
        expect(reminder.nextDueDate.month, dueDate.month);
        expect(reminder.nextDueDate.year, dueDate.year);
      });

      test('should calculate next date for recurring reminder', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: pastDate,
          frequency: ReminderFrequency.weekly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // La prochaine date devrait être dans le futur
        expect(reminder.nextDueDate.isAfter(DateTime.now()), isTrue);
      });
    });

    group('shouldRemindToday', () {
      test('should return false when paid', () {
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().add(const Duration(days: 3)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: true,
          isPaid: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(reminder.shouldRemindToday, false);
      });

      test('should return false when inactive', () {
        final reminder = BillReminder(
          id: 'bill-1',
          userId: 'user-123',
          title: 'Test',
          amount: 50.0,
          dueDate: DateTime.now().add(const Duration(days: 3)),
          frequency: ReminderFrequency.monthly,
          reminderDaysBefore: 3,
          isActive: false,
          isPaid: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(reminder.shouldRemindToday, false);
      });
    });
  });

  group('ReminderFrequency', () {
    test('should have correct labels', () {
      expect(ReminderFrequency.once.label, 'Une fois');
      expect(ReminderFrequency.daily.label, 'Quotidien');
      expect(ReminderFrequency.weekly.label, 'Hebdomadaire');
      expect(ReminderFrequency.monthly.label, 'Mensuel');
      expect(ReminderFrequency.yearly.label, 'Annuel');
    });

    test('should have correct descriptions', () {
      expect(ReminderFrequency.once.description, 'Rappel unique');
      expect(ReminderFrequency.monthly.description, 'Répéter chaque mois');
    });

    test('should parse from string', () {
      expect(
        ReminderFrequency.values.firstWhere((f) => f.name == 'monthly'),
        ReminderFrequency.monthly,
      );
    });
  });
}
