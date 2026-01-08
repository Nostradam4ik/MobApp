import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Provider pour gérer l'état de l'accessibilité
class AccessibilityProvider extends ChangeNotifier {
  ColorBlindnessType _colorBlindnessType = ColorBlindnessType.none;
  bool _highContrast = false;
  double _fontScale = 1.0;
  bool _reduceAnimations = false;
  bool _largeTouch = false;
  bool _screenReaderOptimized = false;

  // Getters
  ColorBlindnessType get colorBlindnessType => _colorBlindnessType;
  bool get highContrast => _highContrast;
  double get fontScale => _fontScale;
  bool get reduceAnimations => _reduceAnimations;
  bool get largeTouch => _largeTouch;
  bool get screenReaderOptimized => _screenReaderOptimized;

  /// Charge les paramètres sauvegardés
  Future<void> loadSettings() async {
    await AccessibilityService.init();
    _colorBlindnessType = AccessibilityService.getColorBlindnessType();
    _highContrast = AccessibilityService.isHighContrastEnabled();
    _fontScale = AccessibilityService.getFontScale();
    _reduceAnimations = AccessibilityService.isReduceAnimationsEnabled();
    _largeTouch = AccessibilityService.isLargeTouchEnabled();
    _screenReaderOptimized = AccessibilityService.isScreenReaderOptimized();
    notifyListeners();
  }

  /// Définit le type de daltonisme
  Future<void> setColorBlindnessType(ColorBlindnessType type) async {
    _colorBlindnessType = type;
    await AccessibilityService.setColorBlindnessType(type);
    notifyListeners();
  }

  /// Active/désactive le mode contraste élevé
  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    await AccessibilityService.setHighContrast(enabled);
    notifyListeners();
  }

  /// Définit l'échelle de police
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 2.0);
    await AccessibilityService.setFontScale(_fontScale);
    notifyListeners();
  }

  /// Active/désactive les animations réduites
  Future<void> setReduceAnimations(bool enabled) async {
    _reduceAnimations = enabled;
    await AccessibilityService.setReduceAnimations(enabled);
    notifyListeners();
  }

  /// Active/désactive les zones tactiles agrandies
  Future<void> setLargeTouch(bool enabled) async {
    _largeTouch = enabled;
    await AccessibilityService.setLargeTouch(enabled);
    notifyListeners();
  }

  /// Active/désactive le mode lecteur d'écran optimisé
  Future<void> setScreenReaderOptimized(bool enabled) async {
    _screenReaderOptimized = enabled;
    await AccessibilityService.setScreenReaderOptimized(enabled);
    notifyListeners();
  }

  /// Adapte une couleur selon les paramètres d'accessibilité
  Color adaptColor(Color color) {
    Color adapted = AccessibilityService.adaptColorForColorBlindness(
      color,
      _colorBlindnessType,
    );

    // Si contraste élevé, augmenter la saturation
    if (_highContrast) {
      adapted = _increaseContrast(adapted);
    }

    return adapted;
  }

  Color _increaseContrast(Color color) {
    // Convertir en HSL pour ajuster la luminosité
    final hsl = HSLColor.fromColor(color);

    // Pousser la luminosité vers les extrêmes
    double newLightness;
    if (hsl.lightness > 0.5) {
      newLightness = (hsl.lightness + 0.2).clamp(0.0, 1.0);
    } else {
      newLightness = (hsl.lightness - 0.2).clamp(0.0, 1.0);
    }

    // Augmenter la saturation
    final newSaturation = (hsl.saturation * 1.3).clamp(0.0, 1.0);

    return hsl
        .withLightness(newLightness)
        .withSaturation(newSaturation)
        .toColor();
  }

  /// Retourne la taille de bouton appropriée
  double getButtonHeight() {
    return _largeTouch ? 56.0 : 48.0;
  }

  /// Retourne le padding de bouton approprié
  EdgeInsets getButtonPadding() {
    return _largeTouch
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  /// Retourne la taille d'icône appropriée
  double getIconSize() {
    return _largeTouch ? 28.0 : 24.0;
  }

  /// Retourne la durée d'animation appropriée
  Duration getAnimationDuration(Duration normalDuration) {
    if (_reduceAnimations) {
      return Duration.zero;
    }
    return normalDuration;
  }

  /// Réinitialise tous les paramètres d'accessibilité
  Future<void> resetAll() async {
    await setColorBlindnessType(ColorBlindnessType.none);
    await setHighContrast(false);
    await setFontScale(1.0);
    await setReduceAnimations(false);
    await setLargeTouch(false);
    await setScreenReaderOptimized(false);
  }
}
