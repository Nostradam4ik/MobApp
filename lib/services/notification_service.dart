import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service de notifications locales
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // IDs de notifications programmées
  static const int _dailyReminderId = 1000;
  static const int _weeklySummaryId = 1001;

  // Clés de préférences
  static const String _keyDailyReminder = 'notification_daily_reminder';
  static const String _keyReminderHour = 'notification_reminder_hour';
  static const String _keyReminderMinute = 'notification_reminder_minute';
  static const String _keyBudgetAlerts = 'notification_budget_alerts';
  static const String _keyGoalAlerts = 'notification_goal_alerts';
  static const String _keyWeeklySummary = 'notification_weekly_summary';

  /// Initialise le service de notifications
  static Future<void> init() async {
    if (_initialized) return;

    // Initialiser timezone
    if (!kIsWeb) {
      tz_data.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Fallback to Paris
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;

    // Restaurer les notifications programmées
    await _restoreScheduledNotifications();
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Restaure les notifications programmées au démarrage
  static Future<void> _restoreScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final dailyEnabled = prefs.getBool(_keyDailyReminder) ?? false;
    if (dailyEnabled) {
      final hour = prefs.getInt(_keyReminderHour) ?? 20;
      final minute = prefs.getInt(_keyReminderMinute) ?? 0;
      await scheduleDailyReminder(hour: hour, minute: minute);
    }

    final weeklyEnabled = prefs.getBool(_keyWeeklySummary) ?? false;
    if (weeklyEnabled) {
      await scheduleWeeklySummary();
    }
  }

  /// Demande les permissions de notification
  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ============ Getters/Setters pour les préférences ============

  /// Vérifie si le rappel quotidien est activé
  static Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminder) ?? false;
  }

  /// Active/désactive le rappel quotidien
  static Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, enabled);

    if (enabled) {
      final hour = prefs.getInt(_keyReminderHour) ?? 20;
      final minute = prefs.getInt(_keyReminderMinute) ?? 0;
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  /// Récupère l'heure du rappel quotidien
  static Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyReminderHour) ?? 20;
    final minute = prefs.getInt(_keyReminderMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Définit l'heure du rappel quotidien
  static Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, time.hour);
    await prefs.setInt(_keyReminderMinute, time.minute);

    final enabled = prefs.getBool(_keyDailyReminder) ?? false;
    if (enabled) {
      await scheduleDailyReminder(hour: time.hour, minute: time.minute);
    }
  }

  /// Vérifie si les alertes budget sont activées
  static Future<bool> areBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlerts) ?? true;
  }

  /// Active/désactive les alertes budget
  static Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlerts, enabled);
  }

  /// Vérifie si les alertes objectifs sont activées
  static Future<bool> areGoalAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGoalAlerts) ?? true;
  }

  /// Active/désactive les alertes objectifs
  static Future<void> setGoalAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGoalAlerts, enabled);
  }

  /// Vérifie si le résumé hebdomadaire est activé
  static Future<bool> isWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeeklySummary) ?? false;
  }

  /// Active/désactive le résumé hebdomadaire
  static Future<void> setWeeklySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklySummary, enabled);

    if (enabled) {
      await scheduleWeeklySummary();
    } else {
      await cancelWeeklySummary();
    }
  }

  // ============ Notifications programmées ============

  /// Programme le rappel quotidien
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si l'heure est passée, programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Rappels quotidiens',
      channelDescription: 'Rappel quotidien pour noter vos dépenses',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'N\'oubliez pas vos dépenses',
      'Avez-vous noté vos dépenses du jour ?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  /// Annule le rappel quotidien
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Programme le résumé hebdomadaire (dimanche 18h)
  static Future<void> scheduleWeeklySummary() async {
    if (kIsWeb) return;

    await _plugin.cancel(_weeklySummaryId);

    final now = tz.TZDateTime.now(tz.local);

    // Trouver le prochain dimanche à 18h
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      18,
      0,
    );

    // Avancer jusqu'au prochain dimanche
    while (scheduledDate.weekday != DateTime.sunday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_summary_channel',
      'Résumé hebdomadaire',
      channelDescription: 'Résumé de vos dépenses de la semaine',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _weeklySummaryId,
      'Résumé de la semaine',
      'Découvrez le bilan de vos dépenses cette semaine',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  /// Annule le résumé hebdomadaire
  static Future<void> cancelWeeklySummary() async {
    await _plugin.cancel(_weeklySummaryId);
  }

  // ============ Notifications immédiates ============

  /// Affiche une notification immédiate
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smartspend_channel',
      'SmartSpend Notifications',
      channelDescription: 'Notifications de l\'application SmartSpend',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Affiche une notification d'alerte budget
  static Future<void> showBudgetAlert({
    required String categoryName,
    required int percentage,
  }) async {
    // Vérifier si les alertes sont activées
    final enabled = await areBudgetAlertsEnabled();
    if (!enabled) return;

    String title;
    String body;

    if (percentage >= 100) {
      title = 'Budget dépassé !';
      body = 'Vous avez dépassé votre budget $categoryName';
    } else if (percentage >= 90) {
      title = 'Budget presque épuisé !';
      body = 'Vous avez utilisé $percentage% de votre budget $categoryName';
    } else if (percentage >= 75) {
      title = 'Attention au budget';
      body = 'Vous avez utilisé $percentage% de votre budget $categoryName';
    } else {
      return; // Pas d'alerte en dessous de 75%
    }

    await showNotification(
      id: categoryName.hashCode,
      title: title,
      body: body,
      payload: 'budget_alert',
    );
  }

  /// Affiche une notification de streak
  static Future<void> showStreakNotification({
    required int streakDays,
  }) async {
    await showNotification(
      id: 2001,
      title: 'Bravo ! $streakDays jours de suite',
      body: 'Continuez à suivre vos dépenses pour maintenir votre streak !',
      payload: 'streak',
    );
  }

  /// Affiche une notification d'achievement
  static Future<void> showAchievementNotification({
    required String title,
    required String description,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Nouveau badge obtenu !',
      body: '$title - $description',
      payload: 'achievement',
    );
  }

  /// Affiche une notification d'objectif atteint
  static Future<void> showGoalCompletedNotification({
    required String goalTitle,
  }) async {
    // Vérifier si les alertes sont activées
    final enabled = await areGoalAlertsEnabled();
    if (!enabled) return;

    await showNotification(
      id: goalTitle.hashCode,
      title: 'Objectif atteint !',
      body: 'Félicitations ! Vous avez atteint votre objectif "$goalTitle"',
      payload: 'goal_completed',
    );
  }

  /// Affiche une notification de progression d'objectif
  static Future<void> showGoalProgressNotification({
    required String goalTitle,
    required int percentage,
  }) async {
    final enabled = await areGoalAlertsEnabled();
    if (!enabled) return;

    if (percentage == 50 || percentage == 75 || percentage == 90) {
      await showNotification(
        id: 'goal_progress_$goalTitle'.hashCode,
        title: 'Objectif en bonne voie !',
        body: 'Vous avez atteint $percentage% de "$goalTitle"',
        payload: 'goal_progress',
      );
    }
  }

  /// Affiche une notification de dépense récurrente
  static Future<void> showRecurringExpenseNotification({
    required String expenseName,
    required double amount,
  }) async {
    await showNotification(
      id: expenseName.hashCode,
      title: 'Dépense récurrente ajoutée',
      body: '$expenseName : ${amount.toStringAsFixed(2)} € a été enregistré',
      payload: 'recurring_expense',
    );
  }

  /// Programme une notification à une date spécifique
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'bills_channel',
      'Rappels de factures',
      channelDescription: 'Notifications pour les rappels de factures',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Annule une notification
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Annule toutes les notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Récupère toutes les notifications programmées
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
