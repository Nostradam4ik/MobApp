import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/export_service.dart';

/// Écran d'export des données - Design Premium
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  ExportPeriod _selectedPeriod = ExportPeriod.thisMonth;
  DateTimeRange? _customDateRange;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'Exporter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Premium
            _buildPremiumBanner(),
            const SizedBox(height: 24),

            // Format d'export
            _buildSectionTitle('Format d\'export'),
            const SizedBox(height: 12),
            _buildFormatSelector(),
            const SizedBox(height: 24),

            // Période
            _buildSectionTitle('Période'),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Aperçu
            _buildPreviewCard(),
            const SizedBox(height: 32),

            // Bouton d'export
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withOpacity(0.2),
            AppColors.accentGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fonctionnalité Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Exportez vos données en CSV ou PDF',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: ExportFormat.values.map((format) {
        final isSelected = _selectedFormat == format;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedFormat = format),
            child: Container(
              margin: EdgeInsets.only(
                right: format == ExportFormat.pdf ? 8 : 0,
                left: format == ExportFormat.csv ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: AppColors.primaryGradient)
                    : null,
                color: isSelected ? null : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.glassBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    format == ExportFormat.pdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.table_chart_rounded,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryDark,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format == ExportFormat.pdf ? 'PDF' : 'CSV',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format == ExportFormat.pdf
                        ? 'Rapport visuel'
                        : 'Tableur Excel',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: ExportPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          final isLast = period == ExportPeriod.values.last;

          return Column(
            children: [
              ListTile(
                onTap: () async {
                  if (period == ExportPeriod.custom) {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: AppColors.surfaceDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _customDateRange = range;
                        _selectedPeriod = period;
                      });
                    }
                  } else {
                    setState(() => _selectedPeriod = period);
                  }
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.glassDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getPeriodIcon(period),
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryDark,
                    size: 20,
                  ),
                ),
                title: Text(
                  _getPeriodTitle(period),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: period == ExportPeriod.custom && _customDateRange != null
                    ? Text(
                        '${DateFormat('dd/MM/yyyy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiaryDark,
                        ),
                      )
                    : null,
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: AppColors.glassBorder,
                  indent: 70,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final dateRange = _getDateRange();
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses.where((e) {
      return e.expenseDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
          e.expenseDate.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();

    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: AppColors.textSecondaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Aperçu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewRow(
            'Période',
            ExportService.formatPeriod(dateRange.start, dateRange.end),
          ),
          const SizedBox(height: 8),
          _buildPreviewRow('Transactions', '${expenses.length}'),
          const SizedBox(height: 8),
          _buildPreviewRow(
            'Total',
            currencyFormat.format(total),
            valueColor: AppColors.accent,
          ),
          const SizedBox(height: 8),
          _buildPreviewRow(
            'Format',
            _selectedFormat == ExportFormat.pdf ? 'PDF' : 'CSV',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiaryDark,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimaryDark,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isExporting ? null : _export,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFormat == ExportFormat.pdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.table_chart_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Exporter en ${_selectedFormat == ExportFormat.pdf ? 'PDF' : 'CSV'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getPeriodIcon(ExportPeriod period) {
    switch (period) {
      case ExportPeriod.thisMonth:
        return Icons.calendar_today_rounded;
      case ExportPeriod.lastMonth:
        return Icons.calendar_month_rounded;
      case ExportPeriod.last3Months:
        return Icons.date_range_rounded;
      case ExportPeriod.thisYear:
        return Icons.calendar_view_month_rounded;
      case ExportPeriod.custom:
        return Icons.edit_calendar_rounded;
    }
  }

  String _getPeriodTitle(ExportPeriod period) {
    switch (period) {
      case ExportPeriod.thisMonth:
        return 'Ce mois-ci';
      case ExportPeriod.lastMonth:
        return 'Le mois dernier';
      case ExportPeriod.last3Months:
        return 'Les 3 derniers mois';
      case ExportPeriod.thisYear:
        return 'Cette année';
      case ExportPeriod.custom:
        return 'Période personnalisée';
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ExportPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case ExportPeriod.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
      case ExportPeriod.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case ExportPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case ExportPeriod.custom:
        return _customDateRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      final dateRange = _getDateRange();
      final expenseProvider = context.read<ExpenseProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      // Filtrer les dépenses par période
      final expenses = expenseProvider.expenses.where((e) {
        return e.expenseDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            e.expenseDate.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();

      // Trier par date décroissante
      expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

      if (expenses.isEmpty) {
        _showSnackBar('Aucune dépense pour cette période', isError: true);
        setState(() => _isExporting = false);
        return;
      }

      final fileName = ExportService.generateFileName(
        'smartspend',
        dateRange.start,
        dateRange.end,
      );
      final period = ExportService.formatPeriod(dateRange.start, dateRange.end);

      bool success;
      if (_selectedFormat == ExportFormat.pdf) {
        success = await ExportService.exportToPDF(
          expenses: expenses,
          fileName: fileName,
          period: period,
          totalBudget: budgetProvider.globalBudget?.monthlyLimit,
        );
      } else {
        success = await ExportService.exportToCSV(
          expenses: expenses,
          fileName: fileName,
        );
      }

      if (success) {
        _showSnackBar('Export réussi !');
      } else {
        _showSnackBar('Erreur lors de l\'export', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

enum ExportFormat { pdf, csv }

enum ExportPeriod {
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}
