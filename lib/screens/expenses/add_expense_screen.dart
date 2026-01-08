import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/category.dart';
import '../../data/models/account.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../services/currency_service.dart';
import '../../widgets/common/custom_button.dart';

/// Écran d'ajout de dépense
class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialiser avec le compte par défaut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = context.read<AccountProvider>();
      if (accountProvider.hasAccounts) {
        setState(() {
          _selectedAccount = accountProvider.defaultAccount;
        });
      }
    });

    if (widget.existingExpense != null) {
      _selectedCategory = widget.existingExpense!['category'] as Category?;

      // Pré-remplir le montant si venant du scanner
      final amount = widget.existingExpense!['amount'];
      if (amount != null && amount is double) {
        _amountController.text = amount.toStringAsFixed(2);
      }

      // Pré-remplir la date si venant du scanner
      final date = widget.existingExpense!['date'];
      if (date != null && date is DateTime) {
        _selectedDate = date;
      }

      // Pré-remplir la note si venant du scanner
      final note = widget.existingExpense!['note'];
      if (note != null && note is String) {
        _noteController.text = note;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final expenseProvider = context.read<ExpenseProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final accountProvider = context.read<AccountProvider>();

    final success = await expenseProvider.createExpense(
      amount: amount,
      categoryId: _selectedCategory?.id,
      accountId: _selectedAccount?.id,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      date: _selectedDate,
      category: _selectedCategory,
    );

    if (success && mounted) {
      // Mettre à jour le solde du compte
      if (_selectedAccount != null) {
        await accountProvider.updateBalance(_selectedAccount!.id, amount);
      }

      // Mettre à jour le streak
      await achievementProvider.updateStreak();

      // Vérifier les achievements
      await achievementProvider.checkExpenseAchievements(
        expenseProvider.expenses.length,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépense ajoutée !'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expenseProvider.error ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle dépense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Bouton scanner de ticket
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: 'Scanner un ticket',
              onPressed: () => context.push(AppRoutes.scanReceipt),
            ),
          ),
        ],
      ),
      body: Consumer2<CategoryProvider, AccountProvider>(
        builder: (context, categoryProvider, accountProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Montant
                Text(
                  'Montant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[,.]?\d{0,2}'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0,00',
                          ),
                          autofocus: true,
                        ),
                      ),
                      const Text(
                        '€',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Montants rapides
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Wrap(
                      spacing: 8,
                      children: [5, 10, 20, 50, 100].map((amount) {
                        return ActionChip(
                          label: Text(
                            '$amount €',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.glassBorder
                                : AppColors.divider,
                          ),
                          onPressed: () {
                            _amountController.text = amount.toString();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Catégorie
                Text(
                  'Catégorie',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryProvider.activeCategories.length,
                    itemBuilder: (context, index) {
                      final category = categoryProvider.activeCategories[index];
                      final isSelected = _selectedCategory?.id == category.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? null : category;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? category.colorValue.withOpacity(0.2)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: category.colorValue,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.iconData,
                                color: category.colorValue,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Compte
                if (accountProvider.hasAccounts) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Compte',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.accounts),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Gérer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: accountProvider.accounts.length,
                      itemBuilder: (context, index) {
                        final account = accountProvider.accounts[index];
                        final isSelected = _selectedAccount?.id == account.id;
                        final isDark = Theme.of(context).brightness == Brightness.dark;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAccount = account;
                            });
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(account.color).withOpacity(0.2)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(account.color),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      account.type.emoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        account.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyService.format(account.currentBalance),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: account.currentBalance >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Date
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                              .format(_selectedDate),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Note
                Text(
                  'Note (optionnel)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Ex: Déjeuner avec collègues',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton sauvegarder
                CustomButton(
                  text: 'Ajouter la dépense',
                  onPressed: _saveExpense,
                  isLoading: _isLoading,
                  width: double.infinity,
                  icon: Icons.add,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
