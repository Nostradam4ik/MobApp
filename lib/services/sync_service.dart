import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_database_service.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart' as models;
import '../data/models/budget.dart';

/// État de la connexion
enum ConnectivityStatus {
  online,
  offline,
}

/// Service de synchronisation entre Supabase et SQLite local
class SyncService {
  SyncService._();

  static final _supabase = Supabase.instance.client;
  static ConnectivityStatus _status = ConnectivityStatus.online;
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static const String _keyLastSync = 'last_sync_timestamp';
  static const String _keyOfflineMode = 'offline_mode_enabled';

  /// Statut actuel de la connexion
  static ConnectivityStatus get status => _status;

  /// Vérifie si on est en ligne
  static bool get isOnline => _status == ConnectivityStatus.online;

  /// Vérifie si le mode hors-ligne est activé manuellement
  static Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineMode) ?? false;
  }

  /// Active/désactive le mode hors-ligne manuel
  static Future<void> setOfflineMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, enabled);
    _status = enabled ? ConnectivityStatus.offline : ConnectivityStatus.online;
  }

  /// Initialise le service de synchronisation
  static Future<void> init() async {
    // Vérifier la connectivité initiale
    await checkConnectivity();

    // Programmer la synchronisation périodique (toutes les 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncAll();
    });
  }

  /// Arrête le service
  static void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Vérifie la connectivité avec Supabase
  static Future<void> checkConnectivity() async {
    try {
      // Tenter une requête simple
      await _supabase.from('categories').select('id').limit(1);
      _status = ConnectivityStatus.online;
    } catch (e) {
      _status = ConnectivityStatus.offline;
      debugPrint('Offline mode: $e');
    }
  }

  /// Récupère la date de dernière synchronisation
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_keyLastSync);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Met à jour la date de dernière synchronisation
  static Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  /// Synchronise toutes les données
  static Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Synchronisation en cours');
    }

    if (!isOnline) {
      return SyncResult(success: false, message: 'Mode hors-ligne');
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    try {
      // 1. Envoyer les modifications locales vers le serveur
      final pendingOps = await OfflineDatabaseService.getPendingSyncOperations();

      for (final op in pendingOps) {
        try {
          await _processSyncOperation(op);
          await OfflineDatabaseService.removeSyncOperation(op['id'] as int);
          synced++;
        } catch (e) {
          failed++;
          await OfflineDatabaseService.incrementRetryCount(op['id'] as int);
          debugPrint('Sync error: $e');
        }
      }

      // 2. Récupérer les données du serveur
      await _syncFromServer();

      await _updateLastSyncTime();

      _isSyncing = false;
      return SyncResult(
        success: true,
        message: 'Synchronisation réussie',
        syncedCount: synced,
        failedCount: failed,
      );
    } catch (e) {
      _isSyncing = false;
      return SyncResult(success: false, message: 'Erreur: $e');
    }
  }

  /// Traite une opération de synchronisation
  static Future<void> _processSyncOperation(Map<String, dynamic> op) async {
    final tableName = op['table_name'] as String;
    final recordId = op['record_id'] as String;
    final action = op['action'] as String;

    switch (action) {
      case 'insert':
      case 'update':
        // Récupérer les données locales et les envoyer
        if (tableName == 'expenses') {
          final expenses = await OfflineDatabaseService.getExpenses();
          final expense = expenses.firstWhere((e) => e.id == recordId, orElse: () => throw Exception('Not found'));
          await _supabase.from('expenses').upsert(expense.toJson()..['id'] = expense.id);
        }
        break;

      case 'delete':
        await _supabase.from(tableName).delete().eq('id', recordId);
        break;
    }
  }

  /// Synchronise les données depuis le serveur
  static Future<void> _syncFromServer() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Synchroniser les catégories
      final categoriesResponse = await _supabase
          .from('categories')
          .select()
          .or('user_id.eq.$userId,is_default.eq.true')
          .order('sort_order');

      final categories = (categoriesResponse as List)
          .map((json) => models.Category.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveCategories(categories);

      // Synchroniser les dépenses (dernier mois)
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final expensesResponse = await _supabase
          .from('expenses')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .gte('expense_date', oneMonthAgo.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      final expenses = (expensesResponse as List)
          .map((json) => Expense.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveExpenses(expenses);

      // Synchroniser les budgets actifs
      final budgetsResponse = await _supabase
          .from('budgets')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .eq('is_active', true);

      final budgets = (budgetsResponse as List)
          .map((json) => Budget.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveBudgets(budgets);
    } catch (e) {
      debugPrint('Error syncing from server: $e');
      rethrow;
    }
  }

  /// Synchronisation initiale complète
  static Future<void> initialSync() async {
    if (!isOnline) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Catégories
      final categoriesResponse = await _supabase
          .from('categories')
          .select()
          .or('user_id.eq.$userId,is_default.eq.true')
          .order('sort_order');

      final categories = (categoriesResponse as List)
          .map((json) => models.Category.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveCategories(categories);

      // Toutes les dépenses des 6 derniers mois
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final expensesResponse = await _supabase
          .from('expenses')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .gte('expense_date', sixMonthsAgo.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      final expenses = (expensesResponse as List)
          .map((json) => Expense.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveExpenses(expenses);

      // Tous les budgets actifs
      final budgetsResponse = await _supabase
          .from('budgets')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .eq('is_active', true);

      final budgets = (budgetsResponse as List)
          .map((json) => Budget.fromJson(json))
          .toList();

      await OfflineDatabaseService.saveBudgets(budgets);

      await _updateLastSyncTime();
    } catch (e) {
      debugPrint('Initial sync error: $e');
      rethrow;
    }
  }

  /// Force la synchronisation immédiate
  static Future<SyncResult> forceSync() async {
    await checkConnectivity();
    return await syncAll();
  }

  /// Sauvegarde une dépense (en ligne ou hors-ligne)
  static Future<Expense> saveExpense({
    required String userId,
    required double amount,
    String? categoryId,
    String? note,
    required DateTime expenseDate,
    bool isRecurring = false,
    String? recurringFrequency,
    String? existingId,
  }) async {
    final now = DateTime.now();
    final id = existingId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final expense = Expense(
      id: id,
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      note: note,
      expenseDate: expenseDate,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      createdAt: now,
      updatedAt: now,
    );

    if (isOnline) {
      try {
        // Sauvegarder en ligne
        if (existingId != null) {
          await _supabase.from('expenses').update(expense.toJson()).eq('id', id);
        } else {
          await _supabase.from('expenses').insert(expense.toJson());
        }

        // Aussi sauvegarder localement
        if (existingId != null) {
          await OfflineDatabaseService.updateExpense(expense);
        } else {
          await OfflineDatabaseService.insertExpense(expense);
        }
      } catch (e) {
        // En cas d'erreur, passer en mode hors-ligne
        _status = ConnectivityStatus.offline;
        if (existingId != null) {
          await OfflineDatabaseService.updateExpense(expense);
        } else {
          await OfflineDatabaseService.insertExpense(expense);
        }
      }
    } else {
      // Mode hors-ligne
      if (existingId != null) {
        await OfflineDatabaseService.updateExpense(expense);
      } else {
        await OfflineDatabaseService.insertExpense(expense);
      }
    }

    return expense;
  }

  /// Supprime une dépense (en ligne ou hors-ligne)
  static Future<void> deleteExpense(String id) async {
    if (isOnline) {
      try {
        await _supabase.from('expenses').delete().eq('id', id);
      } catch (e) {
        _status = ConnectivityStatus.offline;
      }
    }

    await OfflineDatabaseService.deleteExpense(id);
  }

  /// Récupère les dépenses (depuis le cache local si hors-ligne)
  static Future<List<Expense>> getExpenses({int? month, int? year}) async {
    if (isOnline) {
      try {
        // Essayer de synchroniser d'abord
        await _syncFromServer();
      } catch (e) {
        _status = ConnectivityStatus.offline;
      }
    }

    // Toujours lire depuis le cache local
    if (month != null && year != null) {
      return await OfflineDatabaseService.getExpensesByMonth(year, month);
    }
    return await OfflineDatabaseService.getExpenses();
  }
}

/// Résultat d'une synchronisation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}
