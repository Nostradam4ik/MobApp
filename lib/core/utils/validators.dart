import '../constants/app_constants.dart';

/// Utilitaires de validation
class Validators {
  Validators._();

  /// Valide un email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < SecurityConstants.minPasswordLength) {
      return 'Le mot de passe doit faire au moins ${SecurityConstants.minPasswordLength} caractères';
    }
    return null;
  }

  /// Valide une confirmation de mot de passe
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Valide un nom
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    if (value.length < 2) {
      return 'Le nom est trop court';
    }
    return null;
  }

  /// Valide un montant
  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le montant est requis';
    }
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null) {
      return 'Montant invalide';
    }
    if (amount <= 0) {
      return 'Le montant doit être positif';
    }
    if (amount > AppConstants.maxExpenseAmount) {
      return 'Le montant est trop élevé';
    }
    return null;
  }

  /// Valide une note
  static String? note(String? value) {
    if (value != null && value.length > AppConstants.maxNoteLength) {
      return 'La note est trop longue';
    }
    return null;
  }

  /// Valide un champ requis
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }
}
