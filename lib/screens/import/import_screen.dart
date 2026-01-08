import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/import_service.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

/// Écran d'import de données
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _csvContent;
  List<ParsedExpense> _parsedExpenses = [];
  Map<String, int> _detectedColumns = {};
  List<Map<String, String>> _preview = [];

  int _dateColumn = 0;
  int _amountColumn = 1;
  int _descriptionColumn = 2;
  int _categoryColumn = -1;
  bool _hasHeader = true;
  String? _selectedCategoryId;

  bool _isLoading = false;
  bool _isImporting = false;
  ImportResult? _result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        title: Text(
          'Importer des données',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _result != null
              ? _buildResultView(isDark)
              : _csvContent != null
                  ? _buildConfigView(isDark)
                  : _buildUploadView(isDark),
    );
  }

  Widget _buildUploadView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Importer un fichier CSV',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Importez vos dépenses depuis un relevé bancaire ou un autre fichier CSV',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Sélectionner un fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Format supporté
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Format attendu',
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date, Montant, Description, Catégorie (optionnel)',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exemple: 15/01/2025, 45.50, Restaurant, Alimentation',
                    style: TextStyle(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prévisualisation
          _buildSectionHeader(
            icon: Icons.preview_rounded,
            title: 'Aperçu des données',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _preview.isNotEmpty
                    ? _preview.first.keys.map((k) => DataColumn(
                        label: Text(k, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                      )).toList()
                    : [DataColumn(label: Text('Aucune donnée', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)))],
                rows: _preview.map((row) {
                  return DataRow(
                    cells: row.values.map((v) => DataCell(
                      Text(v, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
                    )).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Configuration des colonnes
          _buildSectionHeader(
            icon: Icons.settings_rounded,
            title: 'Configuration',
            color: AppColors.secondary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // En-tête
          _buildSettingRow(
            title: 'Le fichier contient un en-tête',
            isDark: isDark,
            child: Switch(
              value: _hasHeader,
              onChanged: (v) {
                setState(() => _hasHeader = v);
                _reparse();
              },
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Colonnes
          _buildColumnSelector('Colonne Date', _dateColumn, (v) {
            setState(() => _dateColumn = v ?? 0);
            _reparse();
          }, isDark: isDark),
          _buildColumnSelector('Colonne Montant', _amountColumn, (v) {
            setState(() => _amountColumn = v ?? 1);
            _reparse();
          }, isDark: isDark),
          _buildColumnSelector('Colonne Description', _descriptionColumn, (v) {
            setState(() => _descriptionColumn = v ?? -1);
            _reparse();
          }, isDark: isDark),
          _buildColumnSelector('Colonne Catégorie', _categoryColumn, (v) {
            setState(() => _categoryColumn = v ?? -1);
            _reparse();
          }, allowNone: true, isDark: isDark),

          const SizedBox(height: 16),

          // Catégorie par défaut
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catégorie par défaut',
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDark : AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text('Aucune', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
                        ...categoryProvider.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                      style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Résumé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_parsedExpenses.where((e) => e.isValid).length} dépenses valides sur ${_parsedExpenses.length} lignes',
                    style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _csvContent = null;
                      _parsedExpenses = [];
                      _preview = [];
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _parsedExpenses.any((e) => e.isValid) ? _import : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Importer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(bool isDark) {
    final result = _result!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: result.success
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.success ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 64,
                color: result.success ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result.success ? 'Import réussi !' : 'Import terminé avec des erreurs',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  '${result.importedCount}',
                  'Importées',
                  AppColors.success,
                  isDark,
                ),
                const SizedBox(width: 16),
                if (result.errorCount > 0)
                  _buildStatChip(
                    '${result.errorCount}',
                    'Erreurs',
                    AppColors.error,
                    isDark,
                  ),
              ],
            ),

            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Erreurs:',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.take(5).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        e,
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Recharger les dépenses et fermer
                context.read<ExpenseProvider>().loadExpenses();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Terminé'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({required String title, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildColumnSelector(String title, int value, ValueChanged<int?> onChanged, {bool allowNone = false, required bool isDark}) {
    final maxColumns = _preview.isNotEmpty ? _preview.first.length : 10;
    final headers = _preview.isNotEmpty ? _preview.first.keys.toList() : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
          DropdownButton<int>(
            value: value >= 0 ? value : null,
            items: [
              if (allowNone)
                DropdownMenuItem(value: -1, child: Text('Aucune', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary))),
              for (int i = 0; i < maxColumns; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(i < headers.length ? headers[i] : 'Col $i', style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                ),
            ],
            onChanged: onChanged,
            dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      final content = await ImportService.pickAndReadCSVFile();
      if (content != null) {
        setState(() {
          _csvContent = content;
          _detectedColumns = ImportService.detectColumns(content);
          _preview = ImportService.previewCSV(content);

          // Appliquer colonnes détectées
          if (_detectedColumns['date']! >= 0) _dateColumn = _detectedColumns['date']!;
          if (_detectedColumns['amount']! >= 0) _amountColumn = _detectedColumns['amount']!;
          if (_detectedColumns['description']! >= 0) _descriptionColumn = _detectedColumns['description']!;
          if (_detectedColumns['category']! >= 0) _categoryColumn = _detectedColumns['category']!;
        });

        _reparse();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _reparse() {
    if (_csvContent == null) return;

    setState(() {
      _parsedExpenses = ImportService.parseCSV(
        _csvContent!,
        dateColumn: _dateColumn,
        amountColumn: _amountColumn,
        descriptionColumn: _descriptionColumn,
        categoryColumn: _categoryColumn,
        hasHeader: _hasHeader,
      );
    });
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);

    try {
      final categories = context.read<CategoryProvider>().categories;

      final result = await ImportService.importExpenses(
        expenses: _parsedExpenses.where((e) => e.isValid).toList(),
        categories: categories,
        defaultCategoryId: _selectedCategoryId,
      );

      setState(() => _result = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isImporting = false);
  }
}
