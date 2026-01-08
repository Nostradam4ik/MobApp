import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';

/// Résultat d'import
class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final int errorCount;
  final String message;
  final List<String> errors;

  ImportResult({
    required this.success,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errorCount = 0,
    required this.message,
    this.errors = const [],
  });
}

/// Données d'import parsées
class ParsedExpense {
  final DateTime date;
  final double amount;
  final String? description;
  final String? categoryName;
  final bool isValid;
  final String? error;

  ParsedExpense({
    required this.date,
    required this.amount,
    this.description,
    this.categoryName,
    this.isValid = true,
    this.error,
  });

  factory ParsedExpense.invalid(String error) {
    return ParsedExpense(
      date: DateTime.now(),
      amount: 0,
      isValid: false,
      error: error,
    );
  }
}

/// Service d'import de données
class ImportService {
  static final _supabase = Supabase.instance.client;

  // Formats de date supportés
  static final _dateFormats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('MM/dd/yyyy'),
  ];

  /// Lit un fichier CSV depuis le web
  static Future<String?> pickAndReadCSVFile() async {
    if (!kIsWeb) return null;

    final completer = html.FileReader();
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return null;

    final file = input.files!.first;
    completer.readAsText(file);

    await completer.onLoadEnd.first;
    return completer.result as String?;
  }

  /// Parse le contenu CSV
  static List<ParsedExpense> parseCSV(String csvContent, {
    int dateColumn = 0,
    int amountColumn = 1,
    int descriptionColumn = 2,
    int categoryColumn = -1,
    bool hasHeader = true,
  }) {
    final List<ParsedExpense> results = [];

    try {
      final rows = const CsvToListConverter().convert(csvContent);

      for (int i = hasHeader ? 1 : 0; i < rows.length; i++) {
        final row = rows[i];

        try {
          // Date
          final dateStr = row[dateColumn]?.toString().trim() ?? '';
          final date = _parseDate(dateStr);
          if (date == null) {
            results.add(ParsedExpense.invalid('Date invalide: $dateStr (ligne ${i + 1})'));
            continue;
          }

          // Montant
          final amountStr = row[amountColumn]?.toString().trim() ?? '';
          final amount = _parseAmount(amountStr);
          if (amount == null || amount <= 0) {
            results.add(ParsedExpense.invalid('Montant invalide: $amountStr (ligne ${i + 1})'));
            continue;
          }

          // Description
          String? description;
          if (descriptionColumn >= 0 && descriptionColumn < row.length) {
            description = row[descriptionColumn]?.toString().trim();
          }

          // Catégorie
          String? categoryName;
          if (categoryColumn >= 0 && categoryColumn < row.length) {
            categoryName = row[categoryColumn]?.toString().trim();
          }

          results.add(ParsedExpense(
            date: date,
            amount: amount.abs(), // Toujours positif
            description: description,
            categoryName: categoryName,
          ));
        } catch (e) {
          results.add(ParsedExpense.invalid('Erreur ligne ${i + 1}: $e'));
        }
      }
    } catch (e) {
      results.add(ParsedExpense.invalid('Erreur de parsing CSV: $e'));
    }

    return results;
  }

  /// Parse une date avec plusieurs formats
  static DateTime? _parseDate(String dateStr) {
    for (final format in _dateFormats) {
      try {
        return format.parseStrict(dateStr);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Parse un montant
  static double? _parseAmount(String amountStr) {
    // Nettoyer la chaîne
    var cleaned = amountStr
        .replaceAll('€', '')
        .replaceAll('\$', '')
        .replaceAll(' ', '')
        .trim();

    // Gérer les séparateurs européens (1.234,56)
    if (cleaned.contains(',') && cleaned.contains('.')) {
      // Format européen: 1.234,56
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      // Virgule comme décimal
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  /// Importe les dépenses parsées dans la base de données
  static Future<ImportResult> importExpenses({
    required List<ParsedExpense> expenses,
    required List<Category> categories,
    String? defaultCategoryId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return ImportResult(
        success: false,
        message: 'Utilisateur non connecté',
      );
    }

    int imported = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    // Créer un map des catégories par nom
    final categoryMap = <String, String>{};
    for (final cat in categories) {
      categoryMap[cat.name.toLowerCase()] = cat.id;
    }

    for (final expense in expenses) {
      if (!expense.isValid) {
        errors++;
        if (expense.error != null) {
          errorMessages.add(expense.error!);
        }
        continue;
      }

      try {
        // Trouver la catégorie
        String? categoryId = defaultCategoryId;
        if (expense.categoryName != null) {
          final catName = expense.categoryName!.toLowerCase();
          if (categoryMap.containsKey(catName)) {
            categoryId = categoryMap[catName];
          }
        }

        // Créer la dépense
        await _supabase.from('expenses').insert({
          'user_id': userId,
          'category_id': categoryId,
          'amount': expense.amount,
          'note': expense.description,
          'expense_date': expense.date.toIso8601String().split('T')[0],
          'is_recurring': false,
        });

        imported++;
      } catch (e) {
        errors++;
        errorMessages.add('Erreur import: $e');
      }
    }

    return ImportResult(
      success: errors == 0,
      importedCount: imported,
      skippedCount: skipped,
      errorCount: errors,
      message: 'Import terminé: $imported importés, $errors erreurs',
      errors: errorMessages.take(10).toList(),
    );
  }

  /// Détecte automatiquement les colonnes d'un CSV
  static Map<String, int> detectColumns(String csvContent) {
    final result = <String, int>{
      'date': -1,
      'amount': -1,
      'description': -1,
      'category': -1,
    };

    try {
      final rows = const CsvToListConverter().convert(csvContent);
      if (rows.isEmpty) return result;

      final header = rows.first.map((e) => e.toString().toLowerCase()).toList();

      for (int i = 0; i < header.length; i++) {
        final col = header[i];

        if (col.contains('date') || col.contains('jour')) {
          result['date'] = i;
        } else if (col.contains('montant') || col.contains('amount') || col.contains('somme') || col.contains('valeur')) {
          result['amount'] = i;
        } else if (col.contains('description') || col.contains('libellé') || col.contains('libelle') || col.contains('note') || col.contains('label')) {
          result['description'] = i;
        } else if (col.contains('catégorie') || col.contains('categorie') || col.contains('category') || col.contains('type')) {
          result['category'] = i;
        }
      }

      // Si pas trouvé par header, deviner par contenu
      if (result['date'] == -1 || result['amount'] == -1) {
        if (rows.length > 1) {
          final dataRow = rows[1];
          for (int i = 0; i < dataRow.length; i++) {
            final value = dataRow[i].toString();

            if (result['date'] == -1 && _parseDate(value) != null) {
              result['date'] = i;
            } else if (result['amount'] == -1 && _parseAmount(value) != null) {
              result['amount'] = i;
            }
          }
        }
      }
    } catch (_) {}

    return result;
  }

  /// Prévisualise les données d'import
  static List<Map<String, String>> previewCSV(String csvContent, {int maxRows = 5}) {
    final preview = <Map<String, String>>[];

    try {
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) return preview;

      final headers = rows.first.map((e) => e.toString()).toList();

      for (int i = 1; i < rows.length && i <= maxRows; i++) {
        final row = rows[i];
        final rowMap = <String, String>{};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowMap[headers[j]] = row[j].toString();
        }

        preview.add(rowMap);
      }
    } catch (_) {}

    return preview;
  }
}
