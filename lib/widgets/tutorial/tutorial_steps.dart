import 'package:flutter/material.dart';
import '../../services/tutorial_service.dart';
import 'tutorial_overlay.dart';

/// Définition des étapes du tutoriel SmartSpend
class SmartSpendTutorial {
  SmartSpendTutorial._();

  /// Les étapes du tutoriel pour la première utilisation
  static List<TutorialStep> get steps => [
    // Étape 1: Bienvenue
    const TutorialStep(
      id: 'welcome',
      title: 'Bienvenue sur SmartSpend !',
      description:
          'Votre nouvel assistant pour gérer vos finances personnelles. '
          'Suivez ce court tutoriel pour découvrir les fonctionnalités.',
      icon: Icons.waving_hand_rounded,
      targetKey: null, // Pas de cible, message centré
      showArrow: false,
    ),

    // Étape 2: Carte de résumé
    TutorialStep(
      id: 'summary_card',
      title: 'Votre résumé financier',
      description:
          'Ici, vous voyez vos dépenses du mois en cours, '
          'votre budget restant et les statistiques rapides.',
      icon: Icons.account_balance_wallet_rounded,
      targetKey: TutorialService.summaryCardKey,
      tooltipAlignment: Alignment.bottomCenter,
    ),

    // Étape 3: Bouton ajouter
    TutorialStep(
      id: 'add_expense',
      title: 'Ajouter une dépense',
      description:
          'Appuyez sur ce bouton pour enregistrer une nouvelle dépense. '
          'C\'est rapide et facile !',
      icon: Icons.add_circle_rounded,
      targetKey: TutorialService.fabKey,
      tooltipAlignment: Alignment.topCenter,
    ),

    // Étape 4: Ajout rapide
    TutorialStep(
      id: 'quick_add',
      title: 'Ajout rapide par catégorie',
      description:
          'Sélectionnez une catégorie pour ajouter une dépense '
          'encore plus rapidement avec la catégorie pré-remplie.',
      icon: Icons.category_rounded,
      targetKey: TutorialService.quickAddKey,
      tooltipAlignment: Alignment.bottomCenter,
    ),

    // Étape 5: Recherche
    TutorialStep(
      id: 'search',
      title: 'Rechercher vos dépenses',
      description:
          'Retrouvez facilement n\'importe quelle dépense '
          'grâce à la recherche intelligente.',
      icon: Icons.search_rounded,
      targetKey: TutorialService.searchButtonKey,
      tooltipAlignment: Alignment.bottomLeft,
    ),

    // Étape 6: Insights
    TutorialStep(
      id: 'insights',
      title: 'Conseils personnalisés',
      description:
          'Recevez des conseils intelligents basés sur vos habitudes '
          'pour mieux gérer votre argent.',
      icon: Icons.lightbulb_rounded,
      targetKey: TutorialService.insightsButtonKey,
      tooltipAlignment: Alignment.bottomLeft,
    ),

    // Étape 7: Navigation - Stats
    const TutorialStep(
      id: 'stats_nav',
      title: 'Statistiques détaillées',
      description:
          'Analysez vos dépenses avec des graphiques interactifs '
          'et identifiez vos tendances.',
      icon: Icons.pie_chart_rounded,
      targetKey: null, // La navigation est dans le BottomNav
      showArrow: false,
    ),

    // Étape 8: Navigation - Objectifs
    const TutorialStep(
      id: 'goals_nav',
      title: 'Objectifs d\'épargne',
      description:
          'Définissez des objectifs d\'épargne et suivez '
          'votre progression jour après jour.',
      icon: Icons.flag_rounded,
      targetKey: null,
      showArrow: false,
    ),

    // Étape 9: Conclusion
    const TutorialStep(
      id: 'ready',
      title: 'Vous êtes prêt !',
      description:
          'Commencez dès maintenant à suivre vos dépenses. '
          'SmartSpend vous aidera à atteindre vos objectifs financiers.',
      icon: Icons.rocket_launch_rounded,
      targetKey: null,
      showArrow: false,
    ),
  ];

  /// Version courte du tutoriel (pour les utilisateurs pressés)
  static List<TutorialStep> get shortSteps => [
    // Étape 1: Bienvenue
    const TutorialStep(
      id: 'welcome',
      title: 'Bienvenue sur SmartSpend !',
      description:
          'Gérez vos finances simplement et intelligemment.',
      icon: Icons.waving_hand_rounded,
      targetKey: null,
      showArrow: false,
    ),

    // Étape 2: Bouton ajouter
    TutorialStep(
      id: 'add_expense',
      title: 'Ajouter une dépense',
      description:
          'Appuyez ici pour enregistrer vos dépenses.',
      icon: Icons.add_circle_rounded,
      targetKey: TutorialService.fabKey,
      tooltipAlignment: Alignment.topCenter,
    ),

    // Étape 3: Résumé
    TutorialStep(
      id: 'summary_card',
      title: 'Suivez votre budget',
      description:
          'Visualisez vos dépenses et votre progression.',
      icon: Icons.account_balance_wallet_rounded,
      targetKey: TutorialService.summaryCardKey,
      tooltipAlignment: Alignment.bottomCenter,
    ),

    // Étape 4: Conclusion
    const TutorialStep(
      id: 'ready',
      title: 'C\'est parti !',
      description:
          'Commencez à suivre vos dépenses maintenant.',
      icon: Icons.rocket_launch_rounded,
      targetKey: null,
      showArrow: false,
    ),
  ];
}
