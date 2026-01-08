import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Types d'abonnement
enum SubscriptionType {
  free('free', 'Gratuit'),
  premium('premium', 'Premium');

  const SubscriptionType(this.value, this.label);
  final String value;
  final String label;

  static SubscriptionType fromString(String value) {
    return SubscriptionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionType.free,
    );
  }
}

/// Limites pour la version gratuite
class FreeLimits {
  FreeLimits._();

  static const int maxCategories = 5;
  static const int maxBudgets = 1;
  static const int maxGoals = 1;
  static const int maxNotificationReminders = 1;
}

/// Fonctionnalités premium
enum PremiumFeature {
  unlimitedCategories('unlimited_categories', 'Catégories illimitées'),
  unlimitedBudgets('unlimited_budgets', 'Budgets illimités'),
  unlimitedGoals('unlimited_goals', 'Objectifs illimités'),
  advancedStats('advanced_stats', 'Graphiques avancés'),
  importCsv('import_csv', 'Import CSV'),
  exportData('export_data', 'Export données'),
  cloudSync('cloud_sync', 'Synchronisation cloud'),
  currencyConversion('currency_conversion', 'Conversion devises'),
  recurringExpenses('recurring_expenses', 'Dépenses récurrentes'),
  allNotifications('all_notifications', 'Toutes les notifications'),
  noAds('no_ads', 'Sans publicités');

  const PremiumFeature(this.value, this.label);
  final String value;
  final String label;
}

/// Service de gestion des abonnements
class SubscriptionService {
  SubscriptionService._();

  static const String _keySubscriptionType = 'subscription_type';
  static const String _keySubscriptionExpiry = 'subscription_expiry';
  static const String _keyPurchaseDate = 'purchase_date';
  static const String _keyTrialUsed = 'trial_used';
  static const String _keyTrialStartDate = 'trial_start_date';
  static const int trialDays = 7;

  /// Génère une clé liée à l'utilisateur
  static String _userKey(String baseKey) {
    final userId = SupabaseService.userId;
    if (userId != null) {
      return '${baseKey}_$userId';
    }
    return baseKey;
  }

  /// Récupère le type d'abonnement actuel
  static SubscriptionType getSubscriptionType() {
    final typeStr = LocalStorageService.getString(_userKey(_keySubscriptionType));
    return SubscriptionType.fromString(typeStr ?? 'free');
  }

  /// Vérifie si l'utilisateur est premium
  static bool isPremium() {
    final type = getSubscriptionType();
    if (type == SubscriptionType.free) return false;

    // Vérifier si l'abonnement n'a pas expiré
    final expiryStr = LocalStorageService.getString(_userKey(_keySubscriptionExpiry));
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        // Abonnement expiré, réinitialiser à gratuit
        _resetToFree();
        return false;
      }
    }

    return true;
  }

  /// Vérifie si une fonctionnalité premium est disponible
  static bool hasFeature(PremiumFeature feature) {
    return isPremium();
  }

  /// Vérifie si on peut ajouter une nouvelle catégorie
  static bool canAddCategory(int currentCount) {
    if (isPremium()) return true;
    return currentCount < FreeLimits.maxCategories;
  }

  /// Vérifie si on peut ajouter un nouveau budget
  static bool canAddBudget(int currentCount) {
    if (isPremium()) return true;
    return currentCount < FreeLimits.maxBudgets;
  }

  /// Vérifie si on peut ajouter un nouvel objectif
  static bool canAddGoal(int currentCount) {
    if (isPremium()) return true;
    return currentCount < FreeLimits.maxGoals;
  }

  /// Active l'abonnement premium (pour les tests ou après achat)
  static Future<void> activatePremium({
    DateTime? expiryDate,
  }) async {
    await LocalStorageService.setString(_userKey(_keySubscriptionType), 'premium');
    await LocalStorageService.setString(
      _userKey(_keyPurchaseDate),
      DateTime.now().toIso8601String(),
    );

    if (expiryDate != null) {
      await LocalStorageService.setString(
        _userKey(_keySubscriptionExpiry),
        expiryDate.toIso8601String(),
      );
    }

    debugPrint('Premium activated!');
  }

  /// Désactive l'abonnement premium
  static Future<void> deactivatePremium() async {
    await _resetToFree();
  }

  /// Réinitialise à la version gratuite
  static Future<void> _resetToFree() async {
    await LocalStorageService.setString(_userKey(_keySubscriptionType), 'free');
    await LocalStorageService.remove(_userKey(_keySubscriptionExpiry));
    await LocalStorageService.remove(_userKey(_keyPurchaseDate));
  }

  /// Récupère la date d'expiration de l'abonnement
  static DateTime? getExpiryDate() {
    final expiryStr = LocalStorageService.getString(_userKey(_keySubscriptionExpiry));
    return expiryStr != null ? DateTime.tryParse(expiryStr) : null;
  }

  /// Récupère la date d'achat
  static DateTime? getPurchaseDate() {
    final dateStr = LocalStorageService.getString(_userKey(_keyPurchaseDate));
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  /// Nombre de jours restants avant expiration
  static int? getDaysRemaining() {
    final expiry = getExpiryDate();
    if (expiry == null) return null; // Abonnement à vie

    final now = DateTime.now();
    if (expiry.isBefore(now)) return 0;

    return expiry.difference(now).inDays;
  }

  // ==================== ESSAI GRATUIT ====================

  /// Vérifie si l'essai gratuit a déjà été utilisé
  static bool hasUsedTrial() {
    return LocalStorageService.getBool(_userKey(_keyTrialUsed)) ?? false;
  }

  /// Vérifie si l'essai gratuit est actuellement actif
  static bool isTrialActive() {
    final trialStartStr = LocalStorageService.getString(_userKey(_keyTrialStartDate));
    if (trialStartStr == null) return false;

    final trialStart = DateTime.tryParse(trialStartStr);
    if (trialStart == null) return false;

    final trialEnd = trialStart.add(Duration(days: trialDays));
    return DateTime.now().isBefore(trialEnd);
  }

  /// Jours restants de l'essai gratuit
  static int getTrialDaysRemaining() {
    final trialStartStr = LocalStorageService.getString(_userKey(_keyTrialStartDate));
    if (trialStartStr == null) return 0;

    final trialStart = DateTime.tryParse(trialStartStr);
    if (trialStart == null) return 0;

    final trialEnd = trialStart.add(Duration(days: trialDays));
    final remaining = trialEnd.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Active l'essai gratuit de 7 jours
  static Future<bool> startFreeTrial() async {
    if (hasUsedTrial()) {
      debugPrint('Trial already used');
      return false;
    }

    await LocalStorageService.setBool(_userKey(_keyTrialUsed), true);
    await LocalStorageService.setString(
      _userKey(_keyTrialStartDate),
      DateTime.now().toIso8601String(),
    );
    await LocalStorageService.setString(_userKey(_keySubscriptionType), 'premium');
    await LocalStorageService.setString(
      _userKey(_keySubscriptionExpiry),
      DateTime.now().add(Duration(days: trialDays)).toIso8601String(),
    );

    debugPrint('Free trial started!');
    return true;
  }

  /// Message de limite atteinte
  static String getLimitMessage(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.unlimitedCategories:
        return 'Vous avez atteint la limite de ${FreeLimits.maxCategories} catégories. Passez à Premium pour en créer plus !';
      case PremiumFeature.unlimitedBudgets:
        return 'Vous avez atteint la limite de ${FreeLimits.maxBudgets} budget. Passez à Premium pour en créer plus !';
      case PremiumFeature.unlimitedGoals:
        return 'Vous avez atteint la limite de ${FreeLimits.maxGoals} objectif. Passez à Premium pour en créer plus !';
      case PremiumFeature.advancedStats:
        return 'Les graphiques avancés sont une fonctionnalité Premium.';
      case PremiumFeature.importCsv:
        return 'L\'import CSV est une fonctionnalité Premium.';
      case PremiumFeature.exportData:
        return 'L\'export de données est une fonctionnalité Premium.';
      case PremiumFeature.cloudSync:
        return 'La synchronisation cloud est une fonctionnalité Premium.';
      case PremiumFeature.currencyConversion:
        return 'La conversion de devises est une fonctionnalité Premium.';
      case PremiumFeature.recurringExpenses:
        return 'Les dépenses récurrentes sont une fonctionnalité Premium.';
      case PremiumFeature.allNotifications:
        return 'Les notifications personnalisées sont une fonctionnalité Premium.';
      case PremiumFeature.noAds:
        return 'Passez à Premium pour supprimer les publicités.';
    }
  }
}
