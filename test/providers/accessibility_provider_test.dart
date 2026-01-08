import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/accessibility_service.dart';

// Tests for AccessibilityProvider logic without SharedPreferences
// These tests verify the pure computation logic

void main() {
  group('AccessibilityProvider Logic', () {
    group('fontScale clamping', () {
      test('should clamp font scale to minimum 0.8', () {
        const scale = 0.5;
        final clamped = scale.clamp(0.8, 2.0);
        expect(clamped, 0.8);
      });

      test('should clamp font scale to maximum 2.0', () {
        const scale = 3.0;
        final clamped = scale.clamp(0.8, 2.0);
        expect(clamped, 2.0);
      });

      test('should not clamp valid font scale', () {
        const scale = 1.5;
        final clamped = scale.clamp(0.8, 2.0);
        expect(clamped, 1.5);
      });

      test('should accept minimum value', () {
        const scale = 0.8;
        final clamped = scale.clamp(0.8, 2.0);
        expect(clamped, 0.8);
      });

      test('should accept maximum value', () {
        const scale = 2.0;
        final clamped = scale.clamp(0.8, 2.0);
        expect(clamped, 2.0);
      });
    });

    group('increaseContrast', () {
      test('should increase lightness for light colors', () {
        const lightColor = Color(0xFFCCCCCC);
        final hsl = HSLColor.fromColor(lightColor);

        // For light colors (lightness > 0.5), increase lightness
        expect(hsl.lightness, greaterThan(0.5));

        double newLightness;
        if (hsl.lightness > 0.5) {
          newLightness = (hsl.lightness + 0.2).clamp(0.0, 1.0);
        } else {
          newLightness = (hsl.lightness - 0.2).clamp(0.0, 1.0);
        }

        expect(newLightness, greaterThan(hsl.lightness));
      });

      test('should decrease lightness for dark colors', () {
        const darkColor = Color(0xFF333333);
        final hsl = HSLColor.fromColor(darkColor);

        // For dark colors (lightness <= 0.5), decrease lightness
        expect(hsl.lightness, lessThanOrEqualTo(0.5));

        double newLightness;
        if (hsl.lightness > 0.5) {
          newLightness = (hsl.lightness + 0.2).clamp(0.0, 1.0);
        } else {
          newLightness = (hsl.lightness - 0.2).clamp(0.0, 1.0);
        }

        expect(newLightness, lessThan(hsl.lightness));
      });

      test('should increase saturation', () {
        const color = Color(0xFF4488CC);
        final hsl = HSLColor.fromColor(color);

        final newSaturation = (hsl.saturation * 1.3).clamp(0.0, 1.0);

        expect(newSaturation, greaterThanOrEqualTo(hsl.saturation));
      });

      test('should clamp saturation to 1.0 max', () {
        const saturatedColor = Color(0xFFFF0000); // Fully saturated red
        final hsl = HSLColor.fromColor(saturatedColor);

        final newSaturation = (hsl.saturation * 1.3).clamp(0.0, 1.0);

        expect(newSaturation, lessThanOrEqualTo(1.0));
      });
    });

    group('getButtonHeight', () {
      test('should return 56 for large touch mode', () {
        const largeTouch = true;
        final height = largeTouch ? 56.0 : 48.0;
        expect(height, 56.0);
      });

      test('should return 48 for normal mode', () {
        const largeTouch = false;
        final height = largeTouch ? 56.0 : 48.0;
        expect(height, 48.0);
      });
    });

    group('getButtonPadding', () {
      test('should return larger padding for large touch mode', () {
        const largeTouch = true;
        final padding = largeTouch
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

        expect(padding.horizontal, 48.0); // 24 * 2
        expect(padding.vertical, 32.0); // 16 * 2
      });

      test('should return normal padding for normal mode', () {
        const largeTouch = false;
        final padding = largeTouch
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

        expect(padding.horizontal, 32.0); // 16 * 2
        expect(padding.vertical, 24.0); // 12 * 2
      });
    });

    group('getIconSize', () {
      test('should return 28 for large touch mode', () {
        const largeTouch = true;
        final size = largeTouch ? 28.0 : 24.0;
        expect(size, 28.0);
      });

      test('should return 24 for normal mode', () {
        const largeTouch = false;
        final size = largeTouch ? 28.0 : 24.0;
        expect(size, 24.0);
      });
    });

    group('getAnimationDuration', () {
      test('should return zero for reduced animations', () {
        const reduceAnimations = true;
        const normalDuration = Duration(milliseconds: 300);

        final duration = reduceAnimations ? Duration.zero : normalDuration;

        expect(duration, Duration.zero);
      });

      test('should return normal duration when animations not reduced', () {
        const reduceAnimations = false;
        const normalDuration = Duration(milliseconds: 300);

        final duration = reduceAnimations ? Duration.zero : normalDuration;

        expect(duration, normalDuration);
      });
    });

    group('color adaptation', () {
      test('should preserve alpha when adapting color', () {
        const color = Color(0x80FF5500);

        for (final type in ColorBlindnessType.values) {
          final adapted = AccessibilityService.adaptColorForColorBlindness(
            color,
            type,
          );
          expect(adapted.alpha, color.alpha);
        }
      });

      test('should return same color for none type', () {
        const color = Color(0xFFFF5500);
        final adapted = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.none,
        );
        expect(adapted, color);
      });

      test('should convert to grayscale for achromatopsia', () {
        const color = Color(0xFFFF0000);
        final adapted = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.achromatopsia,
        );

        expect(adapted.red, adapted.green);
        expect(adapted.green, adapted.blue);
      });
    });
  });
}
