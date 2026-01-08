import 'package:flutter/material.dart';
import 'local_storage_service.dart';

/// Service pour gérer le tutoriel interactif
class TutorialService {
  TutorialService._();

  static const String _keyTutorialCompleted = 'tutorial_completed';
  static const String _keyTutorialStep = 'tutorial_current_step';
  static const String _keyTutorialSkipped = 'tutorial_skipped';

  /// GlobalKeys pour les éléments à mettre en surbrillance
  static final GlobalKey fabKey = GlobalKey(debugLabel: 'fab_button');
  static final GlobalKey summaryCardKey = GlobalKey(debugLabel: 'summary_card');
  static final GlobalKey quickAddKey = GlobalKey(debugLabel: 'quick_add');
  static final GlobalKey searchButtonKey = GlobalKey(debugLabel: 'search_button');
  static final GlobalKey insightsButtonKey = GlobalKey(debugLabel: 'insights_button');
  static final GlobalKey statsNavKey = GlobalKey(debugLabel: 'stats_nav');
  static final GlobalKey goalsNavKey = GlobalKey(debugLabel: 'goals_nav');
  static final GlobalKey profileNavKey = GlobalKey(debugLabel: 'profile_nav');

  /// Vérifie si le tutoriel a été complété
  static bool isTutorialCompleted() {
    return LocalStorageService.getBool(_keyTutorialCompleted) ?? false;
  }

  /// Vérifie si le tutoriel a été passé (skipped)
  static bool isTutorialSkipped() {
    return LocalStorageService.getBool(_keyTutorialSkipped) ?? false;
  }

  /// Vérifie si le tutoriel doit être affiché
  static bool shouldShowTutorial() {
    return !isTutorialCompleted() && !isTutorialSkipped();
  }

  /// Marque le tutoriel comme complété
  static Future<void> completeTutorial() async {
    await LocalStorageService.setBool(_keyTutorialCompleted, true);
  }

  /// Marque le tutoriel comme passé
  static Future<void> skipTutorial() async {
    await LocalStorageService.setBool(_keyTutorialSkipped, true);
  }

  /// Réinitialise le tutoriel (pour les tests ou les paramètres)
  static Future<void> resetTutorial() async {
    await LocalStorageService.remove(_keyTutorialCompleted);
    await LocalStorageService.remove(_keyTutorialSkipped);
    await LocalStorageService.remove(_keyTutorialStep);
  }

  /// Sauvegarde l'étape courante
  static Future<void> saveCurrentStep(int step) async {
    await LocalStorageService.setInt(_keyTutorialStep, step);
  }

  /// Récupère l'étape courante
  static int getCurrentStep() {
    return LocalStorageService.getInt(_keyTutorialStep) ?? 0;
  }
}
