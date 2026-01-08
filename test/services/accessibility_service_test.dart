import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/accessibility_service.dart';

void main() {
  group('ColorBlindnessType', () {
    test('should have 5 types', () {
      expect(ColorBlindnessType.values.length, 5);
    });

    test('should have correct types', () {
      expect(ColorBlindnessType.none, isNotNull);
      expect(ColorBlindnessType.protanopia, isNotNull);
      expect(ColorBlindnessType.deuteranopia, isNotNull);
      expect(ColorBlindnessType.tritanopia, isNotNull);
      expect(ColorBlindnessType.achromatopsia, isNotNull);
    });
  });

  group('AccessibilityService', () {
    group('getColorBlindnessName', () {
      test('should return correct names for each type', () {
        expect(
          AccessibilityService.getColorBlindnessName(ColorBlindnessType.none),
          'Aucun',
        );
        expect(
          AccessibilityService.getColorBlindnessName(ColorBlindnessType.protanopia),
          'Protanopie (rouge)',
        );
        expect(
          AccessibilityService.getColorBlindnessName(ColorBlindnessType.deuteranopia),
          'Deutéranopie (vert)',
        );
        expect(
          AccessibilityService.getColorBlindnessName(ColorBlindnessType.tritanopia),
          'Tritanopie (bleu)',
        );
        expect(
          AccessibilityService.getColorBlindnessName(ColorBlindnessType.achromatopsia),
          'Achromatopsie (N&B)',
        );
      });
    });

    group('getColorBlindnessDescription', () {
      test('should return correct descriptions for each type', () {
        expect(
          AccessibilityService.getColorBlindnessDescription(ColorBlindnessType.none),
          'Vision des couleurs normale',
        );
        expect(
          AccessibilityService.getColorBlindnessDescription(ColorBlindnessType.protanopia),
          'Difficulté à percevoir le rouge',
        );
        expect(
          AccessibilityService.getColorBlindnessDescription(ColorBlindnessType.deuteranopia),
          'Difficulté à percevoir le vert',
        );
        expect(
          AccessibilityService.getColorBlindnessDescription(ColorBlindnessType.tritanopia),
          'Difficulté à percevoir le bleu',
        );
        expect(
          AccessibilityService.getColorBlindnessDescription(ColorBlindnessType.achromatopsia),
          'Vision en niveaux de gris uniquement',
        );
      });
    });

    group('adaptColorForColorBlindness', () {
      test('should return same color for none type', () {
        const color = Color(0xFFFF0000);
        final result = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.none,
        );
        expect(result, color);
      });

      test('should transform color for protanopia', () {
        const color = Color(0xFFFF0000); // Pure red
        final result = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.protanopia,
        );
        // Should be different from original
        expect(result, isNot(color));
        // Should have alpha preserved
        expect(result.alpha, color.alpha);
      });

      test('should transform color for deuteranopia', () {
        const color = Color(0xFF00FF00); // Pure green
        final result = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.deuteranopia,
        );
        expect(result, isNot(color));
        expect(result.alpha, color.alpha);
      });

      test('should transform color for tritanopia', () {
        const color = Color(0xFF0000FF); // Pure blue
        final result = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.tritanopia,
        );
        expect(result, isNot(color));
        expect(result.alpha, color.alpha);
      });

      test('should convert to grayscale for achromatopsia', () {
        const color = Color(0xFFFF0000); // Pure red
        final result = AccessibilityService.adaptColorForColorBlindness(
          color,
          ColorBlindnessType.achromatopsia,
        );

        // Should be grayscale (R = G = B)
        expect(result.red, result.green);
        expect(result.green, result.blue);
        expect(result.alpha, color.alpha);
      });

      test('should preserve alpha channel for all types', () {
        const color = Color(0x80FF5500); // Semi-transparent orange
        for (final type in ColorBlindnessType.values) {
          final result = AccessibilityService.adaptColorForColorBlindness(color, type);
          expect(result.alpha, color.alpha);
        }
      });

      test('should handle white color', () {
        const white = Color(0xFFFFFFFF);
        for (final type in ColorBlindnessType.values) {
          final result = AccessibilityService.adaptColorForColorBlindness(white, type);
          expect(result.alpha, 255);
        }
      });

      test('should handle black color', () {
        const black = Color(0xFF000000);
        for (final type in ColorBlindnessType.values) {
          final result = AccessibilityService.adaptColorForColorBlindness(black, type);
          // Black should remain relatively dark
          expect(result.red, lessThanOrEqualTo(50));
          expect(result.green, lessThanOrEqualTo(50));
          expect(result.blue, lessThanOrEqualTo(50));
        }
      });
    });
  });
}
