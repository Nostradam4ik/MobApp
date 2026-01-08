import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Service de stockage local
class LocalStorageService {
  LocalStorageService._();

  static SharedPreferences? _prefs;

  /// Initialise le service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Récupère les SharedPreferences
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Theme
  static Future<void> setThemeMode(String mode) async {
    await prefs.setString(AppConstants.keyThemeMode, mode);
  }

  static String getThemeMode() {
    return prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  // Onboarding
  static Future<void> setOnboardingComplete(bool complete) async {
    await prefs.setBool(AppConstants.keyOnboardingComplete, complete);
  }

  static bool isOnboardingComplete() {
    return prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  // Notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  static bool areNotificationsEnabled() {
    return prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  // Last sync
  static Future<void> setLastSyncDate(DateTime date) async {
    await prefs.setString(AppConstants.keyLastSyncDate, date.toIso8601String());
  }

  static DateTime? getLastSyncDate() {
    final dateStr = prefs.getString(AppConstants.keyLastSyncDate);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // Generic methods
  static Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  static String? getString(String key) {
    return prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    await prefs.clear();
  }
}
