import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service de taux de change en temps réel
/// Utilise une API gratuite pour les taux de change
class ExchangeRateService {
  static ExchangeRateService? _instance;

  // Cache local
  Map<String, double> _rates = {};
  DateTime? _lastUpdate;
  String _baseCurrency = 'EUR';

  // Configuration
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _refreshInterval = Duration(hours: 6);
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _lastUpdateKey = 'exchange_rates_last_update';

  // API gratuite (exchangerate-api.com - 1500 requêtes/mois gratuit)
  // Alternative: frankfurter.app (gratuit, illimité)
  static const String _apiBaseUrl = 'https://api.frankfurter.app';

  Timer? _refreshTimer;

  ExchangeRateService._();

  static Future<ExchangeRateService> getInstance() async {
    if (_instance == null) {
      _instance = ExchangeRateService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    // Charger le cache local
    await _loadFromCache();

    // Rafraîchir si nécessaire
    if (_shouldRefresh()) {
      await refreshRates();
    }

    // Démarrer le timer de rafraîchissement automatique
    _startAutoRefresh();
  }

  // ==================== TAUX DE CHANGE ====================

  /// Obtient le taux de change entre deux devises
  Future<double?> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;

    // Vérifier le cache
    if (_shouldRefresh()) {
      await refreshRates();
    }

    // Calculer le taux
    if (_baseCurrency == from) {
      return _rates[to];
    } else if (_baseCurrency == to) {
      final fromRate = _rates[from];
      if (fromRate != null && fromRate > 0) {
        return 1 / fromRate;
      }
    } else {
      // Conversion via la devise de base
      final fromRate = _rates[from];
      final toRate = _rates[to];
      if (fromRate != null && toRate != null && fromRate > 0) {
        return toRate / fromRate;
      }
    }

    return null;
  }

  /// Convertit un montant d'une devise à une autre
  Future<ConversionResult> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) {
      return ConversionResult(
        originalAmount: amount,
        convertedAmount: amount,
        fromCurrency: from,
        toCurrency: to,
        rate: 1.0,
        rateDate: _lastUpdate ?? DateTime.now(),
      );
    }

    final rate = await getExchangeRate(from, to);
    if (rate == null) {
      return ConversionResult.error(
        'Impossible d\'obtenir le taux de change $from → $to',
      );
    }

    return ConversionResult(
      originalAmount: amount,
      convertedAmount: amount * rate,
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
      rateDate: _lastUpdate ?? DateTime.now(),
    );
  }

  /// Obtient tous les taux disponibles
  Map<String, double> getAllRates() {
    return Map.from(_rates);
  }

  /// Obtient les devises supportées
  List<String> getSupportedCurrencies() {
    return ['EUR', ..._rates.keys.toList()..sort()];
  }

  /// Rafraîchit les taux de change depuis l'API
  Future<bool> refreshRates({String? baseCurrency}) async {
    final base = baseCurrency ?? _baseCurrency;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/latest?from=$base'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        _rates = rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        _baseCurrency = base;
        _lastUpdate = DateTime.now();

        // Sauvegarder dans le cache
        await _saveToCache();

        return true;
      }
    } catch (e) {
      // En cas d'erreur, garder les anciennes valeurs
      print('Erreur de rafraîchissement des taux: $e');
    }

    return false;
  }

  /// Change la devise de base
  Future<void> setBaseCurrency(String currency) async {
    if (_baseCurrency != currency) {
      _baseCurrency = currency;
      await refreshRates(baseCurrency: currency);
    }
  }

  // ==================== HISTORIQUE ====================

  /// Obtient les taux historiques pour une date
  Future<Map<String, double>?> getHistoricalRates(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$dateStr?from=$_baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (e) {
      print('Erreur de récupération des taux historiques: $e');
    }

    return null;
  }

  /// Obtient l'évolution d'une paire de devises
  Future<List<RateHistory>> getRateHistory({
    required String from,
    required String to,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$startStr..$endStr?from=$from&to=$to'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        final history = <RateHistory>[];
        rates.forEach((dateStr, ratesData) {
          final rateMap = ratesData as Map<String, dynamic>;
          if (rateMap.containsKey(to)) {
            history.add(RateHistory(
              date: DateTime.parse(dateStr),
              rate: (rateMap[to] as num).toDouble(),
            ));
          }
        });

        history.sort((a, b) => a.date.compareTo(b.date));
        return history;
      }
    } catch (e) {
      print('Erreur de récupération de l\'historique: $e');
    }

    return [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==================== CACHE ====================

  bool _shouldRefresh() {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) > _cacheExpiry;
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (cacheJson != null && lastUpdateStr != null) {
        final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
        _rates = cache['rates'] != null
            ? (cache['rates'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, (v as num).toDouble()))
            : {};
        _baseCurrency = cache['base'] as String? ?? 'EUR';
        _lastUpdate = DateTime.tryParse(lastUpdateStr);
      }
    } catch (e) {
      print('Erreur de chargement du cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = {
        'rates': _rates,
        'base': _baseCurrency,
      };
      await prefs.setString(_cacheKey, jsonEncode(cache));
      await prefs.setString(_lastUpdateKey, _lastUpdate?.toIso8601String() ?? '');
    } catch (e) {
      print('Erreur de sauvegarde du cache: $e');
    }
  }

  // ==================== AUTO-REFRESH ====================

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      refreshRates();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ==================== INFORMATIONS ====================

  /// Dernière mise à jour des taux
  DateTime? get lastUpdate => _lastUpdate;

  /// Devise de base actuelle
  String get baseCurrency => _baseCurrency;

  /// Vérifie si les taux sont disponibles
  bool get hasRates => _rates.isNotEmpty;

  /// Vérifie si les taux sont à jour
  bool get isUpToDate => !_shouldRefresh();

  void dispose() {
    stopAutoRefresh();
  }
}

/// Résultat de conversion
class ConversionResult {
  final bool success;
  final double originalAmount;
  final double convertedAmount;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime rateDate;
  final String? errorMessage;

  const ConversionResult({
    this.success = true,
    required this.originalAmount,
    required this.convertedAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.rateDate,
    this.errorMessage,
  });

  factory ConversionResult.error(String message) {
    return ConversionResult(
      success: false,
      originalAmount: 0,
      convertedAmount: 0,
      fromCurrency: '',
      toCurrency: '',
      rate: 0,
      rateDate: DateTime.now(),
      errorMessage: message,
    );
  }

  /// Montant formaté avec le symbole de devise
  String get formattedResult => '${convertedAmount.toStringAsFixed(2)} $toCurrency';

  /// Taux formaté
  String get formattedRate => '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency';
}

/// Point d'historique de taux
class RateHistory {
  final DateTime date;
  final double rate;

  const RateHistory({
    required this.date,
    required this.rate,
  });
}

/// Informations sur une devise
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  static const Map<String, CurrencyInfo> currencies = {
    'EUR': CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    'USD': CurrencyInfo(code: 'USD', name: 'Dollar américain', symbol: '\$', flag: '🇺🇸'),
    'GBP': CurrencyInfo(code: 'GBP', name: 'Livre sterling', symbol: '£', flag: '🇬🇧'),
    'CHF': CurrencyInfo(code: 'CHF', name: 'Franc suisse', symbol: 'CHF', flag: '🇨🇭'),
    'CAD': CurrencyInfo(code: 'CAD', name: 'Dollar canadien', symbol: 'CA\$', flag: '🇨🇦'),
    'JPY': CurrencyInfo(code: 'JPY', name: 'Yen japonais', symbol: '¥', flag: '🇯🇵'),
    'AUD': CurrencyInfo(code: 'AUD', name: 'Dollar australien', symbol: 'A\$', flag: '🇦🇺'),
    'CNY': CurrencyInfo(code: 'CNY', name: 'Yuan chinois', symbol: '¥', flag: '🇨🇳'),
    'INR': CurrencyInfo(code: 'INR', name: 'Roupie indienne', symbol: '₹', flag: '🇮🇳'),
    'MAD': CurrencyInfo(code: 'MAD', name: 'Dirham marocain', symbol: 'DH', flag: '🇲🇦'),
    'XOF': CurrencyInfo(code: 'XOF', name: 'Franc CFA', symbol: 'CFA', flag: '🌍'),
    'TND': CurrencyInfo(code: 'TND', name: 'Dinar tunisien', symbol: 'DT', flag: '🇹🇳'),
    'DZD': CurrencyInfo(code: 'DZD', name: 'Dinar algérien', symbol: 'DA', flag: '🇩🇿'),
  };

  static CurrencyInfo? get(String code) => currencies[code];
}
