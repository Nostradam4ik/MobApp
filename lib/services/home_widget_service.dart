import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';

/// Noms des widgets
class HomeWidgetNames {
  static const String androidSmall = 'SmartSpendWidgetSmall';
  static const String androidMedium = 'SmartSpendWidgetMedium';
  static const String iosWidget = 'SmartSpendWidget';
}

/// Clés de données pour le widget
class HomeWidgetKeys {
  static const String monthTotal = 'month_total';
  static const String weekTotal = 'week_total';
  static const String todayTotal = 'today_total';
  static const String budgetLimit = 'budget_limit';
  static const String budgetPercent = 'budget_percent';
  static const String currencySymbol = 'currency_symbol';
  static const String lastUpdate = 'last_update';
  static const String streakDays = 'streak_days';
}

/// Service pour gérer le widget d'accueil
class HomeWidgetService {
  HomeWidgetService._();

  static const String _appGroupId = 'group.com.smartspend.widget';
  static const String _workTaskName = 'com.smartspend.widgetUpdate';

  /// Initialise le service de widget
  static Future<void> init() async {
    // Configuration du groupe d'app pour iOS
    await HomeWidget.setAppGroupId(_appGroupId);

    // Écouter les interactions avec le widget
    HomeWidget.widgetClicked.listen(_handleWidgetClick);

    // Configuration du workmanager pour les mises à jour en arrière-plan
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Callback pour les mises à jour en arrière-plan
  @pragma('vm:entry-point')
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == _workTaskName) {
        // Recharger les données et mettre à jour le widget
        // Note: Dans une vraie implémentation, on chargerait les données depuis SQLite
        await updateWidgetFromBackground();
      }
      return Future.value(true);
    });
  }

  /// Met à jour les données du widget depuis l'arrière-plan
  static Future<void> updateWidgetFromBackground() async {
    // Cette méthode sera appelée par le workmanager
    // Les données seront chargées depuis le cache local (SQLite/SharedPreferences)
    await updateWidget();
  }

  /// Configure les mises à jour périodiques du widget
  static Future<void> schedulePeriodicUpdates() async {
    // Programmer une mise à jour toutes les 15 minutes minimum
    await Workmanager().registerPeriodicTask(
      _workTaskName,
      _workTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Annule les mises à jour périodiques
  static Future<void> cancelPeriodicUpdates() async {
    await Workmanager().cancelByUniqueName(_workTaskName);
  }

  /// Met à jour les données du widget avec les valeurs fournies
  static Future<void> updateWidgetData({
    required double monthTotal,
    required double weekTotal,
    required double todayTotal,
    double? budgetLimit,
    double? budgetPercent,
    String currencySymbol = '€',
    int streakDays = 0,
  }) async {
    try {
      // Sauvegarder les données
      await HomeWidget.saveWidgetData<double>(
        HomeWidgetKeys.monthTotal,
        monthTotal,
      );
      await HomeWidget.saveWidgetData<double>(
        HomeWidgetKeys.weekTotal,
        weekTotal,
      );
      await HomeWidget.saveWidgetData<double>(
        HomeWidgetKeys.todayTotal,
        todayTotal,
      );

      if (budgetLimit != null) {
        await HomeWidget.saveWidgetData<double>(
          HomeWidgetKeys.budgetLimit,
          budgetLimit,
        );
      }

      if (budgetPercent != null) {
        await HomeWidget.saveWidgetData<double>(
          HomeWidgetKeys.budgetPercent,
          budgetPercent,
        );
      }

      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.currencySymbol,
        currencySymbol,
      );

      await HomeWidget.saveWidgetData<int>(
        HomeWidgetKeys.streakDays,
        streakDays,
      );

      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.lastUpdate,
        DateFormat('HH:mm').format(DateTime.now()),
      );

      // Mettre à jour le widget
      await updateWidget();
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  /// Force la mise à jour du widget
  static Future<void> updateWidget() async {
    try {
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          androidName: HomeWidgetNames.androidSmall,
        );
        await HomeWidget.updateWidget(
          androidName: HomeWidgetNames.androidMedium,
        );
      } else if (Platform.isIOS) {
        await HomeWidget.updateWidget(
          iOSName: HomeWidgetNames.iosWidget,
        );
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  /// Gère les clics sur le widget
  static void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;

    // Exemples d'actions basées sur l'URI
    switch (uri.host) {
      case 'add_expense':
        // Naviguer vers l'écran d'ajout de dépense
        // Note: Cela nécessiterait un système de deep linking
        break;
      case 'open_app':
      default:
        // Ouvrir l'app normalement
        break;
    }
  }

  /// Vérifie si les widgets sont supportés sur cette plateforme
  static bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Obtient les données formatées pour affichage
  static String formatAmount(double amount, String symbol) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
