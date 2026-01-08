// ============================================================================
// SmartSpend - Système de localisation
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';

/// Délégué de localisation pour SmartSpend
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'de', 'es', 'it', 'pt', 'nl', 'pl', 'uk', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Classe de localisation contenant toutes les traductions
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  /// Liste des langues supportées (English first as default)
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (default)
    Locale('fr', 'FR'), // Français
    Locale('de', 'DE'), // Deutsch
    Locale('es', 'ES'), // Español
    Locale('it', 'IT'), // Italiano
    Locale('pt', 'PT'), // Português
    Locale('nl', 'NL'), // Nederlands
    Locale('pl', 'PL'), // Polski
    Locale('uk', 'UA'), // Українська
    Locale('ru', 'RU'), // Русский
  ];

  /// Obtenir le nom de la langue
  static String getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'nl':
        return 'Nederlands';
      case 'pl':
        return 'Polski';
      case 'uk':
        return 'Українська';
      case 'ru':
        return 'Русский';
      default:
        return code;
    }
  }

  // ============ TRANSLATIONS ============

  Map<String, Map<String, String>> get _translations => {
    // ============ GENERAL ============
    'appName': {
      'fr': 'SmartSpend',
      'en': 'SmartSpend',
      'de': 'SmartSpend',
      'es': 'SmartSpend',
      'it': 'SmartSpend',
      'pt': 'SmartSpend',
      'nl': 'SmartSpend',
      'pl': 'SmartSpend',
      'uk': 'SmartSpend',
      'ru': 'SmartSpend',
    },
    'loading': {
      'fr': 'Chargement...',
      'en': 'Loading...',
      'de': 'Laden...',
      'es': 'Cargando...',
      'it': 'Caricamento...',
      'pt': 'Carregando...',
      'nl': 'Laden...',
      'pl': 'Ładowanie...',
      'uk': 'Завантаження...',
      'ru': 'Загрузка...',
    },
    'save': {
      'fr': 'Enregistrer',
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Guardar',
      'it': 'Salva',
      'pt': 'Salvar',
      'nl': 'Opslaan',
      'pl': 'Zapisz',
      'uk': 'Зберегти',
      'ru': 'Сохранить',
    },
    'cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
      'de': 'Abbrechen',
      'es': 'Cancelar',
      'it': 'Annulla',
      'pt': 'Cancelar',
      'nl': 'Annuleren',
      'pl': 'Anuluj',
      'uk': 'Скасувати',
      'ru': 'Отмена',
    },
    'delete': {
      'fr': 'Supprimer',
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Eliminar',
      'it': 'Elimina',
      'pt': 'Excluir',
      'nl': 'Verwijderen',
      'pl': 'Usuń',
      'uk': 'Видалити',
      'ru': 'Удалить',
    },
    'edit': {
      'fr': 'Modifier',
      'en': 'Edit',
      'de': 'Bearbeiten',
      'es': 'Editar',
      'it': 'Modifica',
      'pt': 'Editar',
      'nl': 'Bewerken',
      'pl': 'Edytuj',
      'uk': 'Редагувати',
      'ru': 'Редактировать',
    },
    'add': {
      'fr': 'Ajouter',
      'en': 'Add',
      'de': 'Hinzufügen',
      'es': 'Añadir',
      'it': 'Aggiungi',
      'pt': 'Adicionar',
      'nl': 'Toevoegen',
      'pl': 'Dodaj',
      'uk': 'Додати',
      'ru': 'Добавить',
    },
    'yes': {
      'fr': 'Oui',
      'en': 'Yes',
      'de': 'Ja',
      'es': 'Sí',
      'it': 'Sì',
      'pt': 'Sim',
      'nl': 'Ja',
      'pl': 'Tak',
      'uk': 'Так',
      'ru': 'Да',
    },
    'no': {
      'fr': 'Non',
      'en': 'No',
      'de': 'Nein',
      'es': 'No',
      'it': 'No',
      'pt': 'Não',
      'nl': 'Nee',
      'pl': 'Nie',
      'uk': 'Ні',
      'ru': 'Нет',
    },
    'ok': {
      'fr': 'OK',
      'en': 'OK',
      'de': 'OK',
      'es': 'OK',
      'it': 'OK',
      'pt': 'OK',
      'nl': 'OK',
      'pl': 'OK',
      'uk': 'OK',
      'ru': 'OK',
    },
    'error': {
      'fr': 'Erreur',
      'en': 'Error',
      'de': 'Fehler',
      'es': 'Error',
      'it': 'Errore',
      'pt': 'Erro',
      'nl': 'Fout',
      'pl': 'Błąd',
      'uk': 'Помилка',
      'ru': 'Ошибка',
    },
    'success': {
      'fr': 'Succès',
      'en': 'Success',
      'de': 'Erfolg',
      'es': 'Éxito',
      'it': 'Successo',
      'pt': 'Sucesso',
      'nl': 'Succes',
      'pl': 'Sukces',
      'uk': 'Успіх',
      'ru': 'Успех',
    },
    'warning': {
      'fr': 'Attention',
      'en': 'Warning',
      'de': 'Warnung',
      'es': 'Advertencia',
      'it': 'Attenzione',
      'pt': 'Aviso',
      'nl': 'Waarschuwing',
      'pl': 'Ostrzeżenie',
      'uk': 'Увага',
      'ru': 'Внимание',
    },
    'seeAll': {
      'fr': 'Voir tout',
      'en': 'See all',
      'de': 'Alle anzeigen',
      'es': 'Ver todo',
      'it': 'Vedi tutto',
      'pt': 'Ver tudo',
      'nl': 'Alles bekijken',
      'pl': 'Zobacz wszystko',
      'uk': 'Переглянути все',
      'ru': 'Смотреть все',
    },

    // ============ AUTH ============
    'login': {
      'fr': 'Se connecter',
      'en': 'Sign in',
      'de': 'Anmelden',
      'es': 'Iniciar sesión',
      'it': 'Accedi',
      'pt': 'Entrar',
      'nl': 'Inloggen',
      'pl': 'Zaloguj się',
      'uk': 'Увійти',
      'ru': 'Войти',
    },
    'logout': {
      'fr': 'Se déconnecter',
      'en': 'Sign out',
      'de': 'Abmelden',
      'es': 'Cerrar sesión',
      'it': 'Esci',
      'pt': 'Sair',
      'nl': 'Uitloggen',
      'pl': 'Wyloguj się',
      'uk': 'Вийти',
      'ru': 'Выйти',
    },
    'register': {
      'fr': 'S\'inscrire',
      'en': 'Sign up',
      'de': 'Registrieren',
      'es': 'Registrarse',
      'it': 'Registrati',
      'pt': 'Cadastrar',
      'nl': 'Registreren',
      'pl': 'Zarejestruj się',
      'uk': 'Зареєструватися',
      'ru': 'Зарегистрироваться',
    },
    'welcomeBack': {
      'fr': 'Bon retour !',
      'en': 'Welcome back!',
      'de': 'Willkommen zurück!',
      'es': '¡Bienvenido de nuevo!',
      'it': 'Bentornato!',
      'pt': 'Bem-vindo de volta!',
      'nl': 'Welkom terug!',
      'pl': 'Witaj ponownie!',
      'uk': 'З поверненням!',
      'ru': 'С возвращением!',
    },
    'signInToContinue': {
      'fr': 'Connectez-vous pour continuer',
      'en': 'Sign in to continue',
      'de': 'Melden Sie sich an, um fortzufahren',
      'es': 'Inicia sesión para continuar',
      'it': 'Accedi per continuare',
      'pt': 'Entre para continuar',
      'nl': 'Log in om door te gaan',
      'pl': 'Zaloguj się, aby kontynuować',
      'uk': 'Увійдіть, щоб продовжити',
      'ru': 'Войдите, чтобы продолжить',
    },
    'createAccount': {
      'fr': 'Créer un compte',
      'en': 'Create account',
      'de': 'Konto erstellen',
      'es': 'Crear cuenta',
      'it': 'Crea account',
      'pt': 'Criar conta',
      'nl': 'Account aanmaken',
      'pl': 'Utwórz konto',
      'uk': 'Створити обліковий запис',
      'ru': 'Создать аккаунт',
    },
    'email': {
      'fr': 'Email',
      'en': 'Email',
      'de': 'E-Mail',
      'es': 'Correo electrónico',
      'it': 'Email',
      'pt': 'E-mail',
      'nl': 'E-mail',
      'pl': 'E-mail',
      'uk': 'Електронна пошта',
      'ru': 'Эл. почта',
    },
    'password': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'de': 'Passwort',
      'es': 'Contraseña',
      'it': 'Password',
      'pt': 'Senha',
      'nl': 'Wachtwoord',
      'pl': 'Hasło',
      'uk': 'Пароль',
      'ru': 'Пароль',
    },
    'confirmPassword': {
      'fr': 'Confirmer le mot de passe',
      'en': 'Confirm password',
      'de': 'Passwort bestätigen',
      'es': 'Confirmar contraseña',
      'it': 'Conferma password',
      'pt': 'Confirmar senha',
      'nl': 'Wachtwoord bevestigen',
      'pl': 'Potwierdź hasło',
      'uk': 'Підтвердити пароль',
      'ru': 'Подтвердить пароль',
    },
    'forgotPassword': {
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot password?',
      'de': 'Passwort vergessen?',
      'es': '¿Olvidaste tu contraseña?',
      'it': 'Password dimenticata?',
      'pt': 'Esqueceu a senha?',
      'nl': 'Wachtwoord vergeten?',
      'pl': 'Zapomniałeś hasła?',
      'uk': 'Забули пароль?',
      'ru': 'Забыли пароль?',
    },
    'resetPassword': {
      'fr': 'Réinitialiser le mot de passe',
      'en': 'Reset password',
      'de': 'Passwort zurücksetzen',
      'es': 'Restablecer contraseña',
      'it': 'Reimposta password',
      'pt': 'Redefinir senha',
      'nl': 'Wachtwoord resetten',
      'pl': 'Zresetuj hasło',
      'uk': 'Скинути пароль',
      'ru': 'Сбросить пароль',
    },
    'noAccount': {
      'fr': 'Pas encore de compte ?',
      'en': 'Don\'t have an account?',
      'de': 'Noch kein Konto?',
      'es': '¿No tienes cuenta?',
      'it': 'Non hai un account?',
      'pt': 'Não tem conta?',
      'nl': 'Nog geen account?',
      'pl': 'Nie masz konta?',
      'uk': 'Немає облікового запису?',
      'ru': 'Нет аккаунта?',
    },
    'alreadyHaveAccount': {
      'fr': 'Déjà un compte ?',
      'en': 'Already have an account?',
      'de': 'Schon ein Konto?',
      'es': '¿Ya tienes cuenta?',
      'it': 'Hai già un account?',
      'pt': 'Já tem conta?',
      'nl': 'Al een account?',
      'pl': 'Masz już konto?',
      'uk': 'Вже є обліковий запис?',
      'ru': 'Уже есть аккаунт?',
    },
    'emailRequired': {
      'fr': 'L\'email est requis',
      'en': 'Email is required',
      'de': 'E-Mail ist erforderlich',
      'es': 'El correo electrónico es obligatorio',
      'it': 'L\'email è obbligatoria',
      'pt': 'O e-mail é obrigatório',
      'nl': 'E-mail is verplicht',
      'pl': 'E-mail jest wymagany',
      'uk': 'Електронна пошта обов\'язкова',
      'ru': 'Эл. почта обязательна',
    },
    'invalidEmail': {
      'fr': 'Email invalide',
      'en': 'Invalid email',
      'de': 'Ungültige E-Mail',
      'es': 'Correo electrónico inválido',
      'it': 'Email non valida',
      'pt': 'E-mail inválido',
      'nl': 'Ongeldig e-mail',
      'pl': 'Nieprawidłowy e-mail',
      'uk': 'Недійсна електронна пошта',
      'ru': 'Неверный адрес эл. почты',
    },
    'passwordRequired': {
      'fr': 'Le mot de passe est requis',
      'en': 'Password is required',
      'de': 'Passwort ist erforderlich',
      'es': 'La contraseña es obligatoria',
      'it': 'La password è obbligatoria',
      'pt': 'A senha é obrigatória',
      'nl': 'Wachtwoord is verplicht',
      'pl': 'Hasło jest wymagane',
      'uk': 'Пароль обов\'язковий',
      'ru': 'Пароль обязателен',
    },

    // ============ NAVIGATION ============
    'home': {
      'fr': 'Accueil',
      'en': 'Home',
      'de': 'Startseite',
      'es': 'Inicio',
      'it': 'Home',
      'pt': 'Início',
      'nl': 'Home',
      'pl': 'Strona główna',
      'uk': 'Головна',
      'ru': 'Главная',
    },
    'stats': {
      'fr': 'Statistiques',
      'en': 'Statistics',
      'de': 'Statistiken',
      'es': 'Estadísticas',
      'it': 'Statistiche',
      'pt': 'Estatísticas',
      'nl': 'Statistieken',
      'pl': 'Statystyki',
      'uk': 'Статистика',
      'ru': 'Статистика',
    },
    'goals': {
      'fr': 'Objectifs',
      'en': 'Goals',
      'de': 'Ziele',
      'es': 'Objetivos',
      'it': 'Obiettivi',
      'pt': 'Metas',
      'nl': 'Doelen',
      'pl': 'Cele',
      'uk': 'Цілі',
      'ru': 'Цели',
    },
    'profile': {
      'fr': 'Profil',
      'en': 'Profile',
      'de': 'Profil',
      'es': 'Perfil',
      'it': 'Profilo',
      'pt': 'Perfil',
      'nl': 'Profiel',
      'pl': 'Profil',
      'uk': 'Профіль',
      'ru': 'Профиль',
    },
    'settings': {
      'fr': 'Paramètres',
      'en': 'Settings',
      'de': 'Einstellungen',
      'es': 'Configuración',
      'it': 'Impostazioni',
      'pt': 'Configurações',
      'nl': 'Instellingen',
      'pl': 'Ustawienia',
      'uk': 'Налаштування',
      'ru': 'Настройки',
    },

    // ============ EXPENSES ============
    'expenses': {
      'fr': 'Dépenses',
      'en': 'Expenses',
      'de': 'Ausgaben',
      'es': 'Gastos',
      'it': 'Spese',
      'pt': 'Despesas',
      'nl': 'Uitgaven',
      'pl': 'Wydatki',
      'uk': 'Витрати',
      'ru': 'Расходы',
    },
    'newExpense': {
      'fr': 'Nouvelle dépense',
      'en': 'New expense',
      'de': 'Neue Ausgabe',
      'es': 'Nuevo gasto',
      'it': 'Nuova spesa',
      'pt': 'Nova despesa',
      'nl': 'Nieuwe uitgave',
      'pl': 'Nowy wydatek',
      'uk': 'Нова витрата',
      'ru': 'Новый расход',
    },
    'addExpense': {
      'fr': 'Ajouter une dépense',
      'en': 'Add expense',
      'de': 'Ausgabe hinzufügen',
      'es': 'Añadir gasto',
      'it': 'Aggiungi spesa',
      'pt': 'Adicionar despesa',
      'nl': 'Uitgave toevoegen',
      'pl': 'Dodaj wydatek',
      'uk': 'Додати витрату',
      'ru': 'Добавить расход',
    },
    'expenseAdded': {
      'fr': 'Dépense ajoutée !',
      'en': 'Expense added!',
      'de': 'Ausgabe hinzugefügt!',
      'es': '¡Gasto añadido!',
      'it': 'Spesa aggiunta!',
      'pt': 'Despesa adicionada!',
      'nl': 'Uitgave toegevoegd!',
      'pl': 'Wydatek dodany!',
      'uk': 'Витрату додано!',
      'ru': 'Расход добавлен!',
    },
    'amount': {
      'fr': 'Montant',
      'en': 'Amount',
      'de': 'Betrag',
      'es': 'Monto',
      'it': 'Importo',
      'pt': 'Valor',
      'nl': 'Bedrag',
      'pl': 'Kwota',
      'uk': 'Сума',
      'ru': 'Сумма',
    },
    'note': {
      'fr': 'Note',
      'en': 'Note',
      'de': 'Notiz',
      'es': 'Nota',
      'it': 'Nota',
      'pt': 'Nota',
      'nl': 'Notitie',
      'pl': 'Notatka',
      'uk': 'Примітка',
      'ru': 'Заметка',
    },
    'noteOptional': {
      'fr': 'Note (optionnel)',
      'en': 'Note (optional)',
      'de': 'Notiz (optional)',
      'es': 'Nota (opcional)',
      'it': 'Nota (opzionale)',
      'pt': 'Nota (opcional)',
      'nl': 'Notitie (optioneel)',
      'pl': 'Notatka (opcjonalnie)',
      'uk': 'Примітка (необов\'язково)',
      'ru': 'Заметка (необязательно)',
    },
    'date': {
      'fr': 'Date',
      'en': 'Date',
      'de': 'Datum',
      'es': 'Fecha',
      'it': 'Data',
      'pt': 'Data',
      'nl': 'Datum',
      'pl': 'Data',
      'uk': 'Дата',
      'ru': 'Дата',
    },
    'today': {
      'fr': 'Aujourd\'hui',
      'en': 'Today',
      'de': 'Heute',
      'es': 'Hoy',
      'it': 'Oggi',
      'pt': 'Hoje',
      'nl': 'Vandaag',
      'pl': 'Dzisiaj',
      'uk': 'Сьогодні',
      'ru': 'Сегодня',
    },
    'yesterday': {
      'fr': 'Hier',
      'en': 'Yesterday',
      'de': 'Gestern',
      'es': 'Ayer',
      'it': 'Ieri',
      'pt': 'Ontem',
      'nl': 'Gisteren',
      'pl': 'Wczoraj',
      'uk': 'Вчора',
      'ru': 'Вчера',
    },
    'thisWeek': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'de': 'Diese Woche',
      'es': 'Esta semana',
      'it': 'Questa settimana',
      'pt': 'Esta semana',
      'nl': 'Deze week',
      'pl': 'Ten tydzień',
      'uk': 'Цього тижня',
      'ru': 'На этой неделе',
    },
    'thisMonth': {
      'fr': 'Ce mois',
      'en': 'This month',
      'de': 'Diesen Monat',
      'es': 'Este mes',
      'it': 'Questo mese',
      'pt': 'Este mês',
      'nl': 'Deze maand',
      'pl': 'Ten miesiąc',
      'uk': 'Цього місяця',
      'ru': 'В этом месяце',
    },
    'expensesThisMonth': {
      'fr': 'Dépenses ce mois',
      'en': 'Expenses this month',
      'de': 'Ausgaben diesen Monat',
      'es': 'Gastos este mes',
      'it': 'Spese questo mese',
      'pt': 'Despesas este mês',
      'nl': 'Uitgaven deze maand',
      'pl': 'Wydatki w tym miesiącu',
      'uk': 'Витрати за місяць',
      'ru': 'Расходы за месяц',
    },
    'latestExpenses': {
      'fr': 'Dernières dépenses',
      'en': 'Latest expenses',
      'de': 'Letzte Ausgaben',
      'es': 'Últimos gastos',
      'it': 'Ultime spese',
      'pt': 'Últimas despesas',
      'nl': 'Laatste uitgaven',
      'pl': 'Ostatnie wydatki',
      'uk': 'Останні витрати',
      'ru': 'Последние расходы',
    },
    'noExpenses': {
      'fr': 'Aucune dépense ce mois',
      'en': 'No expenses this month',
      'de': 'Keine Ausgaben diesen Monat',
      'es': 'Sin gastos este mes',
      'it': 'Nessuna spesa questo mese',
      'pt': 'Sem despesas este mês',
      'nl': 'Geen uitgaven deze maand',
      'pl': 'Brak wydatków w tym miesiącu',
      'uk': 'Немає витрат за цей місяць',
      'ru': 'Нет расходов за этот месяц',
    },
    'quickAdd': {
      'fr': 'Ajout rapide',
      'en': 'Quick add',
      'de': 'Schnell hinzufügen',
      'es': 'Añadir rápido',
      'it': 'Aggiungi veloce',
      'pt': 'Adicionar rápido',
      'nl': 'Snel toevoegen',
      'pl': 'Szybkie dodawanie',
      'uk': 'Швидке додавання',
      'ru': 'Быстрое добавление',
    },
    'enterValidAmount': {
      'fr': 'Veuillez entrer un montant valide',
      'en': 'Please enter a valid amount',
      'de': 'Bitte geben Sie einen gültigen Betrag ein',
      'es': 'Por favor ingrese un monto válido',
      'it': 'Inserisci un importo valido',
      'pt': 'Por favor, insira um valor válido',
      'nl': 'Voer een geldig bedrag in',
      'pl': 'Wprowadź prawidłową kwotę',
      'uk': 'Будь ласка, введіть дійсну суму',
      'ru': 'Пожалуйста, введите корректную сумму',
    },

    // ============ CATEGORIES ============
    'categories': {
      'fr': 'Catégories',
      'en': 'Categories',
      'de': 'Kategorien',
      'es': 'Categorías',
      'it': 'Categorie',
      'pt': 'Categorias',
      'nl': 'Categorieën',
      'pl': 'Kategorie',
      'uk': 'Категорії',
      'ru': 'Категории',
    },
    'category': {
      'fr': 'Catégorie',
      'en': 'Category',
      'de': 'Kategorie',
      'es': 'Categoría',
      'it': 'Categoria',
      'pt': 'Categoria',
      'nl': 'Categorie',
      'pl': 'Kategoria',
      'uk': 'Категорія',
      'ru': 'Категория',
    },
    'newCategory': {
      'fr': 'Nouvelle catégorie',
      'en': 'New category',
      'de': 'Neue Kategorie',
      'es': 'Nueva categoría',
      'it': 'Nuova categoria',
      'pt': 'Nova categoria',
      'nl': 'Nieuwe categorie',
      'pl': 'Nowa kategoria',
      'uk': 'Нова категорія',
      'ru': 'Новая категория',
    },

    // ============ BUDGETS ============
    'budgets': {
      'fr': 'Budgets',
      'en': 'Budgets',
      'de': 'Budgets',
      'es': 'Presupuestos',
      'it': 'Budget',
      'pt': 'Orçamentos',
      'nl': 'Budgetten',
      'pl': 'Budżety',
      'uk': 'Бюджети',
      'ru': 'Бюджеты',
    },
    'budget': {
      'fr': 'Budget',
      'en': 'Budget',
      'de': 'Budget',
      'es': 'Presupuesto',
      'it': 'Budget',
      'pt': 'Orçamento',
      'nl': 'Budget',
      'pl': 'Budżet',
      'uk': 'Бюджет',
      'ru': 'Бюджет',
    },
    'newBudget': {
      'fr': 'Nouveau budget',
      'en': 'New budget',
      'de': 'Neues Budget',
      'es': 'Nuevo presupuesto',
      'it': 'Nuovo budget',
      'pt': 'Novo orçamento',
      'nl': 'Nieuw budget',
      'pl': 'Nowy budżet',
      'uk': 'Новий бюджет',
      'ru': 'Новый бюджет',
    },
    'budgetExceeded': {
      'fr': 'Budget dépassé !',
      'en': 'Budget exceeded!',
      'de': 'Budget überschritten!',
      'es': '¡Presupuesto excedido!',
      'it': 'Budget superato!',
      'pt': 'Orçamento excedido!',
      'nl': 'Budget overschreden!',
      'pl': 'Przekroczono budżet!',
      'uk': 'Бюджет перевищено!',
      'ru': 'Бюджет превышен!',
    },

    // ============ ACCOUNTS ============
    'accounts': {
      'fr': 'Comptes',
      'en': 'Accounts',
      'de': 'Konten',
      'es': 'Cuentas',
      'it': 'Conti',
      'pt': 'Contas',
      'nl': 'Rekeningen',
      'pl': 'Konta',
      'uk': 'Рахунки',
      'ru': 'Счета',
    },
    'account': {
      'fr': 'Compte',
      'en': 'Account',
      'de': 'Konto',
      'es': 'Cuenta',
      'it': 'Conto',
      'pt': 'Conta',
      'nl': 'Rekening',
      'pl': 'Konto',
      'uk': 'Рахунок',
      'ru': 'Счёт',
    },
    'myAccounts': {
      'fr': 'Mes comptes',
      'en': 'My accounts',
      'de': 'Meine Konten',
      'es': 'Mis cuentas',
      'it': 'I miei conti',
      'pt': 'Minhas contas',
      'nl': 'Mijn rekeningen',
      'pl': 'Moje konta',
      'uk': 'Мої рахунки',
      'ru': 'Мои счета',
    },

    // ============ GOALS ============
    'newGoal': {
      'fr': 'Nouvel objectif',
      'en': 'New goal',
      'de': 'Neues Ziel',
      'es': 'Nuevo objetivo',
      'it': 'Nuovo obiettivo',
      'pt': 'Nova meta',
      'nl': 'Nieuw doel',
      'pl': 'Nowy cel',
      'uk': 'Нова ціль',
      'ru': 'Новая цель',
    },
    'goalAchieved': {
      'fr': 'Objectif atteint !',
      'en': 'Goal achieved!',
      'de': 'Ziel erreicht!',
      'es': '¡Objetivo alcanzado!',
      'it': 'Obiettivo raggiunto!',
      'pt': 'Meta atingida!',
      'nl': 'Doel bereikt!',
      'pl': 'Cel osiągnięty!',
      'uk': 'Ціль досягнуто!',
      'ru': 'Цель достигнута!',
    },
    'targetAmount': {
      'fr': 'Montant cible',
      'en': 'Target amount',
      'de': 'Zielbetrag',
      'es': 'Monto objetivo',
      'it': 'Importo target',
      'pt': 'Valor alvo',
      'nl': 'Doelbedrag',
      'pl': 'Kwota docelowa',
      'uk': 'Цільова сума',
      'ru': 'Целевая сумма',
    },
    'currentAmount': {
      'fr': 'Montant actuel',
      'en': 'Current amount',
      'de': 'Aktueller Betrag',
      'es': 'Monto actual',
      'it': 'Importo attuale',
      'pt': 'Valor atual',
      'nl': 'Huidig bedrag',
      'pl': 'Aktualna kwota',
      'uk': 'Поточна сума',
      'ru': 'Текущая сумма',
    },
    'deadline': {
      'fr': 'Date limite',
      'en': 'Deadline',
      'de': 'Frist',
      'es': 'Fecha límite',
      'it': 'Scadenza',
      'pt': 'Prazo',
      'nl': 'Deadline',
      'pl': 'Termin',
      'uk': 'Кінцевий термін',
      'ru': 'Срок',
    },

    // ============ PREMIUM ============
    'premium': {
      'fr': 'Premium',
      'en': 'Premium',
      'de': 'Premium',
      'es': 'Premium',
      'it': 'Premium',
      'pt': 'Premium',
      'nl': 'Premium',
      'pl': 'Premium',
      'uk': 'Преміум',
      'ru': 'Премиум',
    },
    'goPremium': {
      'fr': 'Passez à Premium',
      'en': 'Go Premium',
      'de': 'Auf Premium upgraden',
      'es': 'Hazte Premium',
      'it': 'Passa a Premium',
      'pt': 'Assine Premium',
      'nl': 'Upgrade naar Premium',
      'pl': 'Przejdź na Premium',
      'uk': 'Отримати Преміум',
      'ru': 'Перейти на Премиум',
    },
    'freeTrial': {
      'fr': 'Essai gratuit 7 jours',
      'en': '7-day free trial',
      'de': '7 Tage kostenlos testen',
      'es': 'Prueba gratis 7 días',
      'it': 'Prova gratuita 7 giorni',
      'pt': 'Teste grátis 7 dias',
      'nl': '7 dagen gratis proberen',
      'pl': '7 dni za darmo',
      'uk': '7 днів безкоштовно',
      'ru': '7 дней бесплатно',
    },
    'unlockEverything': {
      'fr': 'Débloquez tout gratuitement',
      'en': 'Unlock everything for free',
      'de': 'Alles kostenlos freischalten',
      'es': 'Desbloquea todo gratis',
      'it': 'Sblocca tutto gratis',
      'pt': 'Desbloqueie tudo grátis',
      'nl': 'Ontgrendel alles gratis',
      'pl': 'Odblokuj wszystko za darmo',
      'uk': 'Розблокуйте все безкоштовно',
      'ru': 'Разблокируйте всё бесплатно',
    },
    'monthly': {
      'fr': 'Mensuel',
      'en': 'Monthly',
      'de': 'Monatlich',
      'es': 'Mensual',
      'it': 'Mensile',
      'pt': 'Mensal',
      'nl': 'Maandelijks',
      'pl': 'Miesięcznie',
      'uk': 'Щомісяця',
      'ru': 'Ежемесячно',
    },
    'yearly': {
      'fr': 'Annuel',
      'en': 'Yearly',
      'de': 'Jährlich',
      'es': 'Anual',
      'it': 'Annuale',
      'pt': 'Anual',
      'nl': 'Jaarlijks',
      'pl': 'Rocznie',
      'uk': 'Щорічно',
      'ru': 'Ежегодно',
    },

    // ============ SETTINGS ============
    'language': {
      'fr': 'Langue',
      'en': 'Language',
      'de': 'Sprache',
      'es': 'Idioma',
      'it': 'Lingua',
      'pt': 'Idioma',
      'nl': 'Taal',
      'pl': 'Język',
      'uk': 'Мова',
      'ru': 'Язык',
    },
    'theme': {
      'fr': 'Thème',
      'en': 'Theme',
      'de': 'Thema',
      'es': 'Tema',
      'it': 'Tema',
      'pt': 'Tema',
      'nl': 'Thema',
      'pl': 'Motyw',
      'uk': 'Тема',
      'ru': 'Тема',
    },
    'darkMode': {
      'fr': 'Mode sombre',
      'en': 'Dark mode',
      'de': 'Dunkelmodus',
      'es': 'Modo oscuro',
      'it': 'Modalità scura',
      'pt': 'Modo escuro',
      'nl': 'Donkere modus',
      'pl': 'Tryb ciemny',
      'uk': 'Темний режим',
      'ru': 'Тёмный режим',
    },
    'lightMode': {
      'fr': 'Mode clair',
      'en': 'Light mode',
      'de': 'Hellmodus',
      'es': 'Modo claro',
      'it': 'Modalità chiara',
      'pt': 'Modo claro',
      'nl': 'Lichte modus',
      'pl': 'Tryb jasny',
      'uk': 'Світлий режим',
      'ru': 'Светлый режим',
    },
    'systemMode': {
      'fr': 'Système',
      'en': 'System',
      'de': 'System',
      'es': 'Sistema',
      'it': 'Sistema',
      'pt': 'Sistema',
      'nl': 'Systeem',
      'pl': 'Systemowy',
      'uk': 'Системний',
      'ru': 'Системный',
    },
    'currency': {
      'fr': 'Devise',
      'en': 'Currency',
      'de': 'Währung',
      'es': 'Moneda',
      'it': 'Valuta',
      'pt': 'Moeda',
      'nl': 'Valuta',
      'pl': 'Waluta',
      'uk': 'Валюта',
      'ru': 'Валюта',
    },
    'notifications': {
      'fr': 'Notifications',
      'en': 'Notifications',
      'de': 'Benachrichtigungen',
      'es': 'Notificaciones',
      'it': 'Notifiche',
      'pt': 'Notificações',
      'nl': 'Meldingen',
      'pl': 'Powiadomienia',
      'uk': 'Сповіщення',
      'ru': 'Уведомления',
    },
    'security': {
      'fr': 'Sécurité',
      'en': 'Security',
      'de': 'Sicherheit',
      'es': 'Seguridad',
      'it': 'Sicurezza',
      'pt': 'Segurança',
      'nl': 'Beveiliging',
      'pl': 'Bezpieczeństwo',
      'uk': 'Безпека',
      'ru': 'Безопасность',
    },
    'privacyPolicy': {
      'fr': 'Politique de confidentialité',
      'en': 'Privacy policy',
      'de': 'Datenschutzrichtlinie',
      'es': 'Política de privacidad',
      'it': 'Informativa sulla privacy',
      'pt': 'Política de privacidade',
      'nl': 'Privacybeleid',
      'pl': 'Polityka prywatności',
      'uk': 'Політика конфіденційності',
      'ru': 'Политика конфиденциальности',
    },
    'termsOfService': {
      'fr': 'Conditions d\'utilisation',
      'en': 'Terms of service',
      'de': 'Nutzungsbedingungen',
      'es': 'Términos de servicio',
      'it': 'Termini di servizio',
      'pt': 'Termos de serviço',
      'nl': 'Servicevoorwaarden',
      'pl': 'Warunki korzystania',
      'uk': 'Умови використання',
      'ru': 'Условия использования',
    },
    'developedBy': {
      'fr': 'Développé par',
      'en': 'Developed by',
      'de': 'Entwickelt von',
      'es': 'Desarrollado por',
      'it': 'Sviluppato da',
      'pt': 'Desenvolvido por',
      'nl': 'Ontwikkeld door',
      'pl': 'Opracowane przez',
      'uk': 'Розроблено',
      'ru': 'Разработано',
    },
    'deleteAccount': {
      'fr': 'Supprimer mon compte',
      'en': 'Delete my account',
      'de': 'Mein Konto löschen',
      'es': 'Eliminar mi cuenta',
      'it': 'Elimina il mio account',
      'pt': 'Excluir minha conta',
      'nl': 'Mijn account verwijderen',
      'pl': 'Usuń moje konto',
      'uk': 'Видалити мій обліковий запис',
      'ru': 'Удалить мой аккаунт',
    },
    'dangerZone': {
      'fr': 'Zone dangereuse',
      'en': 'Danger zone',
      'de': 'Gefahrenzone',
      'es': 'Zona peligrosa',
      'it': 'Zona pericolosa',
      'pt': 'Zona de perigo',
      'nl': 'Gevarenzone',
      'pl': 'Strefa niebezpieczeństwa',
      'uk': 'Небезпечна зона',
      'ru': 'Опасная зона',
    },

    // ============ INSIGHTS & AI ============
    'insights': {
      'fr': 'Conseils',
      'en': 'Insights',
      'de': 'Einblicke',
      'es': 'Consejos',
      'it': 'Approfondimenti',
      'pt': 'Insights',
      'nl': 'Inzichten',
      'pl': 'Wskazówki',
      'uk': 'Поради',
      'ru': 'Рекомендации',
    },
    'aiAssistant': {
      'fr': 'Assistant IA',
      'en': 'AI Assistant',
      'de': 'KI-Assistent',
      'es': 'Asistente IA',
      'it': 'Assistente IA',
      'pt': 'Assistente IA',
      'nl': 'AI-assistent',
      'pl': 'Asystent AI',
      'uk': 'ШІ-асистент',
      'ru': 'ИИ-ассистент',
    },

    // ============ ACHIEVEMENTS ============
    'achievements': {
      'fr': 'Récompenses',
      'en': 'Achievements',
      'de': 'Erfolge',
      'es': 'Logros',
      'it': 'Traguardi',
      'pt': 'Conquistas',
      'nl': 'Prestaties',
      'pl': 'Osiągnięcia',
      'uk': 'Досягнення',
      'ru': 'Достижения',
    },
    'streak': {
      'fr': 'Série',
      'en': 'Streak',
      'de': 'Serie',
      'es': 'Racha',
      'it': 'Serie',
      'pt': 'Sequência',
      'nl': 'Reeks',
      'pl': 'Seria',
      'uk': 'Серія',
      'ru': 'Серия',
    },
    'daysInARow': {
      'fr': 'jours de suite !',
      'en': 'days in a row!',
      'de': 'Tage in Folge!',
      'es': '¡días seguidos!',
      'it': 'giorni di fila!',
      'pt': 'dias seguidos!',
      'nl': 'dagen op rij!',
      'pl': 'dni z rzędu!',
      'uk': 'днів поспіль!',
      'ru': 'дней подряд!',
    },
    'keepTracking': {
      'fr': 'Continuez à suivre vos dépenses',
      'en': 'Keep tracking your expenses',
      'de': 'Verfolgen Sie weiterhin Ihre Ausgaben',
      'es': 'Sigue registrando tus gastos',
      'it': 'Continua a tracciare le spese',
      'pt': 'Continue rastreando suas despesas',
      'nl': 'Blijf je uitgaven bijhouden',
      'pl': 'Kontynuuj śledzenie wydatków',
      'uk': 'Продовжуйте відстежувати витрати',
      'ru': 'Продолжайте отслеживать расходы',
    },

    // ============ EXPORT ============
    'export': {
      'fr': 'Exporter',
      'en': 'Export',
      'de': 'Exportieren',
      'es': 'Exportar',
      'it': 'Esporta',
      'pt': 'Exportar',
      'nl': 'Exporteren',
      'pl': 'Eksportuj',
      'uk': 'Експортувати',
      'ru': 'Экспортировать',
    },
    'import': {
      'fr': 'Importer',
      'en': 'Import',
      'de': 'Importieren',
      'es': 'Importar',
      'it': 'Importa',
      'pt': 'Importar',
      'nl': 'Importeren',
      'pl': 'Importuj',
      'uk': 'Імпортувати',
      'ru': 'Импортировать',
    },
    'exportData': {
      'fr': 'Exporter les données',
      'en': 'Export data',
      'de': 'Daten exportieren',
      'es': 'Exportar datos',
      'it': 'Esporta dati',
      'pt': 'Exportar dados',
      'nl': 'Gegevens exporteren',
      'pl': 'Eksportuj dane',
      'uk': 'Експортувати дані',
      'ru': 'Экспортировать данные',
    },

    // ============ SEARCH ============
    'search': {
      'fr': 'Rechercher',
      'en': 'Search',
      'de': 'Suchen',
      'es': 'Buscar',
      'it': 'Cerca',
      'pt': 'Pesquisar',
      'nl': 'Zoeken',
      'pl': 'Szukaj',
      'uk': 'Пошук',
      'ru': 'Поиск',
    },
    'searchExpenses': {
      'fr': 'Rechercher des dépenses',
      'en': 'Search expenses',
      'de': 'Ausgaben suchen',
      'es': 'Buscar gastos',
      'it': 'Cerca spese',
      'pt': 'Pesquisar despesas',
      'nl': 'Uitgaven zoeken',
      'pl': 'Szukaj wydatków',
      'uk': 'Шукати витрати',
      'ru': 'Искать расходы',
    },

    // ============ SYNC ============
    'sync': {
      'fr': 'Synchronisation',
      'en': 'Sync',
      'de': 'Synchronisierung',
      'es': 'Sincronización',
      'it': 'Sincronizzazione',
      'pt': 'Sincronização',
      'nl': 'Synchronisatie',
      'pl': 'Synchronizacja',
      'uk': 'Синхронізація',
      'ru': 'Синхронизация',
    },
    'syncNow': {
      'fr': 'Synchroniser maintenant',
      'en': 'Sync now',
      'de': 'Jetzt synchronisieren',
      'es': 'Sincronizar ahora',
      'it': 'Sincronizza ora',
      'pt': 'Sincronizar agora',
      'nl': 'Nu synchroniseren',
      'pl': 'Synchronizuj teraz',
      'uk': 'Синхронізувати зараз',
      'ru': 'Синхронизировать сейчас',
    },
    'lastSync': {
      'fr': 'Dernière synchronisation',
      'en': 'Last sync',
      'de': 'Letzte Synchronisierung',
      'es': 'Última sincronización',
      'it': 'Ultima sincronizzazione',
      'pt': 'Última sincronização',
      'nl': 'Laatste synchronisatie',
      'pl': 'Ostatnia synchronizacja',
      'uk': 'Остання синхронізація',
      'ru': 'Последняя синхронизация',
    },

    // ============ GREETING ============
    'hello': {
      'fr': 'Bonjour',
      'en': 'Hello',
      'de': 'Hallo',
      'es': 'Hola',
      'it': 'Ciao',
      'pt': 'Olá',
      'nl': 'Hallo',
      'pl': 'Cześć',
      'uk': 'Привіт',
      'ru': 'Привет',
    },
    'goodMorning': {
      'fr': 'Bonjour',
      'en': 'Good morning',
      'de': 'Guten Morgen',
      'es': 'Buenos días',
      'it': 'Buongiorno',
      'pt': 'Bom dia',
      'nl': 'Goedemorgen',
      'pl': 'Dzień dobry',
      'uk': 'Доброго ранку',
      'ru': 'Доброе утро',
    },
    'goodAfternoon': {
      'fr': 'Bon après-midi',
      'en': 'Good afternoon',
      'de': 'Guten Tag',
      'es': 'Buenas tardes',
      'it': 'Buon pomeriggio',
      'pt': 'Boa tarde',
      'nl': 'Goedemiddag',
      'pl': 'Dzień dobry',
      'uk': 'Доброго дня',
      'ru': 'Добрый день',
    },
    'goodEvening': {
      'fr': 'Bonsoir',
      'en': 'Good evening',
      'de': 'Guten Abend',
      'es': 'Buenas noches',
      'it': 'Buonasera',
      'pt': 'Boa noite',
      'nl': 'Goedenavond',
      'pl': 'Dobry wieczór',
      'uk': 'Доброго вечора',
      'ru': 'Добрый вечер',
    },
    // Onboarding
    'onboardingTrackTitle': {
      'fr': 'Suivez vos dépenses',
      'en': 'Track your expenses',
      'de': 'Verfolgen Sie Ihre Ausgaben',
      'es': 'Sigue tus gastos',
      'it': 'Tieni traccia delle tue spese',
      'pt': 'Acompanhe suas despesas',
      'nl': 'Volg je uitgaven',
      'pl': 'Śledź swoje wydatki',
      'uk': 'Відстежуйте свої витрати',
      'ru': 'Отслеживайте свои расходы',
    },
    'onboardingTrackDesc': {
      'fr': 'Ajoutez vos dépenses en moins de 10 secondes et gardez le contrôle de votre argent.',
      'en': 'Add your expenses in less than 10 seconds and keep control of your money.',
      'de': 'Fügen Sie Ihre Ausgaben in weniger als 10 Sekunden hinzu und behalten Sie die Kontrolle über Ihr Geld.',
      'es': 'Añade tus gastos en menos de 10 segundos y mantén el control de tu dinero.',
      'it': 'Aggiungi le tue spese in meno di 10 secondi e mantieni il controllo del tuo denaro.',
      'pt': 'Adicione suas despesas em menos de 10 segundos e mantenha o controle do seu dinheiro.',
      'nl': 'Voeg je uitgaven toe in minder dan 10 seconden en behoud controle over je geld.',
      'pl': 'Dodaj swoje wydatki w mniej niż 10 sekund i zachowaj kontrolę nad swoimi pieniędzmi.',
      'uk': 'Додавайте свої витрати менш ніж за 10 секунд і контролюйте свої гроші.',
      'ru': 'Добавляйте свои расходы менее чем за 10 секунд и контролируйте свои деньги.',
    },
    'onboardingVisualizeTitle': {
      'fr': 'Visualisez vos finances',
      'en': 'Visualize your finances',
      'de': 'Visualisieren Sie Ihre Finanzen',
      'es': 'Visualiza tus finanzas',
      'it': 'Visualizza le tue finanze',
      'pt': 'Visualize suas finanças',
      'nl': 'Visualiseer je financiën',
      'pl': 'Wizualizuj swoje finanse',
      'uk': 'Візуалізуйте свої фінанси',
      'ru': 'Визуализируйте свои финансы',
    },
    'onboardingVisualizeDesc': {
      'fr': 'Des graphiques clairs pour comprendre où va votre argent chaque mois.',
      'en': 'Clear charts to understand where your money goes each month.',
      'de': 'Klare Diagramme, um zu verstehen, wohin Ihr Geld jeden Monat geht.',
      'es': 'Gráficos claros para entender a dónde va tu dinero cada mes.',
      'it': 'Grafici chiari per capire dove vanno i tuoi soldi ogni mese.',
      'pt': 'Gráficos claros para entender para onde vai seu dinheiro a cada mês.',
      'nl': 'Duidelijke grafieken om te begrijpen waar je geld elke maand naartoe gaat.',
      'pl': 'Przejrzyste wykresy, aby zrozumieć, gdzie idą Twoje pieniądze każdego miesiąca.',
      'uk': 'Чіткі графіки, щоб зрозуміти, куди йдуть ваші гроші щомісяця.',
      'ru': 'Понятные графики, чтобы понять, куда уходят ваши деньги каждый месяц.',
    },
    'onboardingTipsTitle': {
      'fr': 'Conseils personnalisés',
      'en': 'Personalized tips',
      'de': 'Personalisierte Tipps',
      'es': 'Consejos personalizados',
      'it': 'Consigli personalizzati',
      'pt': 'Dicas personalizadas',
      'nl': 'Gepersonaliseerde tips',
      'pl': 'Spersonalizowane porady',
      'uk': 'Персоналізовані поради',
      'ru': 'Персонализированные советы',
    },
    'onboardingTipsDesc': {
      'fr': 'Recevez des conseils intelligents pour mieux gérer votre budget.',
      'en': 'Receive smart tips to better manage your budget.',
      'de': 'Erhalten Sie intelligente Tipps, um Ihr Budget besser zu verwalten.',
      'es': 'Recibe consejos inteligentes para gestionar mejor tu presupuesto.',
      'it': 'Ricevi consigli intelligenti per gestire meglio il tuo budget.',
      'pt': 'Receba dicas inteligentes para gerenciar melhor seu orçamento.',
      'nl': 'Ontvang slimme tips om je budget beter te beheren.',
      'pl': 'Otrzymuj inteligentne porady, aby lepiej zarządzać swoim budżetem.',
      'uk': 'Отримуйте розумні поради для кращого управління бюджетом.',
      'ru': 'Получайте умные советы для лучшего управления бюджетом.',
    },
    'onboardingGoalsTitle': {
      'fr': 'Atteignez vos objectifs',
      'en': 'Achieve your goals',
      'de': 'Erreichen Sie Ihre Ziele',
      'es': 'Alcanza tus objetivos',
      'it': 'Raggiungi i tuoi obiettivi',
      'pt': 'Alcance seus objetivos',
      'nl': 'Bereik je doelen',
      'pl': 'Osiągnij swoje cele',
      'uk': 'Досягайте своїх цілей',
      'ru': 'Достигайте своих целей',
    },
    'onboardingGoalsDesc': {
      'fr': 'Fixez des objectifs d\'épargne et suivez votre progression avec des badges.',
      'en': 'Set savings goals and track your progress with badges.',
      'de': 'Setzen Sie Sparziele und verfolgen Sie Ihren Fortschritt mit Abzeichen.',
      'es': 'Establece objetivos de ahorro y sigue tu progreso con insignias.',
      'it': 'Imposta obiettivi di risparmio e monitora i tuoi progressi con badge.',
      'pt': 'Defina metas de economia e acompanhe seu progresso com distintivos.',
      'nl': 'Stel spaardoelen en volg je voortgang met badges.',
      'pl': 'Ustal cele oszczędnościowe i śledź swoje postępy za pomocą odznak.',
      'uk': 'Встановлюйте цілі заощаджень і відстежуйте свій прогрес за допомогою значків.',
      'ru': 'Устанавливайте цели сбережений и отслеживайте прогресс с помощью значков.',
    },
    'skip': {
      'fr': 'Passer',
      'en': 'Skip',
      'de': 'Überspringen',
      'es': 'Omitir',
      'it': 'Salta',
      'pt': 'Pular',
      'nl': 'Overslaan',
      'pl': 'Pomiń',
      'uk': 'Пропустити',
      'ru': 'Пропустить',
    },
    'next': {
      'fr': 'Suivant',
      'en': 'Next',
      'de': 'Weiter',
      'es': 'Siguiente',
      'it': 'Avanti',
      'pt': 'Próximo',
      'nl': 'Volgende',
      'pl': 'Dalej',
      'uk': 'Далі',
      'ru': 'Далее',
    },
    'getStarted': {
      'fr': 'Commencer',
      'en': 'Get Started',
      'de': 'Loslegen',
      'es': 'Comenzar',
      'it': 'Inizia',
      'pt': 'Começar',
      'nl': 'Beginnen',
      'pl': 'Rozpocznij',
      'uk': 'Почати',
      'ru': 'Начать',
    },
  };

  /// Obtenir une traduction
  String get(String key) {
    final translation = _translations[key];
    if (translation == null) return key;
    return translation[locale.languageCode] ?? translation['en'] ?? key;
  }

  /// Raccourcis pour les traductions courantes
  String get appName => get('appName');
  String get loading => get('loading');
  String get save => get('save');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get edit => get('edit');
  String get add => get('add');
  String get yes => get('yes');
  String get no => get('no');
  String get ok => get('ok');
  String get error => get('error');
  String get success => get('success');
  String get warning => get('warning');
  String get seeAll => get('seeAll');

  // Auth
  String get login => get('login');
  String get logout => get('logout');
  String get register => get('register');
  String get welcomeBack => get('welcomeBack');
  String get signInToContinue => get('signInToContinue');
  String get createAccount => get('createAccount');
  String get email => get('email');
  String get password => get('password');
  String get confirmPassword => get('confirmPassword');
  String get forgotPassword => get('forgotPassword');
  String get resetPassword => get('resetPassword');
  String get noAccount => get('noAccount');
  String get alreadyHaveAccount => get('alreadyHaveAccount');
  String get emailRequired => get('emailRequired');
  String get invalidEmail => get('invalidEmail');
  String get passwordRequired => get('passwordRequired');

  // Navigation
  String get home => get('home');
  String get stats => get('stats');
  String get goals => get('goals');
  String get profile => get('profile');
  String get settings => get('settings');

  // Expenses
  String get expenses => get('expenses');
  String get newExpense => get('newExpense');
  String get addExpense => get('addExpense');
  String get expenseAdded => get('expenseAdded');
  String get amount => get('amount');
  String get note => get('note');
  String get noteOptional => get('noteOptional');
  String get date => get('date');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get thisWeek => get('thisWeek');
  String get thisMonth => get('thisMonth');
  String get expensesThisMonth => get('expensesThisMonth');
  String get latestExpenses => get('latestExpenses');
  String get noExpenses => get('noExpenses');
  String get quickAdd => get('quickAdd');
  String get enterValidAmount => get('enterValidAmount');

  // Categories
  String get categories => get('categories');
  String get category => get('category');
  String get newCategory => get('newCategory');

  // Budgets
  String get budgets => get('budgets');
  String get budget => get('budget');
  String get newBudget => get('newBudget');
  String get budgetExceeded => get('budgetExceeded');

  // Accounts
  String get accounts => get('accounts');
  String get account => get('account');
  String get myAccounts => get('myAccounts');

  // Goals
  String get newGoal => get('newGoal');
  String get goalAchieved => get('goalAchieved');
  String get targetAmount => get('targetAmount');
  String get currentAmount => get('currentAmount');
  String get deadline => get('deadline');

  // Premium
  String get premium => get('premium');
  String get goPremium => get('goPremium');
  String get freeTrial => get('freeTrial');
  String get unlockEverything => get('unlockEverything');
  String get monthly => get('monthly');
  String get yearly => get('yearly');

  // Settings
  String get language => get('language');
  String get theme => get('theme');
  String get darkMode => get('darkMode');
  String get lightMode => get('lightMode');
  String get systemMode => get('systemMode');
  String get currency => get('currency');
  String get notifications => get('notifications');
  String get security => get('security');
  String get privacyPolicy => get('privacyPolicy');
  String get termsOfService => get('termsOfService');
  String get developedBy => get('developedBy');
  String get deleteAccount => get('deleteAccount');
  String get dangerZone => get('dangerZone');

  // Insights & AI
  String get insights => get('insights');
  String get aiAssistant => get('aiAssistant');

  // Achievements
  String get achievements => get('achievements');
  String get streak => get('streak');
  String get daysInARow => get('daysInARow');
  String get keepTracking => get('keepTracking');

  // Export
  String get export => get('export');
  String get import => get('import');
  String get exportData => get('exportData');

  // Search
  String get search => get('search');
  String get searchExpenses => get('searchExpenses');

  // Sync
  String get sync => get('sync');
  String get syncNow => get('syncNow');
  String get lastSync => get('lastSync');

  // Greeting
  String get hello => get('hello');
  String get goodMorning => get('goodMorning');
  String get goodAfternoon => get('goodAfternoon');
  String get goodEvening => get('goodEvening');

  // Onboarding
  String get onboardingTrackTitle => get('onboardingTrackTitle');
  String get onboardingTrackDesc => get('onboardingTrackDesc');
  String get onboardingVisualizeTitle => get('onboardingVisualizeTitle');
  String get onboardingVisualizeDesc => get('onboardingVisualizeDesc');
  String get onboardingTipsTitle => get('onboardingTipsTitle');
  String get onboardingTipsDesc => get('onboardingTipsDesc');
  String get onboardingGoalsTitle => get('onboardingGoalsTitle');
  String get onboardingGoalsDesc => get('onboardingGoalsDesc');
  String get skip => get('skip');
  String get next => get('next');
  String get getStarted => get('getStarted');
}
