import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/services/local_storage_service.dart';
import 'package:smartspend/services/bill_reminder_service.dart';
import 'package:smartspend/data/models/bill_reminder.dart';

void main() {
  group('BillReminderService', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values for each test
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
    });

    BillReminder createTestReminder({
      String? id,
      String? title,
      double? amount,
      DateTime? dueDate,
      ReminderFrequency? frequency,
      bool? isActive,
      bool? isPaid,
    }) {
      return BillReminder(
        id: id ?? 'test-id-1',
        userId: 'user-123',
        title: title ?? 'Test Bill',
        description: 'Test description',
        amount: amount ?? 50.0,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
        frequency: frequency ?? ReminderFrequency.monthly,
        reminderDaysBefore: 3,
        isActive: isActive ?? true,
        isPaid: isPaid ?? false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Helper to add reminders without triggering notifications
    Future<void> addReminderSafely(BillReminder reminder) async {
      try {
        await BillReminderService.addReminder(reminder);
      } catch (_) {
        // Notification service may fail in test environment
      }
    }

    group('getAllReminders', () {
      test('should return empty list initially', () {
        final reminders = BillReminderService.getAllReminders();
        expect(reminders, isEmpty);
      });
    });

    group('addReminder', () {
      test('should add a reminder', () async {
        final reminder = createTestReminder();

        await addReminderSafely(reminder);

        final reminders = BillReminderService.getAllReminders();
        expect(reminders.length, 1);
        expect(reminders.first.title, 'Test Bill');
      });
    });

    group('getReminderById', () {
      test('should return reminder when exists', () async {
        final reminder = createTestReminder(id: 'find-me', title: 'Find Me');

        await addReminderSafely(reminder);

        final found = BillReminderService.getReminderById('find-me');
        expect(found, isNotNull);
        expect(found?.title, 'Find Me');
      });

      test('should return null when not found', () {
        final found = BillReminderService.getReminderById('nonexistent');
        expect(found, isNull);
      });
    });

    group('getActiveReminders', () {
      test('should return only active unpaid reminders', () async {
        final activeUnpaid = createTestReminder(
          id: 'active-1',
          isActive: true,
          isPaid: false,
        );

        await addReminderSafely(activeUnpaid);

        final active = BillReminderService.getActiveReminders();
        expect(active.length, 1);
        expect(active.first.id, 'active-1');
      });

      test('should exclude paid reminders', () async {
        final activePaid = createTestReminder(
          id: 'active-2',
          isActive: true,
          isPaid: true,
        );

        await addReminderSafely(activePaid);

        final active = BillReminderService.getActiveReminders();
        expect(active, isEmpty);
      });

      test('should exclude inactive reminders', () async {
        final inactiveUnpaid = createTestReminder(
          id: 'inactive',
          isActive: false,
          isPaid: false,
        );

        await addReminderSafely(inactiveUnpaid);

        final active = BillReminderService.getActiveReminders();
        expect(active, isEmpty);
      });
    });

    group('getOverdueReminders', () {
      test('should return overdue reminders', () async {
        final overdue = createTestReminder(
          id: 'overdue',
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        await addReminderSafely(overdue);

        final overdueList = BillReminderService.getOverdueReminders();
        expect(overdueList.length, 1);
        expect(overdueList.first.id, 'overdue');
      });

      test('should not return future reminders as overdue', () async {
        final futureReminder = createTestReminder(
          id: 'future',
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        await addReminderSafely(futureReminder);

        final overdueList = BillReminderService.getOverdueReminders();
        expect(overdueList, isEmpty);
      });
    });

    group('getUpcomingReminders', () {
      test('should return reminders within specified days', () async {
        final within7 = createTestReminder(
          id: 'within-7',
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        await addReminderSafely(within7);

        final upcoming = BillReminderService.getUpcomingReminders(days: 7);
        expect(upcoming.length, 1);
        expect(upcoming.first.id, 'within-7');
      });

      test('should not return reminders beyond specified days', () async {
        final beyond7 = createTestReminder(
          id: 'beyond-7',
          dueDate: DateTime.now().add(const Duration(days: 10)),
        );

        await addReminderSafely(beyond7);

        final upcoming = BillReminderService.getUpcomingReminders(days: 7);
        expect(upcoming, isEmpty);
      });
    });

    group('getTotalUpcoming', () {
      test('should calculate total of a single upcoming reminder', () async {
        final reminder = createTestReminder(
          id: 'r1',
          amount: 75.50,
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        await addReminderSafely(reminder);

        final total = BillReminderService.getTotalUpcoming(days: 30);
        expect(total, 75.50);
      });
    });

    group('getTotalOverdue', () {
      test('should calculate total of a single overdue reminder', () async {
        final overdue = createTestReminder(
          id: 'o1',
          amount: 125.00,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        await addReminderSafely(overdue);

        final total = BillReminderService.getTotalOverdue();
        expect(total, 125.00);
      });

      test('should not include future reminders in overdue total', () async {
        final futureReminder = createTestReminder(
          id: 'future',
          amount: 200.0,
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        await addReminderSafely(futureReminder);

        final total = BillReminderService.getTotalOverdue();
        expect(total, 0.0);
      });
    });
  });
}
