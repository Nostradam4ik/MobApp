import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/config/monetization_config.dart';
import 'subscription_service.dart';

/// Service de gestion des achats in-app avec RevenueCat
class PurchaseService {
  PurchaseService._();

  // Product IDs - à configurer dans RevenueCat Dashboard
  static const String productMonthly = MonetizationConfig.productMonthly;
  static const String productYearly = MonetizationConfig.productYearly;
  static const String productLifetime = MonetizationConfig.productLifetime;

  static bool _isInitialized = false;
  static CustomerInfo? _customerInfo;

  /// Initialise RevenueCat
  static Future<void> init() async {
    if (_isInitialized) return;

    // Vérifier si RevenueCat est configuré
    if (!MonetizationConfig.isRevenueCatConfigured) {
      debugPrint('PurchaseService: RevenueCat non configuré (mode simulation)');
      debugPrint('Configurez vos clés dans lib/core/config/monetization_config.dart');
      _isInitialized = true;
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(MonetizationConfig.revenueCatAndroidKey);
      } else {
        configuration = PurchasesConfiguration(MonetizationConfig.revenueCatIosKey);
      }

      await Purchases.configure(configuration);
      _isInitialized = true;

      // Écouter les changements
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        _syncSubscriptionStatus();
      });

      // Charger l'état initial
      await _loadCustomerInfo();
      debugPrint('PurchaseService initialized with RevenueCat');
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
      _isInitialized = true; // Continuer en mode dégradé
    }
  }

  /// Charge les informations client
  static Future<void> _loadCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      await _syncSubscriptionStatus();
    } catch (e) {
      debugPrint('Error loading customer info: $e');
    }
  }

  /// Synchronise le statut d'abonnement avec le local storage
  static Future<void> _syncSubscriptionStatus() async {
    if (_customerInfo == null) return;

    final isPremium = _customerInfo!.entitlements.active.containsKey('premium');

    if (isPremium) {
      final entitlement = _customerInfo!.entitlements.active['premium'];
      DateTime? expiryDate;

      if (entitlement?.expirationDate != null) {
        expiryDate = DateTime.parse(entitlement!.expirationDate!);
      }

      await SubscriptionService.activatePremium(expiryDate: expiryDate);
    } else {
      await SubscriptionService.deactivatePremium();
    }
  }

  /// Récupère les produits disponibles
  static Future<List<StoreProduct>> getProducts() async {
    if (!_isInitialized) {
      debugPrint('PurchaseService not initialized');
      return [];
    }

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null) {
        return current.availablePackages
            .map((p) => p.storeProduct)
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting products: $e');
    }

    return [];
  }

  /// Récupère les offerings
  static Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  /// Achète un produit
  static Future<PurchaseResult> purchase(Package package) async {
    if (!_isInitialized) {
      return PurchaseResult(
        success: false,
        error: 'Service non initialisé',
      );
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _customerInfo = customerInfo;
      await _syncSubscriptionStatus();

      return PurchaseResult(
        success: customerInfo.entitlements.active.containsKey('premium'),
        customerInfo: customerInfo,
      );
    } catch (e) {
      if (e is PurchasesErrorCode) {
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          return PurchaseResult(
            success: false,
            error: 'Achat annulé',
            cancelled: true,
          );
        }
      }

      debugPrint('Purchase error: $e');
      return PurchaseResult(
        success: false,
        error: 'Erreur lors de l\'achat: $e',
      );
    }
  }

  /// Restaure les achats
  static Future<PurchaseResult> restorePurchases() async {
    if (!_isInitialized) {
      return PurchaseResult(
        success: false,
        error: 'Service non initialisé',
      );
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      await _syncSubscriptionStatus();

      final hasActive = customerInfo.entitlements.active.containsKey('premium');

      return PurchaseResult(
        success: hasActive,
        customerInfo: customerInfo,
        error: hasActive ? null : 'Aucun achat trouvé',
      );
    } catch (e) {
      debugPrint('Restore error: $e');
      return PurchaseResult(
        success: false,
        error: 'Erreur lors de la restauration: $e',
      );
    }
  }

  /// Vérifie si l'utilisateur est premium
  static bool isPremium() {
    return _customerInfo?.entitlements.active.containsKey('premium') ?? false;
  }

  /// Identifie l'utilisateur (pour synchroniser entre appareils)
  static Future<void> identify(String userId) async {
    if (!_isInitialized) return;

    try {
      await Purchases.logIn(userId);
      await _loadCustomerInfo();
    } catch (e) {
      debugPrint('Identify error: $e');
    }
  }

  /// Déconnexion (remet à l'utilisateur anonyme)
  static Future<void> logout() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
      await _loadCustomerInfo();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}

/// Résultat d'un achat
class PurchaseResult {
  final bool success;
  final String? error;
  final bool cancelled;
  final CustomerInfo? customerInfo;

  PurchaseResult({
    required this.success,
    this.error,
    this.cancelled = false,
    this.customerInfo,
  });
}
