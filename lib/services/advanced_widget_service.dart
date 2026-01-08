// ============================================================================
// SmartSpend - Service de widgets avancés écran d'accueil
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

/// Types de widgets disponibles
enum HomeWidgetType {
  // Widgets compacts
  monthlyTotal,
  dailyBudget,
  quickAdd,

  // Widgets moyens
  budgetProgress,
  recentExpenses,
  categoryBreakdown,

  // Widgets larges
  weeklyChart,
  monthlyOverview,
  savingsProgress,
}

/// Configuration d'un widget
class WidgetConfig {
  final HomeWidgetType type;
  final String name;
  final String description;
  final String iOSClassName;
  final String androidClassName;
  final int minWidth;
  final int minHeight;
  final bool supportsDarkMode;

  const WidgetConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.iOSClassName,
    required this.androidClassName,
    this.minWidth = 2,
    this.minHeight = 2,
    this.supportsDarkMode = true,
  });
}

/// Service de gestion des widgets écran d'accueil avancés
class AdvancedWidgetService {
  static const String appGroupId = 'group.com.smartspend.app';
  static const String iOSWidgetName = 'SmartSpendWidget';
  static const String androidPackage = 'com.smartspend.app';

  /// Configurations des widgets disponibles
  static final List<WidgetConfig> availableWidgets = [
    const WidgetConfig(
      type: HomeWidgetType.monthlyTotal,
      name: 'Total mensuel',
      description: 'Affiche le total des dépenses du mois',
      iOSClassName: 'MonthlyTotalWidget',
      androidClassName: 'MonthlyTotalWidget',
      minWidth: 2,
      minHeight: 1,
    ),
    const WidgetConfig(
      type: HomeWidgetType.dailyBudget,
      name: 'Budget quotidien',
      description: 'Affiche le budget restant pour aujourd\'hui',
      iOSClassName: 'DailyBudgetWidget',
      androidClassName: 'DailyBudgetWidget',
      minWidth: 2,
      minHeight: 1,
    ),
    const WidgetConfig(
      type: HomeWidgetType.quickAdd,
      name: 'Ajout rapide',
      description: 'Ajouter une dépense en un tap',
      iOSClassName: 'QuickAddWidget',
      androidClassName: 'QuickAddWidget',
      minWidth: 1,
      minHeight: 1,
    ),
    const WidgetConfig(
      type: HomeWidgetType.budgetProgress,
      name: 'Progression budget',
      description: 'Barre de progression du budget mensuel',
      iOSClassName: 'BudgetProgressWidget',
      androidClassName: 'BudgetProgressWidget',
      minWidth: 4,
      minHeight: 1,
    ),
    const WidgetConfig(
      type: HomeWidgetType.recentExpenses,
      name: 'Dépenses récentes',
      description: 'Les 3 dernières dépenses',
      iOSClassName: 'RecentExpensesWidget',
      androidClassName: 'RecentExpensesWidget',
      minWidth: 4,
      minHeight: 2,
    ),
    const WidgetConfig(
      type: HomeWidgetType.categoryBreakdown,
      name: 'Par catégorie',
      description: 'Répartition par catégorie',
      iOSClassName: 'CategoryBreakdownWidget',
      androidClassName: 'CategoryBreakdownWidget',
      minWidth: 2,
      minHeight: 2,
    ),
    const WidgetConfig(
      type: HomeWidgetType.weeklyChart,
      name: 'Graphique hebdo',
      description: 'Évolution sur 7 jours',
      iOSClassName: 'WeeklyChartWidget',
      androidClassName: 'WeeklyChartWidget',
      minWidth: 4,
      minHeight: 2,
    ),
    const WidgetConfig(
      type: HomeWidgetType.monthlyOverview,
      name: 'Aperçu mensuel',
      description: 'Vue complète du mois',
      iOSClassName: 'MonthlyOverviewWidget',
      androidClassName: 'MonthlyOverviewWidget',
      minWidth: 4,
      minHeight: 3,
    ),
    const WidgetConfig(
      type: HomeWidgetType.savingsProgress,
      name: 'Objectifs d\'épargne',
      description: 'Progression vers vos objectifs',
      iOSClassName: 'SavingsProgressWidget',
      androidClassName: 'SavingsProgressWidget',
      minWidth: 4,
      minHeight: 2,
    ),
  ];

  /// Initialiser le service de widgets
  static Future<void> init() async {
    try {
      // Configurer le groupe d'app pour iOS
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }

      // Configurer les mises à jour en arrière-plan
      await _setupBackgroundUpdates();

      debugPrint('AdvancedWidgetService initialized');
    } catch (e) {
      debugPrint('AdvancedWidgetService init error: $e');
    }
  }

  /// Configurer les mises à jour en arrière-plan
  static Future<void> _setupBackgroundUpdates() async {
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Planifier une mise à jour périodique
    await Workmanager().registerPeriodicTask(
      'widget_update',
      'updateWidgets',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
    );
  }

  /// Mettre à jour les données du widget
  static Future<void> updateWidgetData({
    required double monthlyTotal,
    required double monthlyBudget,
    required double todayTotal,
    required double weekTotal,
    required List<Map<String, dynamic>> recentExpenses,
    required Map<String, double> categoryTotals,
    required List<double> weeklyData,
    required double savingsProgress,
    required double savingsGoal,
  }) async {
    try {
      // Données de base
      await HomeWidget.saveWidgetData<double>('monthly_total', monthlyTotal);
      await HomeWidget.saveWidgetData<double>('monthly_budget', monthlyBudget);
      await HomeWidget.saveWidgetData<double>('today_total', todayTotal);
      await HomeWidget.saveWidgetData<double>('week_total', weekTotal);

      // Calculs
      final budgetPercent = monthlyBudget > 0
          ? (monthlyTotal / monthlyBudget * 100).clamp(0, 100)
          : 0.0;
      final dailyBudgetRemaining = _calculateDailyBudget(monthlyBudget, monthlyTotal);

      await HomeWidget.saveWidgetData<double>('budget_percent', budgetPercent);
      await HomeWidget.saveWidgetData<double>('daily_budget', dailyBudgetRemaining);

      // Dépenses récentes (JSON string)
      final recentJson = recentExpenses.map((e) =>
        '${e['amount']}|${e['category']}|${e['date']}'
      ).join(';');
      await HomeWidget.saveWidgetData<String>('recent_expenses', recentJson);

      // Catégories (top 5)
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCategories = sortedCategories.take(5).map((e) =>
        '${e.key}|${e.value.toStringAsFixed(2)}'
      ).join(';');
      await HomeWidget.saveWidgetData<String>('category_breakdown', topCategories);

      // Données hebdomadaires
      final weeklyDataStr = weeklyData.map((d) => d.toStringAsFixed(2)).join(',');
      await HomeWidget.saveWidgetData<String>('weekly_data', weeklyDataStr);

      // Épargne
      await HomeWidget.saveWidgetData<double>('savings_current', savingsProgress);
      await HomeWidget.saveWidgetData<double>('savings_goal', savingsGoal);
      final savingsPercent = savingsGoal > 0
          ? (savingsProgress / savingsGoal * 100).clamp(0, 100)
          : 0.0;
      await HomeWidget.saveWidgetData<double>('savings_percent', savingsPercent);

      // Timestamp de mise à jour
      await HomeWidget.saveWidgetData<String>(
        'last_update',
        DateTime.now().toIso8601String(),
      );

      // Rafraîchir tous les widgets
      await _refreshAllWidgets();

      debugPrint('Widget data updated successfully');
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }

  /// Calculer le budget quotidien restant
  static double _calculateDailyBudget(double monthlyBudget, double monthlyTotal) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;

    final remaining = monthlyBudget - monthlyTotal;
    return remaining > 0 ? remaining / daysRemaining : 0;
  }

  /// Rafraîchir tous les widgets
  static Future<void> _refreshAllWidgets() async {
    if (Platform.isIOS) {
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
      );
    } else if (Platform.isAndroid) {
      // Rafraîchir chaque type de widget
      for (final widget in availableWidgets) {
        await HomeWidget.updateWidget(
          androidName: widget.androidClassName,
        );
      }
    }
  }

  /// Rafraîchir un widget spécifique
  static Future<void> refreshWidget(HomeWidgetType type) async {
    final config = availableWidgets.firstWhere((w) => w.type == type);

    if (Platform.isIOS) {
      await HomeWidget.updateWidget(iOSName: config.iOSClassName);
    } else if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: config.androidClassName);
    }
  }

  /// Gérer les actions du widget (tap)
  static Future<void> handleWidgetAction(Uri? uri) async {
    if (uri == null) return;

    final action = uri.host;
    final params = uri.queryParameters;

    switch (action) {
      case 'add_expense':
        // Ouvrir l'écran d'ajout de dépense
        final categoryId = params['category'];
        final amount = params['amount'];
        // Navigation gérée par le router
        break;

      case 'view_budget':
        // Ouvrir l'écran des budgets
        break;

      case 'view_goals':
        // Ouvrir l'écran des objectifs
        break;

      case 'quick_add':
        // Ouvrir la modale d'ajout rapide
        final quickAmount = double.tryParse(params['amount'] ?? '');
        if (quickAmount != null) {
          // Ajouter la dépense directement
        }
        break;
    }
  }

  /// Configurer le widget interactif (iOS 17+)
  static Future<void> setupInteractiveWidget() async {
    // Configuration pour les widgets interactifs iOS 17+
    // et les widgets glanceable Android
  }

  /// Obtenir les données actuelles du widget
  static Future<Map<String, dynamic>> getWidgetData() async {
    return {
      'monthly_total': await HomeWidget.getWidgetData<double>('monthly_total'),
      'monthly_budget': await HomeWidget.getWidgetData<double>('monthly_budget'),
      'today_total': await HomeWidget.getWidgetData<double>('today_total'),
      'budget_percent': await HomeWidget.getWidgetData<double>('budget_percent'),
      'daily_budget': await HomeWidget.getWidgetData<double>('daily_budget'),
      'last_update': await HomeWidget.getWidgetData<String>('last_update'),
    };
  }

  /// Données pour le widget graphique
  static Future<void> updateChartData(List<double> dailyTotals) async {
    // Convertir en string pour le stockage
    final chartData = dailyTotals.map((d) => d.toStringAsFixed(2)).join(',');
    await HomeWidget.saveWidgetData<String>('chart_data', chartData);

    // Calculer les statistiques
    final max = dailyTotals.isEmpty ? 0.0 : dailyTotals.reduce((a, b) => a > b ? a : b);
    final avg = dailyTotals.isEmpty ? 0.0 : dailyTotals.reduce((a, b) => a + b) / dailyTotals.length;

    await HomeWidget.saveWidgetData<double>('chart_max', max);
    await HomeWidget.saveWidgetData<double>('chart_avg', avg);
  }

  /// Mettre à jour les widgets avec les dernières transactions
  static Future<void> updateWithLatestExpenses(List<Map<String, dynamic>> expenses) async {
    final recent = expenses.take(5).toList();

    for (var i = 0; i < recent.length; i++) {
      await HomeWidget.saveWidgetData<String>('expense_$i',
        '${recent[i]['amount']}|${recent[i]['category']}|${recent[i]['note']}'
      );
    }

    await HomeWidget.saveWidgetData<int>('expense_count', recent.length);
    await _refreshAllWidgets();
  }
}

/// Callback pour les mises à jour en arrière-plan
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'updateWidgets':
        // Mettre à jour les widgets avec les dernières données
        try {
          // Charger les données depuis le stockage local et mettre à jour
          return true;
        } catch (e) {
          return false;
        }
      default:
        return true;
    }
  });
}

/// Écran de gestion des widgets
class WidgetManagementScreen {
  /// Obtenir la liste des widgets installés
  static Future<List<HomeWidgetType>> getInstalledWidgets() async {
    // Dans une vraie implémentation, interroger le système
    return [];
  }

  /// Inviter l'utilisateur à ajouter un widget
  static Future<void> promptAddWidget(HomeWidgetType type) async {
    // Ouvrir les paramètres de widgets du système
  }
}
