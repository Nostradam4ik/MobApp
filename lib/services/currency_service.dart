import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle de devise
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'flag': flag,
      };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'],
        name: json['name'],
        symbol: json['symbol'],
        flag: json['flag'],
      );
}

/// Service de gestion des devises
class CurrencyService {
  static const String _primaryCurrencyKey = 'primary_currency';
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdateKey = 'exchange_rates_last_update';

  // Devises supportées
  static const List<Currency> supportedCurrencies = [
    Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    Currency(code: 'USD', name: 'Dollar américain', symbol: '\$', flag: '🇺🇸'),
    Currency(code: 'GBP', name: 'Livre sterling', symbol: '£', flag: '🇬🇧'),
    Currency(code: 'CHF', name: 'Franc suisse', symbol: 'CHF', flag: '🇨🇭'),
    Currency(code: 'CAD', name: 'Dollar canadien', symbol: 'CA\$', flag: '🇨🇦'),
    Currency(code: 'JPY', name: 'Yen japonais', symbol: '¥', flag: '🇯🇵'),
    Currency(code: 'CNY', name: 'Yuan chinois', symbol: '¥', flag: '🇨🇳'),
    Currency(code: 'AUD', name: 'Dollar australien', symbol: 'A\$', flag: '🇦🇺'),
    Currency(code: 'INR', name: 'Roupie indienne', symbol: '₹', flag: '🇮🇳'),
    Currency(code: 'BRL', name: 'Real brésilien', symbol: 'R\$', flag: '🇧🇷'),
    Currency(code: 'MAD', name: 'Dirham marocain', symbol: 'DH', flag: '🇲🇦'),
    Currency(code: 'TND', name: 'Dinar tunisien', symbol: 'DT', flag: '🇹🇳'),
    Currency(code: 'XOF', name: 'Franc CFA', symbol: 'CFA', flag: '🌍'),
  ];

  // Taux de change par défaut (basés sur EUR)
  static Map<String, double> _defaultRates = {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.86,
    'CHF': 0.95,
    'CAD': 1.47,
    'JPY': 162.50,
    'CNY': 7.82,
    'AUD': 1.66,
    'INR': 90.20,
    'BRL': 5.35,
    'MAD': 10.85,
    'TND': 3.38,
    'XOF': 655.96,
  };

  static Map<String, double> _exchangeRates = Map.from(_defaultRates);
  static Currency _primaryCurrency = supportedCurrencies[0]; // EUR par défaut

  /// Initialise le service
  static Future<void> init() async {
    await _loadPrimaryCurrency();
    await _loadExchangeRates();
  }

  /// Charge la devise principale
  static Future<void> _loadPrimaryCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_primaryCurrencyKey);
    if (code != null) {
      _primaryCurrency = supportedCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => supportedCurrencies[0],
      );
    }
  }

  /// Charge les taux de change
  static Future<void> _loadExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_exchangeRatesKey);
    if (ratesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(ratesJson);
      _exchangeRates = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    // Mettre à jour si les taux ont plus de 24h
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastUpdate > 24 * 60 * 60 * 1000) {
      await refreshExchangeRates();
    }
  }

  /// Devise principale
  static Currency get primaryCurrency => _primaryCurrency;

  /// Définit la devise principale
  static Future<void> setPrimaryCurrency(Currency currency) async {
    _primaryCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryCurrencyKey, currency.code);
  }

  /// Taux de change
  static Map<String, double> get exchangeRates => Map.unmodifiable(_exchangeRates);

  /// Obtient le taux de change entre deux devises
  static double getExchangeRate(String from, String to) {
    if (from == to) return 1.0;

    final fromRate = _exchangeRates[from] ?? 1.0;
    final toRate = _exchangeRates[to] ?? 1.0;

    // Convertir via EUR (base)
    return toRate / fromRate;
  }

  /// Convertit un montant
  static double convert(double amount, String from, String to) {
    return amount * getExchangeRate(from, to);
  }

  /// Formate un montant avec sa devise
  static String format(double amount, {String? currencyCode}) {
    final code = currencyCode ?? _primaryCurrency.code;
    final currency = supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => _primaryCurrency,
    );

    // Format selon la devise
    String formatted;
    if (code == 'JPY') {
      formatted = amount.round().toString();
    } else {
      formatted = amount.toStringAsFixed(2);
    }

    // Ajouter les séparateurs de milliers
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    formatted = parts.length > 1 ? '$intPart,${parts[1]}' : intPart;

    // Position du symbole
    switch (code) {
      case 'USD':
      case 'GBP':
      case 'CAD':
      case 'AUD':
        return '${currency.symbol}$formatted';
      default:
        return '$formatted ${currency.symbol}';
    }
  }

  /// Rafraîchit les taux de change depuis une API
  static Future<bool> refreshExchangeRates() async {
    try {
      // Utiliser une API gratuite de taux de change
      // Note: En production, utiliser une clé API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/EUR'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        for (final currency in supportedCurrencies) {
          if (rates.containsKey(currency.code)) {
            _exchangeRates[currency.code] = (rates[currency.code] as num).toDouble();
          }
        }

        // Sauvegarder
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_exchangeRatesKey, jsonEncode(_exchangeRates));
        await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

        return true;
      }
    } catch (e) {
      // Utiliser les taux par défaut en cas d'erreur
      print('Erreur de mise à jour des taux: $e');
    }
    return false;
  }

  /// Obtient la date de dernière mise à jour
  static Future<DateTime?> getLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Obtient une devise par son code
  static Currency? getCurrency(String code) {
    try {
      return supportedCurrencies.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }
}
