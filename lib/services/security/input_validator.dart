import 'dart:convert';

/// Service de validation et sanitization des entrées
/// Protège contre XSS, injection SQL, et autres attaques
class InputValidator {
  static InputValidator? _instance;

  InputValidator._();

  static InputValidator getInstance() {
    _instance ??= InputValidator._();
    return _instance!;
  }

  // ==================== VALIDATION EMAIL ====================

  /// Valide un email
  ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult.invalid('L\'email est requis');
    }

    email = email.trim().toLowerCase();

    // Longueur
    if (email.length > 254) {
      return ValidationResult.invalid('Email trop long');
    }

    // Pattern strict pour email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Format email invalide');
    }

    // Vérifier les domaines suspects
    final suspiciousDomains = ['tempmail', 'throwaway', 'guerrilla', 'mailinator'];
    if (suspiciousDomains.any((d) => email.contains(d))) {
      return ValidationResult.warning(
        'Adresse email temporaire détectée',
        sanitized: email,
      );
    }

    return ValidationResult.valid(email);
  }

  // ==================== VALIDATION MOT DE PASSE ====================

  /// Valide un mot de passe avec critères stricts
  PasswordValidationResult validatePassword(String password) {
    final issues = <String>[];
    int strength = 0;

    // Longueur minimale (12 caractères pour sécurité maximale)
    if (password.length < 12) {
      issues.add('Minimum 12 caractères requis');
    } else if (password.length >= 16) {
      strength += 2;
    } else {
      strength += 1;
    }

    // Longueur maximale (éviter DoS)
    if (password.length > 128) {
      return PasswordValidationResult(
        isValid: false,
        issues: ['Mot de passe trop long (max 128 caractères)'],
        strength: 0,
      );
    }

    // Majuscule
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('Au moins une majuscule requise');
    } else {
      strength += 1;
    }

    // Minuscule
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('Au moins une minuscule requise');
    } else {
      strength += 1;
    }

    // Chiffre
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      issues.add('Au moins un chiffre requis');
    } else {
      strength += 1;
    }

    // Caractère spécial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]').hasMatch(password)) {
      issues.add('Au moins un caractère spécial requis');
    } else {
      strength += 2;
    }

    // Vérifier les patterns faibles
    final weakPatterns = [
      r'123456',
      r'password',
      r'qwerty',
      r'azerty',
      r'abc123',
      r'letmein',
      r'admin',
      r'welcome',
      r'motdepasse',
      r'(.)\1{3,}', // 4+ caractères répétés
    ];

    final lowerPassword = password.toLowerCase();
    for (final pattern in weakPatterns) {
      if (RegExp(pattern).hasMatch(lowerPassword)) {
        issues.add('Évitez les patterns courants');
        strength -= 2;
        break;
      }
    }

    // Séquences
    if (_hasSequentialChars(password)) {
      issues.add('Évitez les séquences (abc, 123)');
      strength -= 1;
    }

    // Espaces
    if (password.contains(' ')) {
      issues.add('Les espaces ne sont pas autorisés');
    }

    strength = strength.clamp(0, 10);

    return PasswordValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      strength: strength,
      strengthLabel: _getStrengthLabel(strength),
    );
  }

  bool _hasSequentialChars(String password) {
    const sequences = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final lower = password.toLowerCase();

    for (int i = 0; i < lower.length - 2; i++) {
      final sub = lower.substring(i, i + 3);
      if (sequences.contains(sub)) return true;
    }
    return false;
  }

  String _getStrengthLabel(int strength) {
    if (strength >= 8) return 'Excellent';
    if (strength >= 6) return 'Fort';
    if (strength >= 4) return 'Moyen';
    if (strength >= 2) return 'Faible';
    return 'Très faible';
  }

  // ==================== VALIDATION CODE PIN ====================

  /// Valide un code PIN
  ValidationResult validatePin(String pin) {
    if (pin.isEmpty) {
      return ValidationResult.invalid('Le code PIN est requis');
    }

    // Uniquement des chiffres
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return ValidationResult.invalid('Le PIN doit contenir uniquement des chiffres');
    }

    // Longueur exacte
    if (pin.length < 4 || pin.length > 8) {
      return ValidationResult.invalid('Le PIN doit contenir entre 4 et 8 chiffres');
    }

    // Patterns faibles
    final weakPins = [
      '0000', '1111', '2222', '3333', '4444',
      '5555', '6666', '7777', '8888', '9999',
      '1234', '4321', '0123', '9876', '1212',
      '2580', // Ligne verticale
    ];

    if (weakPins.contains(pin)) {
      return ValidationResult.invalid('PIN trop simple - Choisissez un PIN plus sécurisé');
    }

    // Séquences
    if (_hasSequentialChars(pin)) {
      return ValidationResult.warning(
        'PIN avec séquence détectée',
        sanitized: pin,
      );
    }

    return ValidationResult.valid(pin);
  }

  // ==================== VALIDATION MONTANT ====================

  /// Valide un montant financier
  ValidationResult validateAmount(String amountStr) {
    if (amountStr.isEmpty) {
      return ValidationResult.invalid('Le montant est requis');
    }

    // Nettoyer le format
    amountStr = amountStr.replaceAll(' ', '').replaceAll(',', '.');

    // Valider le format numérique
    final amount = double.tryParse(amountStr);
    if (amount == null) {
      return ValidationResult.invalid('Montant invalide');
    }

    // Limites
    if (amount < 0) {
      return ValidationResult.invalid('Le montant ne peut pas être négatif');
    }

    if (amount > 999999999) {
      return ValidationResult.invalid('Montant trop élevé');
    }

    // Précision (2 décimales max)
    final parts = amountStr.split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      amountStr = amount.toStringAsFixed(2);
    }

    return ValidationResult.valid(amountStr);
  }

  // ==================== VALIDATION TEXTE ====================

  /// Valide et sanitize un texte libre
  ValidationResult validateText(
    String text, {
    int minLength = 0,
    int maxLength = 1000,
    bool allowHtml = false,
    bool allowNewlines = true,
  }) {
    if (text.isEmpty && minLength > 0) {
      return ValidationResult.invalid('Ce champ est requis');
    }

    if (text.length < minLength) {
      return ValidationResult.invalid('Minimum $minLength caractères requis');
    }

    if (text.length > maxLength) {
      return ValidationResult.invalid('Maximum $maxLength caractères autorisés');
    }

    // Sanitization
    String sanitized = text;

    // Supprimer HTML si non autorisé
    if (!allowHtml) {
      sanitized = _stripHtml(sanitized);
    }

    // Gérer les nouvelles lignes
    if (!allowNewlines) {
      sanitized = sanitized.replaceAll(RegExp(r'[\r\n]+'), ' ');
    }

    // Supprimer caractères de contrôle dangereux
    sanitized = _removeControlChars(sanitized);

    // Normaliser les espaces
    sanitized = sanitized.replaceAll(RegExp(r' {2,}'), ' ').trim();

    // Détecter injection potentielle
    if (_detectInjection(sanitized)) {
      return ValidationResult.warning(
        'Caractères suspects détectés et nettoyés',
        sanitized: sanitized,
      );
    }

    return ValidationResult.valid(sanitized);
  }

  /// Supprime les balises HTML
  String _stripHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  /// Supprime les caractères de contrôle
  String _removeControlChars(String text) {
    return text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Détecte les tentatives d'injection
  bool _detectInjection(String text) {
    final patterns = [
      r'<script',
      r'javascript:',
      r'onerror\s*=',
      r'onclick\s*=',
      r'onload\s*=',
      r'eval\s*\(',
      r'document\.',
      r'window\.',
      r'SELECT\s+.*\s+FROM',
      r'INSERT\s+INTO',
      r'DELETE\s+FROM',
      r'UPDATE\s+.*\s+SET',
      r'DROP\s+TABLE',
      r'--\s*$',
      r';\s*--',
      r"'\\s*OR\\s*'",
      r"'\\s*=\\s*'",
    ];

    final lowerText = text.toLowerCase();
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerText)) {
        return true;
      }
    }
    return false;
  }

  // ==================== VALIDATION NOM ====================

  /// Valide un nom/prénom
  ValidationResult validateName(String name) {
    if (name.isEmpty) {
      return ValidationResult.invalid('Le nom est requis');
    }

    name = name.trim();

    if (name.length < 2) {
      return ValidationResult.invalid('Nom trop court');
    }

    if (name.length > 50) {
      return ValidationResult.invalid('Nom trop long');
    }

    // Autoriser lettres, espaces, tirets, apostrophes
    if (!RegExp(r"^[\p{L}\s\-']+$", unicode: true).hasMatch(name)) {
      return ValidationResult.invalid('Caractères non autorisés dans le nom');
    }

    // Normaliser
    name = name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return ValidationResult.valid(name);
  }

  // ==================== VALIDATION TÉLÉPHONE ====================

  /// Valide un numéro de téléphone français
  ValidationResult validatePhone(String phone) {
    if (phone.isEmpty) {
      return ValidationResult.invalid('Le numéro est requis');
    }

    // Nettoyer
    phone = phone.replaceAll(RegExp(r'[\s.\-()]'), '');

    // Format international
    if (phone.startsWith('+33')) {
      phone = '0${phone.substring(3)}';
    } else if (phone.startsWith('33')) {
      phone = '0${phone.substring(2)}';
    }

    // Valider format français
    if (!RegExp(r'^0[1-9][0-9]{8}$').hasMatch(phone)) {
      return ValidationResult.invalid('Numéro de téléphone invalide');
    }

    // Formater pour affichage
    final formatted = phone.replaceAllMapped(
      RegExp(r'(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})'),
      (m) => '${m[1]} ${m[2]} ${m[3]} ${m[4]} ${m[5]}',
    );

    return ValidationResult.valid(formatted);
  }

  // ==================== VALIDATION URL ====================

  /// Valide une URL
  ValidationResult validateUrl(String url) {
    if (url.isEmpty) {
      return ValidationResult.invalid('L\'URL est requise');
    }

    url = url.trim();

    // Forcer HTTPS
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // Ajouter protocole si manquant
    if (!url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Valider format
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.invalid('URL invalide');
      }

      // Vérifier protocole sécurisé
      if (uri.scheme != 'https') {
        return ValidationResult.warning(
          'URL non sécurisée convertie en HTTPS',
          sanitized: url,
        );
      }

      return ValidationResult.valid(url);
    } catch (_) {
      return ValidationResult.invalid('URL invalide');
    }
  }

  // ==================== VALIDATION JSON ====================

  /// Valide et parse du JSON
  JsonValidationResult validateJson(String jsonStr) {
    if (jsonStr.isEmpty) {
      return JsonValidationResult.invalid('JSON vide');
    }

    try {
      final data = jsonDecode(jsonStr);
      return JsonValidationResult.valid(data);
    } on FormatException catch (e) {
      return JsonValidationResult.invalid('JSON invalide: ${e.message}');
    }
  }

  // ==================== VALIDATION DATE ====================

  /// Valide une date
  ValidationResult validateDate(
    String dateStr, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (dateStr.isEmpty) {
      return ValidationResult.invalid('La date est requise');
    }

    DateTime? date;

    // Essayer différents formats
    final formats = [
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'), // YYYY-MM-DD
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'), // DD/MM/YYYY
      RegExp(r'^(\d{2})-(\d{2})-(\d{4})$'), // DD-MM-YYYY
    ];

    for (int i = 0; i < formats.length; i++) {
      final match = formats[i].firstMatch(dateStr);
      if (match != null) {
        try {
          if (i == 0) {
            date = DateTime(
              int.parse(match[1]!),
              int.parse(match[2]!),
              int.parse(match[3]!),
            );
          } else {
            date = DateTime(
              int.parse(match[3]!),
              int.parse(match[2]!),
              int.parse(match[1]!),
            );
          }
          break;
        } catch (_) {
          continue;
        }
      }
    }

    if (date == null) {
      return ValidationResult.invalid('Format de date invalide');
    }

    // Vérifier limites
    if (minDate != null && date.isBefore(minDate)) {
      return ValidationResult.invalid('Date trop ancienne');
    }

    if (maxDate != null && date.isAfter(maxDate)) {
      return ValidationResult.invalid('Date trop récente');
    }

    // Retourner format ISO
    return ValidationResult.valid(date.toIso8601String().split('T')[0]);
  }
}

/// Résultat de validation
class ValidationResult {
  final bool isValid;
  final bool hasWarning;
  final String? message;
  final String? sanitized;

  ValidationResult._({
    required this.isValid,
    this.hasWarning = false,
    this.message,
    this.sanitized,
  });

  factory ValidationResult.valid(String sanitized) => ValidationResult._(
        isValid: true,
        sanitized: sanitized,
      );

  factory ValidationResult.invalid(String message) => ValidationResult._(
        isValid: false,
        message: message,
      );

  factory ValidationResult.warning(String message, {required String sanitized}) =>
      ValidationResult._(
        isValid: true,
        hasWarning: true,
        message: message,
        sanitized: sanitized,
      );
}

/// Résultat de validation de mot de passe
class PasswordValidationResult {
  final bool isValid;
  final List<String> issues;
  final int strength;
  final String? strengthLabel;

  PasswordValidationResult({
    required this.isValid,
    required this.issues,
    required this.strength,
    this.strengthLabel,
  });

  double get strengthPercentage => (strength / 10 * 100).clamp(0, 100);
}

/// Résultat de validation JSON
class JsonValidationResult {
  final bool isValid;
  final String? message;
  final dynamic data;

  JsonValidationResult._({
    required this.isValid,
    this.message,
    this.data,
  });

  factory JsonValidationResult.valid(dynamic data) => JsonValidationResult._(
        isValid: true,
        data: data,
      );

  factory JsonValidationResult.invalid(String message) => JsonValidationResult._(
        isValid: false,
        message: message,
      );
}
