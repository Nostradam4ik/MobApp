import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../data/models/budget.dart';
import '../data/models/income.dart';

/// Service de génération de rapports mensuels PDF
class MonthlyReportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'fr_FR');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  /// Génère un rapport PDF mensuel complet
  Future<Uint8List> generateMonthlyReport({
    required DateTime month,
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<Category> categories,
    required List<Budget> budgets,
    required String userName,
    required String currency,
  }) async {
    final pdf = pw.Document();

    // Calculs
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (balance / totalIncome * 100) : 0.0;

    // Dépenses par catégorie
    final expensesByCategory = <String, double>{};
    for (final expense in expenses) {
      final catName = expense.category?.name ?? 'Sans catégorie';
      expensesByCategory[catName] = (expensesByCategory[catName] ?? 0) + expense.amount;
    }

    // Revenus par type
    final incomesByType = <String, double>{};
    for (final income in incomes) {
      incomesByType[income.type.label] = (incomesByType[income.type.label] ?? 0) + income.amount;
    }

    // Trier par montant décroissant
    final sortedExpenses = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(month, userName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Résumé
          _buildSummarySection(totalIncome, totalExpenses, balance, savingsRate),
          pw.SizedBox(height: 20),

          // Graphique des dépenses par catégorie
          _buildExpensesByCategorySection(sortedExpenses, totalExpenses),
          pw.SizedBox(height: 20),

          // Revenus
          _buildIncomeSection(incomesByType, totalIncome),
          pw.SizedBox(height: 20),

          // Budgets
          _buildBudgetSection(budgets),
          pw.SizedBox(height: 20),

          // Liste des transactions
          _buildTransactionsSection(expenses, incomes),
          pw.SizedBox(height: 20),

          // Conseils
          _buildAdviceSection(balance, savingsRate, sortedExpenses),
        ],
      ),
    );

    return pdf.save();
  }

  /// En-tête du rapport
  pw.Widget _buildHeader(DateTime month, String userName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
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
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Rapport Mensuel',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _monthFormat.format(month).toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                userName,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pied de page
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
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

  /// Section résumé
  pw.Widget _buildSummarySection(
    double income,
    double expenses,
    double balance,
    double savingsRate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉSUMÉ FINANCIER',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Revenus', income, PdfColors.green700),
              _buildSummaryCard('Dépenses', expenses, PdfColors.red700),
              _buildSummaryCard('Balance', balance, balance >= 0 ? PdfColors.blue700 : PdfColors.red700),
              _buildSummaryCard('Épargne', savingsRate, PdfColors.purple700, isPercent: true),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(String label, double value, PdfColor color, {bool isPercent = false}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : _currencyFormat.format(value),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Section dépenses par catégorie
  pw.Widget _buildExpensesByCategorySection(
    List<MapEntry<String, double>> expenses,
    double total,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉPENSES PAR CATÉGORIE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...expenses.take(10).map((entry) {
          final percent = total > 0 ? (entry.value / total * 100) : 0.0;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      '${_currencyFormat.format(entry.value)} (${percent.toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: (percent * 10).round(),
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue400,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: ((100 - percent) * 10).round(),
                        child: pw.Container(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Section revenus
  pw.Widget _buildIncomeSection(Map<String, double> incomes, double total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REVENUS PAR TYPE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Type', isHeader: true),
                _tableCell('Montant', isHeader: true),
                _tableCell('%', isHeader: true),
              ],
            ),
            ...incomes.entries.map((entry) {
              final percent = total > 0 ? (entry.value / total * 100) : 0.0;
              return pw.TableRow(
                children: [
                  _tableCell(entry.key),
                  _tableCell(_currencyFormat.format(entry.value)),
                  _tableCell('${percent.toStringAsFixed(1)}%'),
                ],
              );
            }),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              children: [
                _tableCell('TOTAL', isHeader: true),
                _tableCell(_currencyFormat.format(total), isHeader: true),
                _tableCell('100%', isHeader: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Section budgets
  pw.Widget _buildBudgetSection(List<Budget> budgets) {
    if (budgets.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SUIVI DES BUDGETS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Budget', isHeader: true),
                _tableCell('Limite', isHeader: true),
                _tableCell('Dépensé', isHeader: true),
                _tableCell('Restant', isHeader: true),
                _tableCell('Statut', isHeader: true),
              ],
            ),
            ...budgets.map((budget) {
              final status = budget.isOverBudget
                  ? 'Dépassé'
                  : budget.shouldAlert
                      ? 'Attention'
                      : 'OK';
              final statusColor = budget.isOverBudget
                  ? PdfColors.red700
                  : budget.shouldAlert
                      ? PdfColors.orange700
                      : PdfColors.green700;

              return pw.TableRow(
                children: [
                  _tableCell(budget.displayName),
                  _tableCell(_currencyFormat.format(budget.monthlyLimit)),
                  _tableCell(_currencyFormat.format(budget.spent)),
                  _tableCell(_currencyFormat.format(budget.remaining)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      status,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Section transactions
  pw.Widget _buildTransactionsSection(List<Expense> expenses, List<Income> incomes) {
    // Fusionner et trier par date
    final allTransactions = <_Transaction>[];

    for (final expense in expenses) {
      allTransactions.add(_Transaction(
        date: expense.expenseDate,
        description: expense.note ?? expense.category?.name ?? 'Dépense',
        amount: -expense.amount,
        type: 'Dépense',
      ));
    }

    for (final income in incomes) {
      allTransactions.add(_Transaction(
        date: income.date,
        description: income.source ?? income.type.label,
        amount: income.amount,
        type: 'Revenu',
      ));
    }

    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAIL DES TRANSACTIONS (${allTransactions.length})',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Date', isHeader: true),
                _tableCell('Description', isHeader: true),
                _tableCell('Type', isHeader: true),
                _tableCell('Montant', isHeader: true),
              ],
            ),
            ...allTransactions.take(50).map((t) {
              final color = t.amount >= 0 ? PdfColors.green700 : PdfColors.red700;
              return pw.TableRow(
                children: [
                  _tableCell(_dateFormat.format(t.date)),
                  _tableCell(t.description),
                  _tableCell(t.type),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _currencyFormat.format(t.amount.abs()),
                      style: pw.TextStyle(fontSize: 10, color: color),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        if (allTransactions.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Text(
              '... et ${allTransactions.length - 50} autres transactions',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
      ],
    );
  }

  /// Section conseils
  pw.Widget _buildAdviceSection(
    double balance,
    double savingsRate,
    List<MapEntry<String, double>> expenses,
  ) {
    final tips = <String>[];

    if (balance < 0) {
      tips.add('⚠️ Votre balance est négative ce mois-ci. Essayez de réduire vos dépenses non essentielles.');
    }

    if (savingsRate < 10) {
      tips.add('💡 Votre taux d\'épargne est inférieur à 10%. L\'objectif recommandé est de 20%.');
    } else if (savingsRate >= 20) {
      tips.add('🎉 Excellent ! Votre taux d\'épargne de ${savingsRate.toStringAsFixed(1)}% est exemplaire.');
    }

    if (expenses.isNotEmpty) {
      final topCategory = expenses.first;
      tips.add('📊 "${topCategory.key}" représente votre plus gros poste de dépenses ce mois-ci.');
    }

    if (tips.isEmpty) {
      tips.add('✅ Votre gestion financière ce mois-ci est équilibrée. Continuez ainsi !');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONSEILS DU MOIS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...tips.map((tip) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(tip, style: const pw.TextStyle(fontSize: 11)),
          )),
        ],
      ),
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

class _Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final String type;

  _Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}
