import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../services/recurring_expense_service.dart';

/// Écran de gestion des dépenses récurrentes
class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  List<Expense> _recurringExpenses = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  @override
  void initState() {
    super.initState();
    _loadRecurringExpenses();
  }

  Future<void> _loadRecurringExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await RecurringExpenseService.getRecurringExpenses();
      setState(() {
        _recurringExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = RecurringExpenseService.calculateMonthlyTotal(_recurringExpenses);

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
          'Dépenses récurrentes',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurringDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecurringExpenses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé mensuel
                    _buildMonthlySummary(monthlyTotal),
                    const SizedBox(height: 24),

                    // Info
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Liste des dépenses récurrentes
                    if (_recurringExpenses.isEmpty)
                      _buildEmptyState()
                    else
                      ..._recurringExpenses.map((expense) => _buildRecurringCard(expense)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthlySummary(double monthlyTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.2),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.repeat_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total mensuel estimé',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(monthlyTotal),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_recurringExpenses.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'abonnements',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les dépenses récurrentes sont automatiquement ajoutées chaque mois.',
              style: TextStyle(
                color: AppColors.accentBlue,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.repeat_rounded,
              size: 48,
              color: AppColors.textTertiaryDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune dépense récurrente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos abonnements et dépenses mensuelles pour un meilleur suivi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringCard(Expense expense) {
    final frequency = RecurringFrequency.fromString(
      expense.recurringFrequency ?? 'monthly',
    );
    final nextDate = RecurringExpenseService.getNextPaymentDate(expense);
    final categoryColor = expense.category?.colorValue ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditRecurringDialog(expense),
          onLongPress: () => _showDeleteDialog(expense),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône catégorie
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withOpacity(0.2),
                        categoryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    expense.category?.iconData ?? Icons.category_rounded,
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Détails
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category?.name ?? 'Sans catégorie',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              frequency.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppColors.textTertiaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Prochain: ${DateFormat('dd/MM').format(nextDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiaryDark,
                            ),
                          ),
                        ],
                      ),
                      if (expense.note != null && expense.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          expense.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Montant
                Text(
                  _currencyFormat.format(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRecurringDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecurringExpenseForm(
        onSaved: () {
          Navigator.pop(context);
          _loadRecurringExpenses();
          _showSnackBar('Dépense récurrente ajoutée');
        },
      ),
    );
  }

  void _showEditRecurringDialog(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecurringExpenseForm(
        expense: expense,
        onSaved: () {
          Navigator.pop(context);
          _loadRecurringExpenses();
          _showSnackBar('Dépense récurrente modifiée');
        },
      ),
    );
  }

  void _showDeleteDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer ?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Text(
          'Voulez-vous supprimer cette dépense récurrente ?\n\n${expense.category?.name ?? "Dépense"} - ${_currencyFormat.format(expense.amount)}',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await RecurringExpenseService.deleteRecurringExpense(expense.id);
              _loadRecurringExpenses();
              _showSnackBar('Dépense supprimée');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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

/// Formulaire d'ajout/modification de dépense récurrente
class _RecurringExpenseForm extends StatefulWidget {
  final Expense? expense;
  final VoidCallback onSaved;

  const _RecurringExpenseForm({
    this.expense,
    required this.onSaved,
  });

  @override
  State<_RecurringExpenseForm> createState() => _RecurringExpenseFormState();
}

class _RecurringExpenseFormState extends State<_RecurringExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Category? _selectedCategory;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _noteController.text = widget.expense!.note ?? '';
      _selectedFrequency = RecurringFrequency.fromString(
        widget.expense!.recurringFrequency ?? 'monthly',
      );
      _startDate = widget.expense!.expenseDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                isEditing ? 'Modifier la récurrence' : 'Nouvelle récurrence',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 24),

              // Catégorie
              Text(
                'Catégorie',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, _) {
                  final categories = categoryProvider.activeCategories;

                  // Initialiser la catégorie si édition
                  if (isEditing && _selectedCategory == null) {
                    _selectedCategory = categories.firstWhere(
                      (c) => c.id == widget.expense!.categoryId,
                      orElse: () => categories.first,
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.glassDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Category>(
                        value: _selectedCategory,
                        hint: Text(
                          'Sélectionner une catégorie',
                          style: TextStyle(color: AppColors.textTertiaryDark),
                        ),
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceDark,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  category.iconData,
                                  color: category.colorValue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Montant
              Text(
                'Montant',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                  suffixText: '€',
                  suffixStyle: const TextStyle(color: AppColors.textPrimaryDark),
                  filled: true,
                  fillColor: AppColors.glassDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Fréquence
              Text(
                'Fréquence',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.glassDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RecurringFrequency>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceDark,
                    items: RecurringFrequency.values.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(
                          freq.label,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFrequency = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note
              Text(
                'Note (optionnel)',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: 'Ex: Netflix, Loyer...',
                  hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                  filled: true,
                  fillColor: AppColors.glassDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Enregistrer' : 'Ajouter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (isEditing) {
        final updated = widget.expense!.copyWith(
          categoryId: _selectedCategory!.id,
          amount: amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          recurringFrequency: _selectedFrequency.value,
        );
        await RecurringExpenseService.updateRecurringExpense(updated);
      } else {
        await RecurringExpenseService.createRecurringExpense(
          categoryId: _selectedCategory!.id,
          amount: amount,
          frequency: _selectedFrequency,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          startDate: _startDate,
        );
      }

      widget.onSaved();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
