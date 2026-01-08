import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service de chiffrement pour les données sensibles
/// Utilise AES-256-GCM pour le chiffrement symétrique
class EncryptionService {
  static EncryptionService? _instance;
  static encrypt.Key? _key;
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16;  // 128 bits

  EncryptionService._();

  /// Initialise le service avec une clé existante ou en génère une nouvelle
  static Future<EncryptionService> getInstance({String? existingKey}) async {
    if (_instance == null) {
      _instance = EncryptionService._();
      if (existingKey != null && existingKey.isNotEmpty) {
        _key = encrypt.Key.fromBase64(existingKey);
      } else {
        _key = _instance!._generateKey();
      }
    }
    return _instance!;
  }

  /// Génère une nouvelle clé de chiffrement
  encrypt.Key _generateKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keyLength, (_) => random.nextInt(256));
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  /// Obtient la clé actuelle encodée en base64
  String? getKeyBase64() {
    return _key?.base64;
  }

  /// Définit une nouvelle clé
  void setKey(String base64Key) {
    _key = encrypt.Key.fromBase64(base64Key);
  }

  /// Génère un IV (vecteur d'initialisation) aléatoire
  encrypt.IV _generateIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(_ivLength, (_) => random.nextInt(256));
    return encrypt.IV(Uint8List.fromList(ivBytes));
  }

  // ==================== CHIFFREMENT/DÉCHIFFREMENT ====================

  /// Chiffre une chaîne de caractères
  /// Retourne: IV:CipherText en base64
  String encryptString(String plainText) {
    if (_key == null) {
      throw EncryptionException('Encryption key not initialized');
    }
    if (plainText.isEmpty) return '';

    try {
      final iv = _generateIV();
      final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Format: IV:CipherText (les deux en base64)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Déchiffre une chaîne chiffrée
  String decryptString(String encryptedText) {
    if (_key == null) {
      throw EncryptionException('Encryption key not initialized');
    }
    if (encryptedText.isEmpty) return '';

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw EncryptionException('Invalid encrypted format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);

      return decrypted;
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Chiffre des données binaires
  Uint8List encryptBytes(Uint8List data) {
    if (_key == null) {
      throw EncryptionException('Encryption key not initialized');
    }
    if (data.isEmpty) return Uint8List(0);

    try {
      final iv = _generateIV();
      final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encryptBytes(data, iv: iv);

      // Concaténer IV + données chiffrées
      final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
      result.setRange(0, iv.bytes.length, iv.bytes);
      result.setRange(iv.bytes.length, result.length, encrypted.bytes);

      return result;
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Déchiffre des données binaires
  Uint8List decryptBytes(Uint8List encryptedData) {
    if (_key == null) {
      throw EncryptionException('Encryption key not initialized');
    }
    if (encryptedData.isEmpty) return Uint8List(0);

    try {
      // Extraire IV et données chiffrées
      final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, _ivLength)));
      final cipherData = Uint8List.fromList(encryptedData.sublist(_ivLength));

      final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
      final encrypted = encrypt.Encrypted(cipherData);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Chiffre un objet JSON
  String encryptJson(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    return encryptString(jsonString);
  }

  /// Déchiffre un objet JSON
  Map<String, dynamic> decryptJson(String encryptedJson) {
    final jsonString = decryptString(encryptedJson);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // ==================== HACHAGE ====================

  /// Hache une chaîne avec SHA-256
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hache un mot de passe avec sel
  String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final saltedPassword = '$salt:$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Vérifie un mot de passe haché
  bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final expectedHash = hashPassword(password, salt: salt);
    return hashedPassword == expectedHash;
  }

  /// Génère un sel aléatoire
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hache un code PIN
  String hashPin(String pin) {
    return hashPassword(pin);
  }

  /// Vérifie un code PIN haché
  bool verifyPin(String pin, String hashedPin) {
    return verifyPassword(pin, hashedPin);
  }

  // ==================== VALIDATION ====================

  /// Valide la force d'un mot de passe
  PasswordStrength validatePasswordStrength(String password) {
    int score = 0;
    final issues = <String>[];

    // Longueur minimale (12 caractères)
    if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 8) {
      score += 1;
      issues.add('Le mot de passe devrait contenir au moins 12 caractères');
    } else {
      issues.add('Le mot de passe doit contenir au moins 8 caractères');
    }

    // Majuscules
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      issues.add('Ajoutez des majuscules');
    }

    // Minuscules
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      issues.add('Ajoutez des minuscules');
    }

    // Chiffres
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      issues.add('Ajoutez des chiffres');
    }

    // Caractères spéciaux
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 2;
    } else {
      issues.add('Ajoutez des caractères spéciaux (!@#\$%^&*)');
    }

    // Pas de séquences communes
    if (_hasCommonPatterns(password)) {
      score -= 1;
      issues.add('Évitez les séquences communes (123, abc, etc.)');
    }

    // Déterminer le niveau
    PasswordLevel level;
    if (score >= 6) {
      level = PasswordLevel.strong;
    } else if (score >= 4) {
      level = PasswordLevel.medium;
    } else if (score >= 2) {
      level = PasswordLevel.weak;
    } else {
      level = PasswordLevel.veryWeak;
    }

    return PasswordStrength(
      score: score,
      level: level,
      issues: issues,
      isValid: level == PasswordLevel.strong || level == PasswordLevel.medium,
    );
  }

  /// Vérifie les patterns communs
  bool _hasCommonPatterns(String password) {
    final commonPatterns = [
      '123456', 'password', 'qwerty', 'abc123', 'letmein',
      '111111', '123123', 'admin', 'welcome', 'monkey',
      'azerty', 'motdepasse', '000000',
    ];

    final lowerPassword = password.toLowerCase();
    for (final pattern in commonPatterns) {
      if (lowerPassword.contains(pattern)) return true;
    }

    // Vérifier les séquences
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) return true; // aaa, 111
    if (RegExp(r'(012|123|234|345|456|567|678|789)').hasMatch(password)) return true;
    if (RegExp(r'(abc|bcd|cde|def|efg)').hasMatch(lowerPassword)) return true;

    return false;
  }

  // ==================== UTILITAIRES ====================

  /// Génère un token aléatoire sécurisé
  String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Génère un code de vérification numérique
  String generateVerificationCode({int length = 6}) {
    final random = Random.secure();
    final code = StringBuffer();
    for (var i = 0; i < length; i++) {
      code.write(random.nextInt(10));
    }
    return code.toString();
  }

  /// Compare deux chaînes de manière sécurisée (timing-safe)
  bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Masque une donnée sensible pour l'affichage
  String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    final visible = data.substring(data.length - visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return masked + visible;
  }

  /// Masque un email pour l'affichage
  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.length <= 2) {
      return '***@$domain';
    }

    final visible = localPart[0];
    final masked = '*' * (localPart.length - 1);
    return '$visible$masked@$domain';
  }
}

/// Exception pour les erreurs de chiffrement
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Niveau de force du mot de passe
enum PasswordLevel { veryWeak, weak, medium, strong }

/// Résultat de validation de mot de passe
class PasswordStrength {
  final int score;
  final PasswordLevel level;
  final List<String> issues;
  final bool isValid;

  PasswordStrength({
    required this.score,
    required this.level,
    required this.issues,
    required this.isValid,
  });

  String get levelText {
    switch (level) {
      case PasswordLevel.veryWeak:
        return 'Très faible';
      case PasswordLevel.weak:
        return 'Faible';
      case PasswordLevel.medium:
        return 'Moyen';
      case PasswordLevel.strong:
        return 'Fort';
    }
  }

  double get percentage {
    return (score / 7 * 100).clamp(0, 100);
  }
}
