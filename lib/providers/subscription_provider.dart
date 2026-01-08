import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/purchase_service.dart';

/// Provider pour gérer l'état de l'abonnement
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionType _subscriptionType = SubscriptionType.free;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  SubscriptionProvider() {
    // Ne pas charger au constructeur car userId n'est pas encore disponible
  }

  /// Met à jour l'ID utilisateur et recharge l'abonnement
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        _loadSubscription();
      } else {
        // Utilisateur déconnecté, réinitialiser
        _subscriptionType = SubscriptionType.free;
        notifyListeners();
      }
    }
  }

  // Getters
  SubscriptionType get subscriptionType => _subscriptionType;
  bool get isPremium => (_subscriptionType == SubscriptionType.premium && SubscriptionService.isPremium()) || isTrialActive;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get expiryDate => SubscriptionService.getExpiryDate();
  int? get daysRemaining => SubscriptionService.getDaysRemaining();

  // Essai gratuit
  bool get hasUsedTrial => SubscriptionService.hasUsedTrial();
  bool get isTrialActive => SubscriptionService.isTrialActive();
  int get trialDaysRemaining => SubscriptionService.getTrialDaysRemaining();
  bool get canStartTrial => !hasUsedTrial;

  /// Charge l'état de l'abonnement
  void _loadSubscription() {
    _subscriptionType = SubscriptionService.getSubscriptionType();
    // Re-vérifier si vraiment premium (peut avoir expiré)
    // Mais garder premium si l'essai gratuit est actif
    if (_subscriptionType == SubscriptionType.premium &&
        !SubscriptionService.isPremium() &&
        !SubscriptionService.isTrialActive()) {
      _subscriptionType = SubscriptionType.free;
    }
    // Si l'essai est actif, s'assurer que le type est premium
    if (SubscriptionService.isTrialActive()) {
      _subscriptionType = SubscriptionType.premium;
    }
    notifyListeners();
  }

  /// Recharge l'état de l'abonnement
  void refresh() {
    _loadSubscription();
  }

  /// Vérifie si une fonctionnalité premium est disponible
  bool hasFeature(PremiumFeature feature) {
    return isPremium;
  }

  /// Vérifie si on peut ajouter une catégorie
  bool canAddCategory(int currentCount) {
    return SubscriptionService.canAddCategory(currentCount);
  }

  /// Vérifie si on peut ajouter un budget
  bool canAddBudget(int currentCount) {
    return SubscriptionService.canAddBudget(currentCount);
  }

  /// Vérifie si on peut ajouter un objectif
  bool canAddGoal(int currentCount) {
    return SubscriptionService.canAddGoal(currentCount);
  }

  /// Récupère le message de limite
  String getLimitMessage(PremiumFeature feature) {
    return SubscriptionService.getLimitMessage(feature);
  }

  /// Active l'abonnement premium (après achat réussi)
  Future<void> activatePremium({DateTime? expiryDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SubscriptionService.activatePremium(expiryDate: expiryDate);
      _subscriptionType = SubscriptionType.premium;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'activation Premium';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Désactive l'abonnement premium
  Future<void> deactivatePremium() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SubscriptionService.deactivatePremium();
      _subscriptionType = SubscriptionType.free;
    } catch (e) {
      _error = 'Erreur lors de la désactivation';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Restaure les achats (pour iOS/Android)
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PurchaseService.restorePurchases();

      if (result.success) {
        _subscriptionType = SubscriptionType.premium;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? 'Aucun achat trouvé';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors de la restauration';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Active l'essai gratuit de 7 jours
  Future<bool> startFreeTrial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await SubscriptionService.startFreeTrial();
      if (success) {
        _subscriptionType = SubscriptionType.premium;
      } else {
        _error = 'L\'essai gratuit a déjà été utilisé';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Erreur lors de l\'activation de l\'essai';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
