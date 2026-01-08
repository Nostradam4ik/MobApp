// ============================================================================
// SmartSpend - Service d'import bancaire
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/expense.dart';
import '../data/models/category.dart' as models;

/// Types de banques supportées
enum BankType {
  // France
  bnpParibas,
  creditAgricole,
  societGenerale,
  labanquePostale,
  creditMutuel,
  caisseDEpargne,
  lcl,
  boursorama,
  fortuneo,
  helloBank,
  n26,
  revolut,

  // International
  ing,
  hsbc,
  santander,

  // Agrégateurs
  plaid,
  tink,
  budget_insight,

  // Fichiers
  csv,
  ofx,
  qif,
}

/// Informations sur une banque
class BankInfo {
  final BankType type;
  final String name;
  final String logo;
  final String country;
  final bool supportsDirectConnect;
  final bool supportsFileImport;
  final List<String> supportedFormats;

  const BankInfo({
    required this.type,
    required this.name,
    required this.logo,
    required this.country,
    this.supportsDirectConnect = false,
    this.supportsFileImport = true,
    this.supportedFormats = const ['csv', 'ofx'],
  });
}

/// Transaction bancaire importée
class BankTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String? category;
  final String? reference;
  final String? counterparty;
  final bool isDebit;
  final Map<String, dynamic>? metadata;

  BankTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.category,
    this.reference,
    this.counterparty,
    required this.isDebit,
    this.metadata,
  });

  /// Convertir en Expense
  Expense toExpense({
    required String userId,
    String? categoryId,
    String? accountId,
  }) {
    return Expense(
      id: id,
      userId: userId,
      amount: amount.abs(),
      categoryId: categoryId,
      accountId: accountId,
      expenseDate: date,
      note: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Résultat de l'import
class ImportResult {
  final bool success;
  final int totalTransactions;
  final int importedCount;
  final int skippedCount;
  final int duplicateCount;
  final List<BankTransaction> transactions;
  final String? error;
  final Map<String, int> categoryBreakdown;

  ImportResult({
    required this.success,
    this.totalTransactions = 0,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.duplicateCount = 0,
    this.transactions = const [],
    this.error,
    this.categoryBreakdown = const {},
  });

  factory ImportResult.error(String message) {
    return ImportResult(
      success: false,
      error: message,
    );
  }
}

/// Service d'import bancaire
class BankImportService {
  /// Liste des banques supportées
  static final List<BankInfo> supportedBanks = [
    // France
    const BankInfo(
      type: BankType.bnpParibas,
      name: 'BNP Paribas',
      logo: '🏦',
      country: 'FR',
      supportsDirectConnect: true,
      supportedFormats: ['csv', 'ofx', 'qif'],
    ),
    const BankInfo(
      type: BankType.creditAgricole,
      name: 'Crédit Agricole',
      logo: '🏦',
      country: 'FR',
      supportsDirectConnect: true,
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.societGenerale,
      name: 'Société Générale',
      logo: '🏦',
      country: 'FR',
      supportsDirectConnect: true,
      supportedFormats: ['csv', 'ofx', 'qif'],
    ),
    const BankInfo(
      type: BankType.labanquePostale,
      name: 'La Banque Postale',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.creditMutuel,
      name: 'Crédit Mutuel',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.caisseDEpargne,
      name: 'Caisse d\'Épargne',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.lcl,
      name: 'LCL',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.boursorama,
      name: 'Boursorama',
      logo: '🏦',
      country: 'FR',
      supportsDirectConnect: true,
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.fortuneo,
      name: 'Fortuneo',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.helloBank,
      name: 'Hello Bank',
      logo: '🏦',
      country: 'FR',
      supportedFormats: ['csv', 'ofx'],
    ),

    // Néobanques
    const BankInfo(
      type: BankType.n26,
      name: 'N26',
      logo: '📱',
      country: 'EU',
      supportsDirectConnect: true,
      supportedFormats: ['csv'],
    ),
    const BankInfo(
      type: BankType.revolut,
      name: 'Revolut',
      logo: '📱',
      country: 'EU',
      supportsDirectConnect: true,
      supportedFormats: ['csv'],
    ),

    // International
    const BankInfo(
      type: BankType.ing,
      name: 'ING',
      logo: '🏦',
      country: 'EU',
      supportedFormats: ['csv', 'ofx'],
    ),
    const BankInfo(
      type: BankType.hsbc,
      name: 'HSBC',
      logo: '🏦',
      country: 'INTL',
      supportedFormats: ['csv', 'ofx', 'qif'],
    ),

    // Import fichier générique
    const BankInfo(
      type: BankType.csv,
      name: 'Fichier CSV',
      logo: '📄',
      country: 'ALL',
      supportedFormats: ['csv'],
    ),
    const BankInfo(
      type: BankType.ofx,
      name: 'Fichier OFX/QFX',
      logo: '📄',
      country: 'ALL',
      supportedFormats: ['ofx', 'qfx'],
    ),
    const BankInfo(
      type: BankType.qif,
      name: 'Fichier QIF',
      logo: '📄',
      country: 'ALL',
      supportedFormats: ['qif'],
    ),
  ];

  /// Parser un fichier CSV
  static Future<ImportResult> parseCSV({
    required String content,
    required BankType bankType,
    String delimiter = ';',
    int dateColumn = 0,
    int descriptionColumn = 1,
    int amountColumn = 2,
    String dateFormat = 'dd/MM/yyyy',
    bool hasHeader = true,
  }) async {
    try {
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return ImportResult.error('Fichier vide');
      }

      final transactions = <BankTransaction>[];
      final startIndex = hasHeader ? 1 : 0;

      for (var i = startIndex; i < lines.length; i++) {
        try {
          final columns = _parseCSVLine(lines[i], delimiter);
          if (columns.length <= [dateColumn, descriptionColumn, amountColumn].reduce((a, b) => a > b ? a : b)) {
            continue;
          }

          final dateStr = columns[dateColumn].trim();
          final description = columns[descriptionColumn].trim();
          final amountStr = columns[amountColumn].trim()
              .replaceAll(' ', '')
              .replaceAll(',', '.')
              .replaceAll('€', '')
              .replaceAll('\$', '');

          final date = _parseDate(dateStr, dateFormat);
          if (date == null) continue;

          final amount = double.tryParse(amountStr);
          if (amount == null) continue;

          transactions.add(BankTransaction(
            id: 'csv_${date.millisecondsSinceEpoch}_$i',
            date: date,
            description: description,
            amount: amount.abs(),
            isDebit: amount < 0,
          ));
        } catch (e) {
          debugPrint('Error parsing line $i: $e');
        }
      }

      return ImportResult(
        success: true,
        totalTransactions: lines.length - (hasHeader ? 1 : 0),
        importedCount: transactions.length,
        skippedCount: lines.length - (hasHeader ? 1 : 0) - transactions.length,
        transactions: transactions,
      );
    } catch (e) {
      return ImportResult.error('Erreur de parsing: $e');
    }
  }

  /// Parser une ligne CSV (gestion des guillemets)
  static List<String> _parseCSVLine(String line, String delimiter) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());

    return result;
  }

  /// Parser un fichier OFX
  static Future<ImportResult> parseOFX(String content) async {
    try {
      final transactions = <BankTransaction>[];

      // Regex pour extraire les transactions OFX
      final stmtTrnRegex = RegExp(r'<STMTTRN>(.*?)</STMTTRN>', dotAll: true);
      final matches = stmtTrnRegex.allMatches(content);

      for (final match in matches) {
        final trn = match.group(1) ?? '';

        // Extraire les champs
        final dtPosted = _extractOFXField(trn, 'DTPOSTED');
        final trnAmt = _extractOFXField(trn, 'TRNAMT');
        final name = _extractOFXField(trn, 'NAME');
        final memo = _extractOFXField(trn, 'MEMO');
        final fitid = _extractOFXField(trn, 'FITID');

        if (dtPosted != null && trnAmt != null) {
          final date = _parseOFXDate(dtPosted);
          final amount = double.tryParse(trnAmt.replaceAll(',', '.'));

          if (date != null && amount != null) {
            transactions.add(BankTransaction(
              id: fitid ?? 'ofx_${date.millisecondsSinceEpoch}',
              date: date,
              description: name ?? memo ?? 'Transaction',
              amount: amount.abs(),
              isDebit: amount < 0,
              reference: fitid,
            ));
          }
        }
      }

      return ImportResult(
        success: true,
        totalTransactions: matches.length,
        importedCount: transactions.length,
        transactions: transactions,
      );
    } catch (e) {
      return ImportResult.error('Erreur de parsing OFX: $e');
    }
  }

  /// Extraire un champ OFX
  static String? _extractOFXField(String content, String field) {
    final regex = RegExp('<$field>([^<\n]+)');
    final match = regex.firstMatch(content);
    return match?.group(1)?.trim();
  }

  /// Parser une date OFX (format YYYYMMDD ou YYYYMMDDHHMMSS)
  static DateTime? _parseOFXDate(String dateStr) {
    try {
      if (dateStr.length >= 8) {
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(4, 6));
        final day = int.parse(dateStr.substring(6, 8));
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing OFX date: $e');
    }
    return null;
  }

  /// Parser un fichier QIF
  static Future<ImportResult> parseQIF(String content) async {
    try {
      final transactions = <BankTransaction>[];
      final entries = content.split('^').where((e) => e.trim().isNotEmpty);

      for (final entry in entries) {
        final lines = entry.split('\n').where((l) => l.trim().isNotEmpty);

        DateTime? date;
        double? amount;
        String? payee;
        String? memo;

        for (final line in lines) {
          if (line.isEmpty) continue;
          final type = line[0];
          final value = line.substring(1).trim();

          switch (type) {
            case 'D':
              date = _parseQIFDate(value);
              break;
            case 'T':
            case 'U':
              amount = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
              break;
            case 'P':
              payee = value;
              break;
            case 'M':
              memo = value;
              break;
          }
        }

        if (date != null && amount != null) {
          transactions.add(BankTransaction(
            id: 'qif_${date.millisecondsSinceEpoch}_${transactions.length}',
            date: date,
            description: payee ?? memo ?? 'Transaction',
            amount: amount.abs(),
            isDebit: amount < 0,
            counterparty: payee,
          ));
        }
      }

      return ImportResult(
        success: true,
        totalTransactions: entries.length,
        importedCount: transactions.length,
        transactions: transactions,
      );
    } catch (e) {
      return ImportResult.error('Erreur de parsing QIF: $e');
    }
  }

  /// Parser une date QIF (formats variés)
  static DateTime? _parseQIFDate(String dateStr) {
    // Formats courants: M/D/YY, M/D/YYYY, D/M/YY, D/M/YYYY
    try {
      final parts = dateStr.split(RegExp(r'[/\-.]'));
      if (parts.length >= 3) {
        var year = int.parse(parts[2]);
        if (year < 100) {
          year += year > 50 ? 1900 : 2000;
        }
        return DateTime(year, int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (e) {
      debugPrint('Error parsing QIF date: $e');
    }
    return null;
  }

  /// Parser une date avec format personnalisé
  static DateTime? _parseDate(String dateStr, String format) {
    try {
      // Formats supportés: dd/MM/yyyy, MM/dd/yyyy, yyyy-MM-dd
      if (format == 'dd/MM/yyyy' || format == 'dd-MM-yyyy') {
        final parts = dateStr.split(RegExp(r'[/\-.]'));
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } else if (format == 'MM/dd/yyyy') {
        final parts = dateStr.split(RegExp(r'[/\-.]'));
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } else if (format == 'yyyy-MM-dd') {
        final parts = dateStr.split(RegExp(r'[/\-.]'));
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  /// Catégoriser automatiquement les transactions
  static String? autoCategorize(
    String description,
    List<models.Category> categories,
  ) {
    final desc = description.toLowerCase();

    // Règles de catégorisation basées sur des mots-clés
    final rules = <String, List<String>>{
      'restaurant': ['restaurant', 'cafe', 'bar', 'brasserie', 'pizza', 'sushi', 'mcdo', 'mcdonald', 'burger', 'kebab', 'starbucks'],
      'alimentation': ['carrefour', 'leclerc', 'auchan', 'lidl', 'aldi', 'intermarche', 'super u', 'monoprix', 'franprix', 'casino', 'picard'],
      'transport': ['uber', 'bolt', 'taxi', 'sncf', 'ratp', 'metro', 'bus', 'essence', 'total', 'bp', 'shell', 'parking'],
      'shopping': ['amazon', 'fnac', 'darty', 'zara', 'h&m', 'decathlon', 'ikea', 'leroy merlin'],
      'sante': ['pharmacie', 'medecin', 'docteur', 'hopital', 'clinique', 'dentiste', 'kine'],
      'loisirs': ['cinema', 'theatre', 'concert', 'netflix', 'spotify', 'deezer', 'playstation', 'xbox', 'nintendo'],
      'abonnements': ['orange', 'sfr', 'bouygues', 'free', 'canal', 'edf', 'engie', 'veolia'],
      'loyer': ['loyer', 'rent', 'proprietaire'],
      'banque': ['frais', 'commission', 'agios', 'interet'],
    };

    for (final entry in rules.entries) {
      for (final keyword in entry.value) {
        if (desc.contains(keyword)) {
          // Trouver la catégorie correspondante
          for (final category in categories) {
            if (category.name.toLowerCase().contains(entry.key)) {
              return category.id;
            }
          }
        }
      }
    }

    return null;
  }

  /// Détecter les doublons
  static List<BankTransaction> filterDuplicates(
    List<BankTransaction> newTransactions,
    List<Expense> existingExpenses,
  ) {
    return newTransactions.where((t) {
      // Vérifier si une dépense similaire existe déjà
      return !existingExpenses.any((e) =>
          e.expenseDate.year == t.date.year &&
          e.expenseDate.month == t.date.month &&
          e.expenseDate.day == t.date.day &&
          (e.amount - t.amount).abs() < 0.01 &&
          (e.note?.toLowerCase().contains(t.description.toLowerCase().substring(0, 5)) ?? false)
      );
    }).toList();
  }
}

/// Configuration d'import CSV personnalisée
class CSVImportConfig {
  final String delimiter;
  final int dateColumn;
  final int descriptionColumn;
  final int amountColumn;
  final int? categoryColumn;
  final String dateFormat;
  final bool hasHeader;
  final String encoding;

  const CSVImportConfig({
    this.delimiter = ';',
    this.dateColumn = 0,
    this.descriptionColumn = 1,
    this.amountColumn = 2,
    this.categoryColumn,
    this.dateFormat = 'dd/MM/yyyy',
    this.hasHeader = true,
    this.encoding = 'utf-8',
  });

  /// Configurations prédéfinies pour les banques françaises
  static const bnpParibas = CSVImportConfig(
    delimiter: ';',
    dateColumn: 0,
    descriptionColumn: 2,
    amountColumn: 3,
    dateFormat: 'dd/MM/yyyy',
  );

  static const creditAgricole = CSVImportConfig(
    delimiter: ';',
    dateColumn: 0,
    descriptionColumn: 1,
    amountColumn: 2,
    dateFormat: 'dd/MM/yyyy',
  );

  static const boursorama = CSVImportConfig(
    delimiter: ';',
    dateColumn: 0,
    descriptionColumn: 1,
    amountColumn: 2,
    dateFormat: 'yyyy-MM-dd',
  );

  static const n26 = CSVImportConfig(
    delimiter: ',',
    dateColumn: 0,
    descriptionColumn: 1,
    amountColumn: 2,
    dateFormat: 'yyyy-MM-dd',
  );

  static const revolut = CSVImportConfig(
    delimiter: ',',
    dateColumn: 0,
    descriptionColumn: 4,
    amountColumn: 2,
    dateFormat: 'yyyy-MM-dd',
  );
}
