// ============================================================================
// SmartSpend - Service de synchronisation temps réel
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

/// État de la synchronisation
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
  offline,
}

/// Événement de changement temps réel
class RealtimeEvent {
  final String table;
  final String eventType; // INSERT, UPDATE, DELETE
  final Map<String, dynamic>? oldRecord;
  final Map<String, dynamic>? newRecord;
  final DateTime timestamp;

  RealtimeEvent({
    required this.table,
    required this.eventType,
    this.oldRecord,
    this.newRecord,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Callback pour les événements temps réel
typedef RealtimeCallback = void Function(RealtimeEvent event);

/// Service de synchronisation temps réel multi-appareils via Supabase
class RealtimeSyncService extends ChangeNotifier {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();

  final _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, List<RealtimeCallback>> _listeners = {};

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  bool _isInitialized = false;
  String? _currentUserId;

  // Getters
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isOnline => _status != SyncStatus.offline;

  /// Tables à synchroniser
  static const List<String> _syncTables = [
    'expenses',
    'categories',
    'budgets',
    'goals',
    'accounts',
    'achievements',
    'user_achievements',
  ];

  /// Initialiser le service de synchronisation
  Future<void> init(String? userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    _currentUserId = userId;
    if (userId == null) {
      await dispose();
      return;
    }

    try {
      _setStatus(SyncStatus.syncing);

      // S'abonner aux changements pour chaque table
      for (final table in _syncTables) {
        await _subscribeToTable(table, userId);
      }

      // Charger la dernière heure de sync
      final lastSync = LocalStorageService.getString('last_sync_$userId');
      if (lastSync != null) {
        _lastSyncTime = DateTime.tryParse(lastSync);
      }

      _isInitialized = true;
      _setStatus(SyncStatus.synced);

      debugPrint('RealtimeSyncService initialized for user: $userId');
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
      debugPrint('RealtimeSyncService init error: $e');
    }
  }

  /// S'abonner aux changements d'une table
  Future<void> _subscribeToTable(String table, String userId) async {
    // Annuler l'ancien channel si existant
    if (_channels.containsKey(table)) {
      await _channels[table]?.unsubscribe();
    }

    final channel = _supabase.channel('realtime_$table');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleRealtimeEvent(table, payload);
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Subscribed to $table realtime changes');
          } else if (status == RealtimeSubscribeStatus.closed) {
            debugPrint('Unsubscribed from $table');
          } else if (error != null) {
            debugPrint('Subscription error for $table: $error');
          }
        });

    _channels[table] = channel;
  }

  /// Gérer un événement temps réel
  void _handleRealtimeEvent(String table, PostgresChangePayload payload) {
    final event = RealtimeEvent(
      table: table,
      eventType: payload.eventType.name.toUpperCase(),
      oldRecord: payload.oldRecord,
      newRecord: payload.newRecord,
    );

    debugPrint('Realtime event: ${event.eventType} on $table');

    // Mettre à jour le statut
    _lastSyncTime = DateTime.now();
    _setStatus(SyncStatus.synced);

    // Sauvegarder l'heure de sync
    if (_currentUserId != null) {
      LocalStorageService.setString(
        'last_sync_$_currentUserId',
        _lastSyncTime!.toIso8601String(),
      );
    }

    // Notifier les listeners
    final listeners = _listeners[table] ?? [];
    for (final callback in listeners) {
      try {
        callback(event);
      } catch (e) {
        debugPrint('Error in realtime callback: $e');
      }
    }

    // Notifier également les listeners globaux
    final globalListeners = _listeners['*'] ?? [];
    for (final callback in globalListeners) {
      try {
        callback(event);
      } catch (e) {
        debugPrint('Error in global realtime callback: $e');
      }
    }

    notifyListeners();
  }

  /// Ajouter un listener pour une table spécifique
  void addListener(String table, RealtimeCallback callback) {
    _listeners.putIfAbsent(table, () => []).add(callback);
  }

  /// Ajouter un listener global (toutes les tables)
  void addGlobalListener(RealtimeCallback callback) {
    _listeners.putIfAbsent('*', () => []).add(callback);
  }

  /// Supprimer un listener
  void removeListener(String table, RealtimeCallback callback) {
    _listeners[table]?.remove(callback);
  }

  /// Supprimer un listener global
  void removeGlobalListener(RealtimeCallback callback) {
    _listeners['*']?.remove(callback);
  }

  /// Forcer une synchronisation
  Future<void> forceSync() async {
    if (_currentUserId == null) return;

    try {
      _setStatus(SyncStatus.syncing);

      // Synchroniser les données locales non synchronisées
      await _syncPendingChanges();

      _lastSyncTime = DateTime.now();
      LocalStorageService.setString(
        'last_sync_$_currentUserId',
        _lastSyncTime!.toIso8601String(),
      );

      _setStatus(SyncStatus.synced);
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
      rethrow;
    }
  }

  /// Synchroniser les changements en attente
  Future<void> _syncPendingChanges() async {
    // Récupérer les changements locaux non synchronisés
    final pendingChanges = await _getPendingChanges();

    for (final change in pendingChanges) {
      try {
        await _pushChange(change);
      } catch (e) {
        debugPrint('Error syncing change: $e');
        // Continuer avec les autres changements
      }
    }
  }

  /// Récupérer les changements en attente
  Future<List<Map<String, dynamic>>> _getPendingChanges() async {
    // Implémenter la logique pour récupérer les changements locaux non synchronisés
    // Pour l'instant, retourner une liste vide
    return [];
  }

  /// Pousser un changement vers le serveur
  Future<void> _pushChange(Map<String, dynamic> change) async {
    final table = change['table'] as String;
    final operation = change['operation'] as String;
    final data = change['data'] as Map<String, dynamic>;

    switch (operation) {
      case 'INSERT':
        await _supabase.from(table).insert(data);
        break;
      case 'UPDATE':
        await _supabase.from(table).update(data).eq('id', data['id']);
        break;
      case 'DELETE':
        await _supabase.from(table).delete().eq('id', data['id']);
        break;
    }
  }

  /// Marquer comme hors ligne
  void setOffline() {
    _setStatus(SyncStatus.offline);
  }

  /// Marquer comme en ligne
  void setOnline() {
    if (_status == SyncStatus.offline) {
      _setStatus(SyncStatus.idle);
      forceSync();
    }
  }

  /// Mettre à jour le statut
  void _setStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  /// Obtenir l'icône du statut
  String get statusIcon {
    switch (_status) {
      case SyncStatus.idle:
        return '⏸️';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.error:
        return '❌';
      case SyncStatus.offline:
        return '📴';
    }
  }

  /// Obtenir le texte du statut
  String get statusText {
    switch (_status) {
      case SyncStatus.idle:
        return 'En attente';
      case SyncStatus.syncing:
        return 'Synchronisation...';
      case SyncStatus.synced:
        return 'Synchronisé';
      case SyncStatus.error:
        return 'Erreur de sync';
      case SyncStatus.offline:
        return 'Hors ligne';
    }
  }

  /// Obtenir le texte de la dernière synchronisation
  String get lastSyncText {
    if (_lastSyncTime == null) return 'Jamais synchronisé';

    final diff = DateTime.now().difference(_lastSyncTime!);

    if (diff.inSeconds < 60) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else {
      return 'Il y a ${diff.inDays} jours';
    }
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
    _listeners.clear();
    _isInitialized = false;
    _currentUserId = null;
    _setStatus(SyncStatus.idle);
  }
}

/// Widget pour afficher le statut de synchronisation
class SyncStatusWidget {
  static String getIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return '⏸️';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.error:
        return '❌';
      case SyncStatus.offline:
        return '📴';
    }
  }

  static int getColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 0xFF9E9E9E; // Gris
      case SyncStatus.syncing:
        return 0xFF2196F3; // Bleu
      case SyncStatus.synced:
        return 0xFF4CAF50; // Vert
      case SyncStatus.error:
        return 0xFFF44336; // Rouge
      case SyncStatus.offline:
        return 0xFFFF9800; // Orange
    }
  }
}
