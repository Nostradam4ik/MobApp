import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/models/bill_reminder.dart';
import 'notification_service.dart';
import 'local_storage_service.dart';
import 'dart:convert';

/// Service pour gérer les rappels de factures
class BillReminderService {
  BillReminderService._();

  static const String _storageKey = 'bill_reminders';
  static const int _notificationIdBase = 10000;

  /// Récupère tous les rappels de factures
  static List<BillReminder> getAllReminders() {
    final jsonString = LocalStorageService.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => BillReminder.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde tous les rappels
  static Future<void> _saveReminders(List<BillReminder> reminders) async {
    final jsonString = json.encode(reminders.map((r) => r.toJson()).toList());
    await LocalStorageService.setString(_storageKey, jsonString);
  }

  /// Ajoute un nouveau rappel
  static Future<void> addReminder(BillReminder reminder) async {
    final reminders = getAllReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);
    await _scheduleNotification(reminder);
  }

  /// Met à jour un rappel existant
  static Future<void> updateReminder(BillReminder reminder) async {
    final reminders = getAllReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _saveReminders(reminders);
      await _cancelNotification(reminder.id);
      if (reminder.isActive && !reminder.isPaid) {
        await _scheduleNotification(reminder);
      }
    }
  }

  /// Supprime un rappel
  static Future<void> deleteReminder(String id) async {
    final reminders = getAllReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
    await _cancelNotification(id);
  }

  /// Marque un rappel comme payé
  static Future<void> markAsPaid(String id) async {
    final reminders = getAllReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = reminders[index];

      if (reminder.frequency == ReminderFrequency.once) {
        // Pour les rappels uniques, on les marque simplement comme payés
        reminders[index] = reminder.copyWith(
          isPaid: true,
          updatedAt: DateTime.now(),
        );
      } else {
        // Pour les rappels récurrents, on met à jour la date d'échéance
        reminders[index] = reminder.copyWith(
          dueDate: reminder.nextDueDate,
          isPaid: false,
          updatedAt: DateTime.now(),
        );
      }

      await _saveReminders(reminders);
      await _cancelNotification(id);

      if (!reminders[index].isPaid && reminders[index].isActive) {
        await _scheduleNotification(reminders[index]);
      }
    }
  }

  /// Récupère les rappels actifs triés par date d'échéance
  static List<BillReminder> getActiveReminders() {
    final reminders = getAllReminders()
        .where((r) => r.isActive && !r.isPaid)
        .toList();
    reminders.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return reminders;
  }

  /// Récupère les rappels en retard
  static List<BillReminder> getOverdueReminders() {
    return getActiveReminders().where((r) => r.isOverdue).toList();
  }

  /// Récupère les rappels à venir (dans les X prochains jours)
  static List<BillReminder> getUpcomingReminders({int days = 7}) {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    return getActiveReminders()
        .where((r) => r.nextDueDate.isAfter(now) && r.nextDueDate.isBefore(endDate))
        .toList();
  }

  /// Récupère un rappel par ID
  static BillReminder? getReminderById(String id) {
    try {
      return getAllReminders().firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Programme une notification pour un rappel
  static Future<void> _scheduleNotification(BillReminder reminder) async {
    if (!reminder.isActive || reminder.isPaid) return;

    final notificationId = _getNotificationId(reminder.id);
    final reminderDate = reminder.nextDueDate.subtract(
      Duration(days: reminder.reminderDaysBefore),
    );

    // Ne pas programmer de notification dans le passé
    if (reminderDate.isBefore(DateTime.now())) {
      // Si la date est dépassée mais pas la date d'échéance, notifier maintenant
      if (reminder.nextDueDate.isAfter(DateTime.now())) {
        await NotificationService.showNotification(
          id: notificationId,
          title: 'Facture à payer',
          body: '${reminder.title} - ${reminder.amount.toStringAsFixed(2)}€ '
              '(échéance dans ${reminder.daysUntilDue} jours)',
        );
      }
      return;
    }

    // Programmer la notification
    final scheduledDate = tz.TZDateTime.from(
      DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // À 9h du matin
        0,
      ),
      tz.local,
    );

    await NotificationService.scheduleNotification(
      id: notificationId,
      title: 'Rappel de facture',
      body: '${reminder.title} - ${reminder.amount.toStringAsFixed(2)}€ '
          'à payer avant le ${_formatDate(reminder.nextDueDate)}',
      scheduledDate: scheduledDate,
    );
  }

  /// Annule une notification
  static Future<void> _cancelNotification(String reminderId) async {
    final notificationId = _getNotificationId(reminderId);
    await NotificationService.cancelNotification(notificationId);
  }

  /// Génère un ID de notification unique basé sur l'ID du rappel
  static int _getNotificationId(String reminderId) {
    return _notificationIdBase + reminderId.hashCode.abs() % 10000;
  }

  /// Formate une date pour l'affichage
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Reprogramme toutes les notifications actives
  static Future<void> rescheduleAllNotifications() async {
    final reminders = getActiveReminders();
    for (final reminder in reminders) {
      await _scheduleNotification(reminder);
    }
  }

  /// Vérifie et envoie les notifications pour les factures en retard
  static Future<void> checkOverdueReminders() async {
    final overdueReminders = getOverdueReminders();
    for (final reminder in overdueReminders) {
      await NotificationService.showNotification(
        id: _getNotificationId(reminder.id) + 1,
        title: 'Facture en retard !',
        body: '${reminder.title} - ${reminder.amount.toStringAsFixed(2)}€ '
            'devait être payée le ${_formatDate(reminder.dueDate)}',
      );
    }
  }

  /// Calcule le total des factures à venir
  static double getTotalUpcoming({int days = 30}) {
    return getUpcomingReminders(days: days).fold(0.0, (sum, r) => sum + r.amount);
  }

  /// Calcule le total des factures en retard
  static double getTotalOverdue() {
    return getOverdueReminders().fold(0.0, (sum, r) => sum + r.amount);
  }
}
