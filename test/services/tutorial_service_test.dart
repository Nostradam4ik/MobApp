import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/services/local_storage_service.dart';
import 'package:smartspend/services/tutorial_service.dart';

void main() {
  group('TutorialService', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values for each test
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
    });

    group('shouldShowTutorial', () {
      test('should return true when tutorial not completed and not skipped', () {
        expect(TutorialService.shouldShowTutorial(), true);
      });

      test('should return false when tutorial is completed', () async {
        await TutorialService.completeTutorial();

        expect(TutorialService.shouldShowTutorial(), false);
      });

      test('should return false when tutorial is skipped', () async {
        await TutorialService.skipTutorial();

        expect(TutorialService.shouldShowTutorial(), false);
      });
    });

    group('isTutorialCompleted', () {
      test('should return false initially', () {
        expect(TutorialService.isTutorialCompleted(), false);
      });

      test('should return true after completing', () async {
        await TutorialService.completeTutorial();

        expect(TutorialService.isTutorialCompleted(), true);
      });
    });

    group('isTutorialSkipped', () {
      test('should return false initially', () {
        expect(TutorialService.isTutorialSkipped(), false);
      });

      test('should return true after skipping', () async {
        await TutorialService.skipTutorial();

        expect(TutorialService.isTutorialSkipped(), true);
      });
    });

    group('resetTutorial', () {
      test('should reset completed status', () async {
        await TutorialService.completeTutorial();
        expect(TutorialService.isTutorialCompleted(), true);

        await TutorialService.resetTutorial();

        expect(TutorialService.isTutorialCompleted(), false);
        expect(TutorialService.shouldShowTutorial(), true);
      });

      test('should reset skipped status', () async {
        await TutorialService.skipTutorial();
        expect(TutorialService.isTutorialSkipped(), true);

        await TutorialService.resetTutorial();

        expect(TutorialService.isTutorialSkipped(), false);
        expect(TutorialService.shouldShowTutorial(), true);
      });

      test('should reset current step', () async {
        await TutorialService.saveCurrentStep(5);
        expect(TutorialService.getCurrentStep(), 5);

        await TutorialService.resetTutorial();

        expect(TutorialService.getCurrentStep(), 0);
      });
    });

    group('step management', () {
      test('should start at step 0', () {
        expect(TutorialService.getCurrentStep(), 0);
      });

      test('should save and retrieve current step', () async {
        await TutorialService.saveCurrentStep(3);

        expect(TutorialService.getCurrentStep(), 3);
      });

      test('should update step correctly', () async {
        await TutorialService.saveCurrentStep(1);
        expect(TutorialService.getCurrentStep(), 1);

        await TutorialService.saveCurrentStep(2);
        expect(TutorialService.getCurrentStep(), 2);

        await TutorialService.saveCurrentStep(5);
        expect(TutorialService.getCurrentStep(), 5);
      });
    });

    group('GlobalKeys', () {
      test('should have unique debug labels', () {
        final keys = [
          TutorialService.fabKey,
          TutorialService.summaryCardKey,
          TutorialService.quickAddKey,
          TutorialService.searchButtonKey,
          TutorialService.insightsButtonKey,
          TutorialService.statsNavKey,
          TutorialService.goalsNavKey,
          TutorialService.profileNavKey,
        ];

        // Collect all labels
        final labels = <String>{};
        for (final key in keys) {
          final label = key.toString();
          expect(labels.contains(label), false,
              reason: 'Duplicate key label: $label');
          labels.add(label);
        }

        // Verify count
        expect(labels.length, keys.length);
      });

      test('should have descriptive labels', () {
        expect(TutorialService.fabKey.toString(), contains('fab'));
        expect(TutorialService.summaryCardKey.toString(), contains('summary'));
        expect(TutorialService.statsNavKey.toString(), contains('stats'));
        expect(TutorialService.profileNavKey.toString(), contains('profile'));
      });
    });
  });
}
