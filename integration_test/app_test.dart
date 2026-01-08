// ============================================================================
// SmartSpend - Tests d'intégration
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartspend/main.dart';
import 'package:smartspend/screens/auth/login_screen.dart';
import 'package:smartspend/screens/auth/register_screen.dart';
import 'package:smartspend/screens/home/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flux d\'authentification', () {
    testWidgets('Affichage de l\'écran de connexion', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Vérifier que l'écran de connexion s'affiche
      expect(find.text('Bon retour !'), findsOneWidget);
      expect(find.text('Connectez-vous pour continuer'), findsOneWidget);
    });

    testWidgets('Validation du formulaire de connexion - email vide', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Appuyer sur le bouton de connexion sans remplir les champs
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier le message d'erreur
      expect(find.text('L\'email est requis'), findsOneWidget);
    });

    testWidgets('Validation du formulaire de connexion - email invalide', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Entrer un email invalide
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier le message d'erreur
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('Navigation vers l\'inscription', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Appuyer sur le lien d'inscription
      await tester.tap(find.text('S\'inscrire'));
      await tester.pumpAndSettle();

      // Vérifier qu'on est sur l'écran d'inscription
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets('Navigation vers mot de passe oublié', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Appuyer sur le lien mot de passe oublié
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      // Vérifier qu'on est sur l'écran de récupération
      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);
    });
  });

  group('Flux de navigation principale', () {
    testWidgets('Navigation entre les onglets', (tester) async {
      await tester.pumpWidget(const SmartSpendApp());
      await tester.pumpAndSettle();

      // Les onglets sont dans la barre de navigation
      // Après connexion, tester la navigation
    });
  });

  group('Flux d\'ajout de dépense', () {
    testWidgets('Validation du montant', (tester) async {
      // Test de validation du montant dans l'écran d'ajout
    });

    testWidgets('Sélection de catégorie', (tester) async {
      // Test de sélection de catégorie
    });

    testWidgets('Sélection de date', (tester) async {
      // Test de sélection de date
    });
  });
}
