import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../data/models/budget.dart';
import '../data/models/goal.dart';
import '../data/models/income.dart';
import '../data/models/account.dart';
import '../data/models/tag.dart';
import 'security/encryption_service.dart';

/// Service de sauvegarde et restauration des données
class BackupService {
  static const String _backupVersion = '1.0.0';
  static const String _fileExtension = '.smartspend';
  static const String _encryptedExtension = '.smartspend.enc';

  EncryptionService? _encryption;

  BackupService({EncryptionService? encryption}) : _encryption = encryption;

  /// Initialise le service d'encryption si nécessaire
  Future<void> initEncryption() async {
    _encryption ??= await EncryptionService.getInstance();
  }

  // ==================== EXPORT ====================

  /// Crée une sauvegarde complète de toutes les données
  Future<BackupData> createBackup({
    required List<Expense> expenses,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<Income> incomes,
    required List<Account> accounts,
    required List<Tag> tags,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? userProfile,
  }) async {
    final now = DateTime.now();

    final backup = BackupData(
      version: _backupVersion,
      createdAt: now,
      deviceInfo: await _getDeviceInfo(),
      data: BackupContent(
        expenses: expenses,
        categories: categories,
        budgets: budgets,
        goals: goals,
        incomes: incomes,
        accounts: accounts,
        tags: tags,
        settings: settings ?? {},
        userProfile: userProfile ?? {},
      ),
      stats: BackupStats(
        expenseCount: expenses.length,
        categoryCount: categories.length,
        budgetCount: budgets.length,
        goalCount: goals.length,
        incomeCount: incomes.length,
        accountCount: accounts.length,
        tagCount: tags.length,
        totalExpenseAmount: expenses.fold(0.0, (sum, e) => sum + e.amount),
        totalIncomeAmount: incomes.fold(0.0, (sum, i) => sum + i.amount),
        dateRange: _calculateDateRange(expenses, incomes),
      ),
    );

    return backup;
  }

  /// Exporte la sauvegarde en JSON
  Future<Uint8List> exportToJson(BackupData backup) async {
    final json = backup.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Exporte la sauvegarde chiffrée
  Future<Uint8List> exportEncrypted(BackupData backup, {String? password}) async {
    await initEncryption();

    final json = backup.toJson();
    final jsonString = jsonEncode(json);

    // Utiliser le mot de passe fourni ou la clé par défaut
    String encrypted;
    if (password != null && password.isNotEmpty) {
      // Créer une clé à partir du mot de passe
      final passwordHash = _encryption!.hashString(password);
      // Pour simplifier, on utilise le hash comme partie de la donnée
      encrypted = _encryption!.encryptString('$passwordHash|$jsonString');
    } else {
      encrypted = _encryption!.encryptString(jsonString);
    }

    return Uint8List.fromList(utf8.encode(encrypted));
  }

  /// Génère un nom de fichier pour la sauvegarde
  String generateBackupFileName({bool encrypted = false}) {
    final date = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final ext = encrypted ? _encryptedExtension : _fileExtension;
    return 'smartspend_backup_$date$ext';
  }

  // ==================== IMPORT ====================

  /// Importe une sauvegarde depuis du JSON
  Future<BackupData?> importFromJson(Uint8List data) async {
    try {
      final jsonString = utf8.decode(data);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return BackupData.fromJson(json);
    } catch (e) {
      throw BackupException('Erreur lors de l\'import: $e');
    }
  }

  /// Importe une sauvegarde chiffrée
  Future<BackupData?> importEncrypted(Uint8List data, {String? password}) async {
    await initEncryption();

    try {
      final encryptedString = utf8.decode(data);
      String decrypted;

      try {
        decrypted = _encryption!.decryptString(encryptedString);
      } catch (e) {
        throw BackupException('Impossible de déchiffrer le fichier. Vérifiez le mot de passe.');
      }

      // Vérifier si un mot de passe était utilisé
      if (password != null && password.isNotEmpty) {
        final passwordHash = _encryption!.hashString(password);
        if (!decrypted.startsWith('$passwordHash|')) {
          throw BackupException('Mot de passe incorrect.');
        }
        decrypted = decrypted.substring(passwordHash.length + 1);
      }

      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      return BackupData.fromJson(json);
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Erreur lors de l\'import chiffré: $e');
    }
  }

  /// Détecte le type de fichier de sauvegarde
  BackupFileType detectFileType(String filename) {
    if (filename.endsWith(_encryptedExtension)) {
      return BackupFileType.encrypted;
    } else if (filename.endsWith(_fileExtension)) {
      return BackupFileType.json;
    } else if (filename.endsWith('.json')) {
      return BackupFileType.json;
    }
    return BackupFileType.unknown;
  }

  /// Valide une sauvegarde avant import
  BackupValidation validateBackup(BackupData backup) {
    final issues = <String>[];
    final warnings = <String>[];

    // Vérifier la version
    if (backup.version != _backupVersion) {
      final versionNum = double.tryParse(backup.version) ?? 0;
      final currentNum = double.tryParse(_backupVersion) ?? 0;

      if (versionNum > currentNum) {
        issues.add('Version de sauvegarde plus récente que l\'app');
      } else {
        warnings.add('Ancienne version de sauvegarde (${backup.version})');
      }
    }

    // Vérifier les données
    if (backup.data.expenses.isEmpty &&
        backup.data.incomes.isEmpty &&
        backup.data.categories.isEmpty) {
      warnings.add('La sauvegarde ne contient aucune donnée');
    }

    // Vérifier les catégories référencées
    final categoryIds = backup.data.categories.map((c) => c.id).toSet();
    for (final expense in backup.data.expenses) {
      if (expense.categoryId != null && !categoryIds.contains(expense.categoryId)) {
        warnings.add('Certaines dépenses référencent des catégories manquantes');
        break;
      }
    }

    // Note: Le modèle Expense ne supporte pas accountId pour le moment
    // Cette validation sera ajoutée quand le multi-compte sera implémenté
    // final accountIds = backup.data.accounts.map((a) => a.id).toSet();

    return BackupValidation(
      isValid: issues.isEmpty,
      issues: issues,
      warnings: warnings,
      stats: backup.stats,
    );
  }

  // ==================== UTILITAIRES ====================

  Future<Map<String, String>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }

  DateRange? _calculateDateRange(List<Expense> expenses, List<Income> incomes) {
    final allDates = <DateTime>[
      ...expenses.map((e) => e.expenseDate),
      ...incomes.map((i) => i.date),
    ];

    if (allDates.isEmpty) return null;

    allDates.sort();
    return DateRange(
      start: allDates.first,
      end: allDates.last,
    );
  }
}

/// Types de fichiers de sauvegarde
enum BackupFileType {
  json,
  encrypted,
  unknown,
}

/// Données de sauvegarde complètes
class BackupData {
  final String version;
  final DateTime createdAt;
  final Map<String, String> deviceInfo;
  final BackupContent data;
  final BackupStats stats;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.deviceInfo,
    required this.data,
    required this.stats,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deviceInfo: Map<String, String>.from(json['device_info'] as Map),
      data: BackupContent.fromJson(json['data'] as Map<String, dynamic>),
      stats: BackupStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'device_info': deviceInfo,
      'data': data.toJson(),
      'stats': stats.toJson(),
    };
  }
}

/// Contenu de la sauvegarde
class BackupContent {
  final List<Expense> expenses;
  final List<Category> categories;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<Income> incomes;
  final List<Account> accounts;
  final List<Tag> tags;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> userProfile;

  const BackupContent({
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.goals,
    required this.incomes,
    required this.accounts,
    required this.tags,
    required this.settings,
    required this.userProfile,
  });

  factory BackupContent.fromJson(Map<String, dynamic> json) {
    return BackupContent(
      expenses: (json['expenses'] as List?)
          ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      categories: (json['categories'] as List?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      budgets: (json['budgets'] as List?)
          ?.map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      goals: (json['goals'] as List?)
          ?.map((e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      incomes: (json['incomes'] as List?)
          ?.map((e) => Income.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      accounts: (json['accounts'] as List?)
          ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      tags: (json['tags'] as List?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      userProfile: json['user_profile'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'incomes': incomes.map((e) => e.toJson()).toList(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'settings': settings,
      'user_profile': userProfile,
    };
  }
}

/// Statistiques de la sauvegarde
class BackupStats {
  final int expenseCount;
  final int categoryCount;
  final int budgetCount;
  final int goalCount;
  final int incomeCount;
  final int accountCount;
  final int tagCount;
  final double totalExpenseAmount;
  final double totalIncomeAmount;
  final DateRange? dateRange;

  const BackupStats({
    required this.expenseCount,
    required this.categoryCount,
    required this.budgetCount,
    required this.goalCount,
    required this.incomeCount,
    required this.accountCount,
    required this.tagCount,
    required this.totalExpenseAmount,
    required this.totalIncomeAmount,
    this.dateRange,
  });

  factory BackupStats.fromJson(Map<String, dynamic> json) {
    return BackupStats(
      expenseCount: json['expense_count'] as int? ?? 0,
      categoryCount: json['category_count'] as int? ?? 0,
      budgetCount: json['budget_count'] as int? ?? 0,
      goalCount: json['goal_count'] as int? ?? 0,
      incomeCount: json['income_count'] as int? ?? 0,
      accountCount: json['account_count'] as int? ?? 0,
      tagCount: json['tag_count'] as int? ?? 0,
      totalExpenseAmount: (json['total_expense_amount'] as num?)?.toDouble() ?? 0,
      totalIncomeAmount: (json['total_income_amount'] as num?)?.toDouble() ?? 0,
      dateRange: json['date_range'] != null
          ? DateRange.fromJson(json['date_range'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_count': expenseCount,
      'category_count': categoryCount,
      'budget_count': budgetCount,
      'goal_count': goalCount,
      'income_count': incomeCount,
      'account_count': accountCount,
      'tag_count': tagCount,
      'total_expense_amount': totalExpenseAmount,
      'total_income_amount': totalIncomeAmount,
      'date_range': dateRange?.toJson(),
    };
  }

  int get totalItems =>
      expenseCount + categoryCount + budgetCount + goalCount +
      incomeCount + accountCount + tagCount;
}

/// Plage de dates
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  int get daySpan => end.difference(start).inDays;
}

/// Résultat de validation
class BackupValidation {
  final bool isValid;
  final List<String> issues;
  final List<String> warnings;
  final BackupStats stats;

  const BackupValidation({
    required this.isValid,
    required this.issues,
    required this.warnings,
    required this.stats,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Exception de sauvegarde
class BackupException implements Exception {
  final String message;
  BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
