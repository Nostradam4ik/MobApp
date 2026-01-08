// ============================================================================
// SmartSpend - Provider de langue
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../l10n/app_localizations.dart';

/// Provider pour gérer la langue de l'application
class LanguageProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  // Langue par défaut: Anglais
  Locale _locale = const Locale('en', 'US');
  bool _isInitialized = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  String get languageName => AppLocalizations.getLanguageName(_locale.languageCode);
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    _loadLocale();
  }

  /// Charger la langue sauvegardée
  Future<void> _loadLocale() async {
    final savedLocale = LocalStorageService.getString(_localeKey);
    if (savedLocale != null && savedLocale.isNotEmpty) {
      final parts = savedLocale.split('_');
      if (parts.isNotEmpty) {
        _locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
      }
    }
    // Par défaut: anglais (déjà défini dans _locale)
    _isInitialized = true;
    notifyListeners();
  }

  /// Changer la langue
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    await LocalStorageService.setString(
      _localeKey,
      '${newLocale.languageCode}_${newLocale.countryCode ?? ''}'
    );
    notifyListeners();
  }

  /// Changer la langue par code
  Future<void> setLanguageCode(String code) async {
    final locale = AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => const Locale('en', 'US'),
    );
    await setLocale(locale);
  }

  /// Liste des langues disponibles
  List<Map<String, dynamic>> get availableLanguages {
    return AppLocalizations.supportedLocales.map((locale) {
      return {
        'code': locale.languageCode,
        'name': AppLocalizations.getLanguageName(locale.languageCode),
        'locale': locale,
        'flag': _getFlag(locale.languageCode),
      };
    }).toList();
  }

  /// Obtenir le drapeau emoji pour une langue
  String _getFlag(String code) {
    switch (code) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'nl':
        return '🇳🇱';
      case 'pl':
        return '🇵🇱';
      case 'uk':
        return '🇺🇦';
      case 'ru':
        return '🇷🇺';
      default:
        return '🌍';
    }
  }
}
