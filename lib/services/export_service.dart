import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import '../data/models/expense.dart';

/// Service pour l'export des données en CSV et PDF
class ExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');

  /// Formate un montant avec le symbole euro
  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }

  /// Exporte les dépenses en CSV
  static Future<bool> exportToCSV({
    required List<Expense> expenses,
    required String fileName,
  }) async {
    try {
      // En-têtes
      final headers = [
        'Date',
        'Catégorie',
        'Montant',
        'Note',
        'Récurrent',
      ];

      // Données
      final rows = expenses.map((expense) {
        return [
          _dateFormat.format(expense.expenseDate),
          expense.category?.name ?? 'Sans catégorie',
          expense.amount.toStringAsFixed(2),
          expense.note ?? '',
          expense.isRecurring ? 'Oui' : 'Non',
        ];
      }).toList();

      // Créer le CSV
      final csvData = [headers, ...rows];
      final csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        // Web: télécharger directement
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      return true;
    } catch (e) {
      print('Erreur export CSV: $e');
      return false;
    }
  }

  /// Exporte les dépenses en PDF
  static Future<bool> exportToPDF({
    required List<Expense> expenses,
    required String fileName,
    required String period,
    double? totalBudget,
  }) async {
    try {
      // Charger une police qui supporte l'euro
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      final pdf = pw.Document();
      final theme = pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      );

      // Calculer les totaux
      final totalExpenses = expenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

      // Grouper par catégorie
      final Map<String, double> categoryTotals = {};
      for (final expense in expenses) {
        final categoryName = expense.category?.name ?? 'Sans catégorie';
        categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + expense.amount;
      }

      // Trier par montant décroissant
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          header: (context) => _buildHeader(period),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            // Résumé
            _buildSummarySection(totalExpenses, totalBudget, expenses.length),
            pw.SizedBox(height: 20),

            // Répartition par catégorie
            _buildCategorySection(sortedCategories, totalExpenses),
            pw.SizedBox(height: 20),

            // Liste des dépenses
            _buildExpenseTable(expenses),
          ],
        ),
      );

      // Sauvegarder/partager le PDF
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Web: télécharger directement
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile/Desktop: utiliser le dialog d'impression/partage
        await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
      }

      return true;
    } catch (e) {
      print('Erreur export PDF: $e');
      return false;
    }
  }

  /// Construit l'en-tête du PDF
  static pw.Widget _buildHeader(String period) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SmartSpend',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Rapport de dépenses',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              period,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le pied de page du PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Généré le ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Construit la section résumé
  static pw.Widget _buildSummarySection(
    double totalExpenses,
    double? totalBudget,
    int expenseCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total dépensé', _formatCurrency(totalExpenses), PdfColors.red700),
          if (totalBudget != null)
            _buildStatItem('Budget', _formatCurrency(totalBudget), PdfColors.blue700),
          _buildStatItem('Transactions', expenseCount.toString(), PdfColors.purple700),
          if (totalBudget != null)
            _buildStatItem(
              'Reste',
              _formatCurrency(totalBudget - totalExpenses),
              (totalBudget - totalExpenses) >= 0 ? PdfColors.green700 : PdfColors.red700,
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Construit la section catégories
  static pw.Widget _buildCategorySection(
    List<MapEntry<String, double>> categories,
    double total,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Répartition par catégorie',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...categories.take(10).map((entry) {
          final percentage = (entry.value / total * 100);
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.Container(
                        height: 16,
                        width: (percentage * 1.5).clamp(0, 150).toDouble(),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.purple400,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.SizedBox(
                  width: 60,
                  child: pw.Text(
                    _formatCurrency(entry.value),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.SizedBox(
                  width: 40,
                  child: pw.Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Construit le tableau des dépenses
  static pw.Widget _buildExpenseTable(List<Expense> expenses) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détail des dépenses',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.purple50),
              children: [
                _buildTableHeader('Date'),
                _buildTableHeader('Catégorie'),
                _buildTableHeader('Montant'),
                _buildTableHeader('Note'),
              ],
            ),
            // Lignes
            ...expenses.map((expense) {
              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(expense.expenseDate)),
                  _buildTableCell(expense.category?.name ?? 'Sans catégorie'),
                  _buildTableCell(
                    _formatCurrency(expense.amount),
                    isBold: true,
                    color: PdfColors.red700,
                  ),
                  _buildTableCell(expense.note ?? '-'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.purple700,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : null,
          color: color ?? PdfColors.grey800,
        ),
      ),
    );
  }

  /// Génère un nom de fichier avec la date
  static String generateFileName(String prefix, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    if (startDate != null && endDate != null) {
      final start = DateFormat('dd-MM').format(startDate);
      final end = DateFormat('dd-MM').format(endDate);
      return '${prefix}_${start}_au_$end';
    }

    return '${prefix}_$dateStr';
  }

  /// Formate une période pour l'affichage
  static String formatPeriod(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return _monthFormat.format(DateTime.now());
    }

    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      return _monthFormat.format(startDate);
    }

    return '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
  }
}
