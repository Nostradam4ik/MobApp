// ============================================================================
// SmartSpend - Tests des localisations
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    group('supportedLocales', () {
      test('devrait supporter le français', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'fr'),
          true,
        );
      });

      test('devrait supporter l\'anglais', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'en'),
          true,
        );
      });

      test('devrait supporter l\'allemand', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'de'),
          true,
        );
      });

      test('devrait supporter l\'espagnol', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'es'),
          true,
        );
      });

      test('devrait supporter l\'italien', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'it'),
          true,
        );
      });

      test('devrait supporter le portugais', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'pt'),
          true,
        );
      });

      test('devrait supporter l\'ukrainien', () {
        expect(
          AppLocalizations.supportedLocales.any((l) => l.languageCode == 'uk'),
          true,
        );
      });

      test('devrait avoir au moins 10 langues', () {
        expect(AppLocalizations.supportedLocales.length, greaterThanOrEqualTo(10));
      });
    });

    group('getLanguageName', () {
      test('devrait retourner le bon nom pour le français', () {
        expect(AppLocalizations.getLanguageName('fr'), 'Français');
      });

      test('devrait retourner le bon nom pour l\'anglais', () {
        expect(AppLocalizations.getLanguageName('en'), 'English');
      });

      test('devrait retourner le bon nom pour l\'allemand', () {
        expect(AppLocalizations.getLanguageName('de'), 'Deutsch');
      });

      test('devrait retourner le bon nom pour l\'espagnol', () {
        expect(AppLocalizations.getLanguageName('es'), 'Español');
      });

      test('devrait retourner le bon nom pour l\'ukrainien', () {
        expect(AppLocalizations.getLanguageName('uk'), 'Українська');
      });

      test('devrait retourner le code pour une langue inconnue', () {
        expect(AppLocalizations.getLanguageName('xx'), 'xx');
      });
    });

    group('Traductions françaises', () {
      late AppLocalizations l10n;

      setUp(() {
        l10n = AppLocalizations(const Locale('fr', 'FR'));
      });

      test('devrait avoir le nom de l\'app', () {
        expect(l10n.appName, 'SmartSpend');
      });

      test('devrait avoir les boutons d\'action', () {
        expect(l10n.save, 'Enregistrer');
        expect(l10n.cancel, 'Annuler');
        expect(l10n.delete, 'Supprimer');
        expect(l10n.edit, 'Modifier');
        expect(l10n.add, 'Ajouter');
      });

      test('devrait avoir les textes d\'authentification', () {
        expect(l10n.login, 'Se connecter');
        expect(l10n.logout, 'Se déconnecter');
        expect(l10n.register, 'S\'inscrire');
        expect(l10n.welcomeBack, 'Bon retour !');
        expect(l10n.email, 'Email');
        expect(l10n.password, 'Mot de passe');
      });

      test('devrait avoir les textes de navigation', () {
        expect(l10n.home, 'Accueil');
        expect(l10n.stats, 'Statistiques');
        expect(l10n.goals, 'Objectifs');
        expect(l10n.profile, 'Profil');
        expect(l10n.settings, 'Paramètres');
      });

      test('devrait avoir les textes de dépenses', () {
        expect(l10n.expenses, 'Dépenses');
        expect(l10n.newExpense, 'Nouvelle dépense');
        expect(l10n.addExpense, 'Ajouter une dépense');
        expect(l10n.amount, 'Montant');
        expect(l10n.note, 'Note');
        expect(l10n.date, 'Date');
      });

      test('devrait avoir les textes de catégories', () {
        expect(l10n.categories, 'Catégories');
        expect(l10n.category, 'Catégorie');
        expect(l10n.newCategory, 'Nouvelle catégorie');
      });

      test('devrait avoir les textes de budgets', () {
        expect(l10n.budgets, 'Budgets');
        expect(l10n.budget, 'Budget');
        expect(l10n.newBudget, 'Nouveau budget');
        expect(l10n.budgetExceeded, 'Budget dépassé !');
      });

      test('devrait avoir les textes premium', () {
        expect(l10n.premium, 'Premium');
        expect(l10n.goPremium, 'Passez à Premium');
        expect(l10n.freeTrial, 'Essai gratuit 7 jours');
      });

      test('devrait avoir les textes de paramètres', () {
        expect(l10n.language, 'Langue');
        expect(l10n.theme, 'Thème');
        expect(l10n.darkMode, 'Mode sombre');
        expect(l10n.lightMode, 'Mode clair');
        expect(l10n.currency, 'Devise');
        expect(l10n.notifications, 'Notifications');
      });
    });

    group('Traductions anglaises', () {
      late AppLocalizations l10n;

      setUp(() {
        l10n = AppLocalizations(const Locale('en', 'US'));
      });

      test('devrait avoir les boutons d\'action en anglais', () {
        expect(l10n.save, 'Save');
        expect(l10n.cancel, 'Cancel');
        expect(l10n.delete, 'Delete');
        expect(l10n.edit, 'Edit');
        expect(l10n.add, 'Add');
      });

      test('devrait avoir les textes d\'authentification en anglais', () {
        expect(l10n.login, 'Sign in');
        expect(l10n.logout, 'Sign out');
        expect(l10n.register, 'Sign up');
        expect(l10n.welcomeBack, 'Welcome back!');
      });

      test('devrait avoir les textes de navigation en anglais', () {
        expect(l10n.home, 'Home');
        expect(l10n.stats, 'Statistics');
        expect(l10n.goals, 'Goals');
        expect(l10n.profile, 'Profile');
        expect(l10n.settings, 'Settings');
      });
    });

    group('Traductions allemandes', () {
      late AppLocalizations l10n;

      setUp(() {
        l10n = AppLocalizations(const Locale('de', 'DE'));
      });

      test('devrait avoir les boutons d\'action en allemand', () {
        expect(l10n.save, 'Speichern');
        expect(l10n.cancel, 'Abbrechen');
        expect(l10n.delete, 'Löschen');
      });

      test('devrait avoir les textes de navigation en allemand', () {
        expect(l10n.home, 'Startseite');
        expect(l10n.settings, 'Einstellungen');
      });
    });

    group('Traductions espagnoles', () {
      late AppLocalizations l10n;

      setUp(() {
        l10n = AppLocalizations(const Locale('es', 'ES'));
      });

      test('devrait avoir les boutons d\'action en espagnol', () {
        expect(l10n.save, 'Guardar');
        expect(l10n.cancel, 'Cancelar');
        expect(l10n.delete, 'Eliminar');
      });

      test('devrait avoir les textes de navigation en espagnol', () {
        expect(l10n.home, 'Inicio');
        expect(l10n.goals, 'Objetivos');
      });
    });

    group('Traductions ukrainiennes', () {
      late AppLocalizations l10n;

      setUp(() {
        l10n = AppLocalizations(const Locale('uk', 'UA'));
      });

      test('devrait avoir les boutons d\'action en ukrainien', () {
        expect(l10n.save, 'Зберегти');
        expect(l10n.cancel, 'Скасувати');
        expect(l10n.delete, 'Видалити');
      });

      test('devrait avoir les textes d\'authentification en ukrainien', () {
        expect(l10n.login, 'Увійти');
        expect(l10n.logout, 'Вийти');
        expect(l10n.register, 'Зареєструватися');
      });
    });

    group('AppLocalizationsDelegate', () {
      test('devrait supporter les langues configurées', () {
        const delegate = AppLocalizationsDelegate();

        expect(delegate.isSupported(const Locale('fr')), true);
        expect(delegate.isSupported(const Locale('en')), true);
        expect(delegate.isSupported(const Locale('de')), true);
        expect(delegate.isSupported(const Locale('es')), true);
        expect(delegate.isSupported(const Locale('uk')), true);
      });

      test('ne devrait pas supporter les langues non configurées', () {
        const delegate = AppLocalizationsDelegate();

        expect(delegate.isSupported(const Locale('zh')), false);
        expect(delegate.isSupported(const Locale('ja')), false);
        expect(delegate.isSupported(const Locale('ko')), false);
      });

      test('ne devrait pas nécessiter de rechargement', () {
        const delegate = AppLocalizationsDelegate();
        expect(delegate.shouldReload(delegate), false);
      });
    });
  });
}
