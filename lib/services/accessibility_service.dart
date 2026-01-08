import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types de daltonisme supportés
enum ColorBlindnessType {
  none,
  protanopia,    // Rouge faible/absent
  deuteranopia,  // Vert faible/absent
  tritanopia,    // Bleu faible/absent
  achromatopsia, // Vision en noir et blanc
}

/// Service pour gérer l'accessibilité de l'application
class AccessibilityService {
  static const String _keyColorBlindness = 'accessibility_color_blindness';
  static const String _keyHighContrast = 'accessibility_high_contrast';
  static const String _keyFontScale = 'accessibility_font_scale';
  static const String _keyReduceAnimations = 'accessibility_reduce_animations';
  static const String _keyLargeTouch = 'accessibility_large_touch';
  static const String _keyScreenReader = 'accessibility_screen_reader';

  static SharedPreferences? _prefs;

  /// Initialise le service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== DALTONISME ====================

  /// Récupère le type de daltonisme configuré
  static ColorBlindnessType getColorBlindnessType() {
    final index = _prefs?.getInt(_keyColorBlindness) ?? 0;
    return ColorBlindnessType.values[index];
  }

  /// Définit le type de daltonisme
  static Future<void> setColorBlindnessType(ColorBlindnessType type) async {
    await _prefs?.setInt(_keyColorBlindness, type.index);
  }

  /// Adapte une couleur pour le daltonisme
  static Color adaptColorForColorBlindness(Color color, ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.none:
        return color;

      case ColorBlindnessType.protanopia:
        // Simule la protanopie (difficulté rouge)
        return _simulateProtanopia(color);

      case ColorBlindnessType.deuteranopia:
        // Simule la deutéranopie (difficulté vert)
        return _simulateDeuteranopia(color);

      case ColorBlindnessType.tritanopia:
        // Simule la tritanopie (difficulté bleu)
        return _simulateTritanopia(color);

      case ColorBlindnessType.achromatopsia:
        // Vision en niveaux de gris
        final gray = (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114).round();
        return Color.fromARGB(color.alpha, gray, gray, gray);
    }
  }

  static Color _simulateProtanopia(Color color) {
    // Matrice de transformation pour protanopie
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final newR = (0.567 * r + 0.433 * g + 0.0 * b).clamp(0.0, 1.0);
    final newG = (0.558 * r + 0.442 * g + 0.0 * b).clamp(0.0, 1.0);
    final newB = (0.0 * r + 0.242 * g + 0.758 * b).clamp(0.0, 1.0);

    return Color.fromARGB(
      color.alpha,
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
    );
  }

  static Color _simulateDeuteranopia(Color color) {
    // Matrice de transformation pour deutéranopie
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final newR = (0.625 * r + 0.375 * g + 0.0 * b).clamp(0.0, 1.0);
    final newG = (0.7 * r + 0.3 * g + 0.0 * b).clamp(0.0, 1.0);
    final newB = (0.0 * r + 0.3 * g + 0.7 * b).clamp(0.0, 1.0);

    return Color.fromARGB(
      color.alpha,
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
    );
  }

  static Color _simulateTritanopia(Color color) {
    // Matrice de transformation pour tritanopie
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final newR = (0.95 * r + 0.05 * g + 0.0 * b).clamp(0.0, 1.0);
    final newG = (0.0 * r + 0.433 * g + 0.567 * b).clamp(0.0, 1.0);
    final newB = (0.0 * r + 0.475 * g + 0.525 * b).clamp(0.0, 1.0);

    return Color.fromARGB(
      color.alpha,
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
    );
  }

  // ==================== CONTRASTE ÉLEVÉ ====================

  /// Vérifie si le mode contraste élevé est activé
  static bool isHighContrastEnabled() {
    return _prefs?.getBool(_keyHighContrast) ?? false;
  }

  /// Active/désactive le mode contraste élevé
  static Future<void> setHighContrast(bool enabled) async {
    await _prefs?.setBool(_keyHighContrast, enabled);
  }

  // ==================== TAILLE DE POLICE ====================

  /// Récupère l'échelle de police (1.0 = normal)
  static double getFontScale() {
    return _prefs?.getDouble(_keyFontScale) ?? 1.0;
  }

  /// Définit l'échelle de police
  static Future<void> setFontScale(double scale) async {
    await _prefs?.setDouble(_keyFontScale, scale.clamp(0.8, 2.0));
  }

  // ==================== ANIMATIONS RÉDUITES ====================

  /// Vérifie si les animations réduites sont activées
  static bool isReduceAnimationsEnabled() {
    return _prefs?.getBool(_keyReduceAnimations) ?? false;
  }

  /// Active/désactive les animations réduites
  static Future<void> setReduceAnimations(bool enabled) async {
    await _prefs?.setBool(_keyReduceAnimations, enabled);
  }

  // ==================== ZONES TACTILES AGRANDIES ====================

  /// Vérifie si les zones tactiles agrandies sont activées
  static bool isLargeTouchEnabled() {
    return _prefs?.getBool(_keyLargeTouch) ?? false;
  }

  /// Active/désactive les zones tactiles agrandies
  static Future<void> setLargeTouch(bool enabled) async {
    await _prefs?.setBool(_keyLargeTouch, enabled);
  }

  // ==================== LECTEUR D'ÉCRAN ====================

  /// Vérifie si le mode lecteur d'écran optimisé est activé
  static bool isScreenReaderOptimized() {
    return _prefs?.getBool(_keyScreenReader) ?? false;
  }

  /// Active/désactive le mode lecteur d'écran optimisé
  static Future<void> setScreenReaderOptimized(bool enabled) async {
    await _prefs?.setBool(_keyScreenReader, enabled);
  }

  // ==================== HELPERS ====================

  /// Retourne le nom lisible du type de daltonisme
  static String getColorBlindnessName(ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.none:
        return 'Aucun';
      case ColorBlindnessType.protanopia:
        return 'Protanopie (rouge)';
      case ColorBlindnessType.deuteranopia:
        return 'Deutéranopie (vert)';
      case ColorBlindnessType.tritanopia:
        return 'Tritanopie (bleu)';
      case ColorBlindnessType.achromatopsia:
        return 'Achromatopsie (N&B)';
    }
  }

  /// Retourne la description du type de daltonisme
  static String getColorBlindnessDescription(ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.none:
        return 'Vision des couleurs normale';
      case ColorBlindnessType.protanopia:
        return 'Difficulté à percevoir le rouge';
      case ColorBlindnessType.deuteranopia:
        return 'Difficulté à percevoir le vert';
      case ColorBlindnessType.tritanopia:
        return 'Difficulté à percevoir le bleu';
      case ColorBlindnessType.achromatopsia:
        return 'Vision en niveaux de gris uniquement';
    }
  }
}
