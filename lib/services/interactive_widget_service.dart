import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

/// Service pour le widget interactif sur l'écran d'accueil
/// Permet d'ajouter des dépenses et voir le résumé sans ouvrir l'app
class InteractiveWidgetService {
  static InteractiveWidgetService? _instance;

  static const String _appGroupId = 'group.com.smartspend.widget';
  static const String _widgetName = 'SmartSpendWidget';

  // Clés de données partagées
  static const String _keyTodaySpent = 'today_spent';
  static const String _keyMonthSpent = 'month_spent';
  static const String _keyBudgetRemaining = 'budget_remaining';
  static const String _keyBudgetPercent = 'budget_percent';
  static const String _keyLastExpense = 'last_expense';
  static const String _keyQuickActions = 'quick_actions';
  static const String _keyCurrency = 'currency';
  static const String _keyLastUpdate = 'last_update';
  static const String _keyPendingExpense = 'pending_expense';

  InteractiveWidgetService._();

  static InteractiveWidgetService getInstance() {
    _instance ??= InteractiveWidgetService._();
    return _instance!;
  }

  /// Initialise le service de widget
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      // Écouter les interactions du widget
      HomeWidget.widgetClicked.listen(_handleWidgetClick);
    } catch (e) {
      debugPrint('Erreur d\'initialisation du widget: $e');
    }
  }

  // ==================== MISE À JOUR DES DONNÉES ====================

  /// Met à jour toutes les données du widget
  Future<void> updateWidgetData({
    required double todaySpent,
    required double monthSpent,
    required double budgetRemaining,
    required double budgetPercent,
    String? lastExpenseDescription,
    double? lastExpenseAmount,
    required String currency,
    List<QuickAction>? quickActions,
  }) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData(_keyTodaySpent, todaySpent),
        HomeWidget.saveWidgetData(_keyMonthSpent, monthSpent),
        HomeWidget.saveWidgetData(_keyBudgetRemaining, budgetRemaining),
        HomeWidget.saveWidgetData(_keyBudgetPercent, budgetPercent),
        HomeWidget.saveWidgetData(_keyCurrency, currency),
        HomeWidget.saveWidgetData(_keyLastUpdate, DateTime.now().toIso8601String()),
      ]);

      if (lastExpenseDescription != null && lastExpenseAmount != null) {
        await HomeWidget.saveWidgetData(
          _keyLastExpense,
          jsonEncode({
            'description': lastExpenseDescription,
            'amount': lastExpenseAmount,
          }),
        );
      }

      if (quickActions != null) {
        await HomeWidget.saveWidgetData(
          _keyQuickActions,
          jsonEncode(quickActions.map((a) => a.toJson()).toList()),
        );
      }

      // Rafraîchir le widget
      await refreshWidget();
    } catch (e) {
      debugPrint('Erreur de mise à jour du widget: $e');
    }
  }

  /// Met à jour uniquement le montant dépensé aujourd'hui
  Future<void> updateTodaySpent(double amount) async {
    await HomeWidget.saveWidgetData(_keyTodaySpent, amount);
    await refreshWidget();
  }

  /// Met à jour le budget restant
  Future<void> updateBudget({
    required double remaining,
    required double percentUsed,
  }) async {
    await HomeWidget.saveWidgetData(_keyBudgetRemaining, remaining);
    await HomeWidget.saveWidgetData(_keyBudgetPercent, percentUsed);
    await refreshWidget();
  }

  /// Rafraîchit l'affichage du widget
  Future<void> refreshWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: _widgetName,
        androidName: 'SmartSpendWidgetProvider',
      );
    } catch (e) {
      debugPrint('Erreur de rafraîchissement du widget: $e');
    }
  }

  // ==================== ACTIONS RAPIDES ====================

  /// Configure les actions rapides disponibles dans le widget
  Future<void> setQuickActions(List<QuickAction> actions) async {
    await HomeWidget.saveWidgetData(
      _keyQuickActions,
      jsonEncode(actions.map((a) => a.toJson()).toList()),
    );
    await refreshWidget();
  }

  /// Ajoute une dépense depuis le widget
  Future<void> addPendingExpense(PendingWidgetExpense expense) async {
    await HomeWidget.saveWidgetData(
      _keyPendingExpense,
      jsonEncode(expense.toJson()),
    );
  }

  /// Récupère une dépense en attente ajoutée depuis le widget
  Future<PendingWidgetExpense?> getPendingExpense() async {
    try {
      final data = await HomeWidget.getWidgetData<String>(_keyPendingExpense);
      if (data != null) {
        // Effacer après lecture
        await HomeWidget.saveWidgetData(_keyPendingExpense, null);
        return PendingWidgetExpense.fromJson(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Erreur de récupération de dépense en attente: $e');
    }
    return null;
  }

  // ==================== GESTION DES CLICS ====================

  /// Gère les clics sur le widget
  void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;

    final action = uri.host;
    final params = uri.queryParameters;

    switch (action) {
      case 'add_expense':
        _onAddExpenseClicked(params);
        break;
      case 'quick_action':
        _onQuickActionClicked(params);
        break;
      case 'view_details':
        _onViewDetailsClicked();
        break;
    }
  }

  void _onAddExpenseClicked(Map<String, String> params) {
    // Notifier l'app pour ouvrir l'écran d'ajout de dépense
    _notifyListeners(WidgetEvent.addExpense, params);
  }

  void _onQuickActionClicked(Map<String, String> params) {
    final actionId = params['id'];
    final amount = double.tryParse(params['amount'] ?? '');

    if (actionId != null) {
      _notifyListeners(WidgetEvent.quickAction, {
        'actionId': actionId,
        if (amount != null) 'amount': amount.toString(),
      });
    }
  }

  void _onViewDetailsClicked() {
    _notifyListeners(WidgetEvent.viewDetails, {});
  }

  // ==================== LISTENERS ====================

  final _listeners = <void Function(WidgetEvent, Map<String, dynamic>)>[];

  void addListener(void Function(WidgetEvent, Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(WidgetEvent, Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(WidgetEvent event, Map<String, dynamic> data) {
    for (final listener in _listeners) {
      listener(event, data);
    }
  }

  // ==================== CONFIGURATION ====================

  /// Vérifie si les widgets sont supportés
  Future<bool> isWidgetSupported() async {
    // La plupart des appareils modernes supportent les widgets
    return true;
  }

  /// Demande l'installation du widget
  Future<bool> requestWidgetPin() async {
    try {
      await HomeWidget.requestPinWidget(
        name: _widgetName,
        androidName: 'SmartSpendWidgetProvider',
      );
      return true;
    } catch (e) {
      debugPrint('Erreur de demande d\'épinglage: $e');
      return false;
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

/// Types d'événements du widget
enum WidgetEvent {
  addExpense,
  quickAction,
  viewDetails,
}

/// Action rapide configurée dans le widget
class QuickAction {
  final String id;
  final String label;
  final String? icon;
  final double? amount;
  final String? categoryId;
  final int color;

  const QuickAction({
    required this.id,
    required this.label,
    this.icon,
    this.amount,
    this.categoryId,
    this.color = 0xFF2196F3,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      color: json['color'] as int? ?? 0xFF2196F3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
      'amount': amount,
      'category_id': categoryId,
      'color': color,
    };
  }
}

/// Dépense en attente créée depuis le widget
class PendingWidgetExpense {
  final double? amount;
  final String? categoryId;
  final String? note;
  final DateTime createdAt;

  const PendingWidgetExpense({
    this.amount,
    this.categoryId,
    this.note,
    required this.createdAt,
  });

  factory PendingWidgetExpense.fromJson(Map<String, dynamic> json) {
    return PendingWidgetExpense(
      amount: (json['amount'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category_id': categoryId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Configuration du widget
class WidgetConfig {
  final WidgetSize size;
  final WidgetTheme theme;
  final bool showQuickActions;
  final bool showBudgetProgress;
  final bool showLastExpense;
  final List<QuickAction> quickActions;

  const WidgetConfig({
    this.size = WidgetSize.medium,
    this.theme = WidgetTheme.system,
    this.showQuickActions = true,
    this.showBudgetProgress = true,
    this.showLastExpense = true,
    this.quickActions = const [],
  });

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      size: WidgetSize.values.firstWhere(
        (s) => s.name == json['size'],
        orElse: () => WidgetSize.medium,
      ),
      theme: WidgetTheme.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => WidgetTheme.system,
      ),
      showQuickActions: json['show_quick_actions'] as bool? ?? true,
      showBudgetProgress: json['show_budget_progress'] as bool? ?? true,
      showLastExpense: json['show_last_expense'] as bool? ?? true,
      quickActions: (json['quick_actions'] as List<dynamic>?)
          ?.map((a) => QuickAction.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'theme': theme.name,
      'show_quick_actions': showQuickActions,
      'show_budget_progress': showBudgetProgress,
      'show_last_expense': showLastExpense,
      'quick_actions': quickActions.map((a) => a.toJson()).toList(),
    };
  }
}

/// Tailles de widget disponibles
enum WidgetSize {
  small,  // Affiche seulement le total du jour
  medium, // Affiche total + budget + 2 actions rapides
  large,  // Affiche tout + dernière dépense + 4 actions
}

/// Thèmes de widget
enum WidgetTheme {
  system,
  light,
  dark,
}
