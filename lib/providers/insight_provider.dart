import 'package:flutter/material.dart';
import '../data/models/insight.dart';
import '../services/supabase_service.dart';

/// Provider pour la gestion des insights
class InsightProvider extends ChangeNotifier {
  List<Insight> _insights = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Insight> get insights => _insights;
  List<Insight> get unreadInsights => _insights.where((i) => !i.isRead).toList();
  List<Insight> get validInsights => _insights.where((i) => i.isValid).toList();
  int get unreadCount => unreadInsights.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Met à jour l'ID utilisateur
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadInsights();
      } else {
        _insights = [];
        notifyListeners();
      }
    }
  }

  /// Charge les insights
  Future<void> loadInsights() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await SupabaseService.getInsights();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des conseils';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marque un insight comme lu
  Future<void> markAsRead(String id) async {
    try {
      await SupabaseService.markInsightAsRead(id);
      final index = _insights.indexWhere((i) => i.id == id);
      if (index != -1) {
        _insights[index] = _insights[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking insight as read: $e');
    }
  }

  /// Masque un insight
  Future<void> dismiss(String id) async {
    try {
      await SupabaseService.dismissInsight(id);
      _insights.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error dismissing insight: $e');
    }
  }

  /// Marque tous les insights comme lus
  Future<void> markAllAsRead() async {
    for (final insight in unreadInsights) {
      await markAsRead(insight.id);
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
