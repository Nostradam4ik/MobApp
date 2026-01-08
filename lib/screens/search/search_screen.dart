import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

/// Écran de recherche et filtres
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  // Filtres
  List<String> _selectedCategories = [];
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  bool _onlyRecurring = false;
  String _sortBy = 'date_desc';

  // Résultats
  List<Expense> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty || _hasFilters) {
      _performSearch();
    }
  }

  bool get _hasFilters =>
      _selectedCategories.isNotEmpty ||
      _dateRange != null ||
      _minAmount != null ||
      _maxAmount != null ||
      _onlyRecurring;

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);

    final expenseProvider = context.read<ExpenseProvider>();
    final allExpenses = expenseProvider.expenses;

    List<Expense> filtered = List.from(allExpenses);

    // Filtre par texte
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        final note = e.note?.toLowerCase() ?? '';
        final categoryName = e.category?.name.toLowerCase() ?? '';
        return note.contains(query) || categoryName.contains(query);
      }).toList();
    }

    // Filtre par catégories
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.categoryId != null && _selectedCategories.contains(e.categoryId)
      ).toList();
    }

    // Filtre par date
    if (_dateRange != null) {
      filtered = filtered.where((e) {
        return e.expenseDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               e.expenseDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filtre par montant
    if (_minAmount != null) {
      filtered = filtered.where((e) => e.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((e) => e.amount <= _maxAmount!).toList();
    }

    // Filtre récurrent
    if (_onlyRecurring) {
      filtered = filtered.where((e) => e.isRecurring).toList();
    }

    // Tri
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    setState(() {
      _results = filtered;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategories = [];
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _onlyRecurring = false;
      _sortBy = 'date_desc';
      _results = [];
      _hasSearched = false;
    });
  }

  Future<void> _selectDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.textPrimaryDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => _dateRange = range);
      _performSearch();
    }
  }

  void _showAmountFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minController = TextEditingController(
      text: _minAmount?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxAmount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Filtrer par montant',
          style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Montant minimum',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                suffixText: '€',
                suffixStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Montant maximum',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                suffixText: '€',
                suffixStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _minAmount = double.tryParse(minController.text);
                _maxAmount = double.tryParse(maxController.text);
              });
              Navigator.pop(context);
              _performSearch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = context.read<CategoryProvider>().categories;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Catégories',
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          if (_selectedCategories.length == categories.length) {
                            _selectedCategories = [];
                          } else {
                            _selectedCategories = categories.map((c) => c.id).toList();
                          }
                        });
                      },
                      child: Text(
                        _selectedCategories.length == categories.length
                            ? 'Tout désélectionner'
                            : 'Tout sélectionner',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _selectedCategories.contains(category.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.iconData,
                            size: 16,
                            color: isSelected ? Colors.white : category.colorValue,
                          ),
                          const SizedBox(width: 6),
                          Text(category.name),
                        ],
                      ),
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            _selectedCategories.add(category.id);
                          } else {
                            _selectedCategories.remove(category.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                      _performSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        title: Text(
          'Recherche',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: AppColors.error),
              onPressed: _clearFilters,
              tooltip: 'Effacer les filtres',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher une dépense...',
                hintStyle: TextStyle(color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          _clearFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  icon: Icons.category_rounded,
                  label: _selectedCategories.isEmpty
                      ? 'Catégories'
                      : '${_selectedCategories.length} catégories',
                  isActive: _selectedCategories.isNotEmpty,
                  onTap: _showCategoryFilterSheet,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  icon: Icons.date_range_rounded,
                  label: _dateRange != null
                      ? '${_dateFormat.format(_dateRange!.start)} - ${_dateFormat.format(_dateRange!.end)}'
                      : 'Période',
                  isActive: _dateRange != null,
                  onTap: _selectDateRange,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  icon: Icons.euro_rounded,
                  label: _minAmount != null || _maxAmount != null
                      ? '${_minAmount ?? 0}€ - ${_maxAmount ?? '∞'}€'
                      : 'Montant',
                  isActive: _minAmount != null || _maxAmount != null,
                  onTap: _showAmountFilterDialog,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  icon: Icons.repeat_rounded,
                  label: 'Récurrentes',
                  isActive: _onlyRecurring,
                  onTap: () {
                    setState(() => _onlyRecurring = !_onlyRecurring);
                    _performSearch();
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Tri
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _hasSearched ? '${_results.length} résultat(s)' : 'Utilisez les filtres pour rechercher',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                    if (_hasSearched) _performSearch();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'date_desc', child: Text('Date (récent)')),
                    const PopupMenuItem(value: 'date_asc', child: Text('Date (ancien)')),
                    const PopupMenuItem(value: 'amount_desc', child: Text('Montant (élevé)')),
                    const PopupMenuItem(value: 'amount_asc', child: Text('Montant (faible)')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Trier',
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? _buildEmptyState(isDark: isDark)
                    : _results.isEmpty
                        ? _buildNoResultsState(isDark: isDark)
                        : _buildResultsList(isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : (isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recherchez vos dépenses',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez un mot-clé ou utilisez les filtres',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState({required bool isDark}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun résultat',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres critères',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList({required bool isDark}) {
    // Calculer le total
    final total = _results.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        // Total
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final expense = _results[index];
              return _buildExpenseItem(expense, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense, {required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/expense/${expense.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (expense.category?.colorValue ?? AppColors.primary)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    expense.category?.iconData ?? Icons.category,
                    color: expense.category?.colorValue ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category?.name ?? 'Sans catégorie',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (expense.note?.isNotEmpty == true)
                        Text(
                          expense.note!,
                          style: TextStyle(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        _dateFormat.format(expense.expenseDate),
                        style: TextStyle(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${expense.amount.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (expense.isRecurring)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Récurrent',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
