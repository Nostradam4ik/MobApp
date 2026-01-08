import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';

/// Écran de formulaire de budget
class BudgetFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBudget;

  const BudgetFormScreen({super.key, this.existingBudget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _limitController = TextEditingController();
  String? _selectedCategoryId;
  int _alertThreshold = 80;
  bool _isLoading = false;
  bool _isGlobal = true;

  bool get isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _limitController.text =
          widget.existingBudget!['monthly_limit'].toString();
      _selectedCategoryId = widget.existingBudget!['category_id'];
      _alertThreshold = widget.existingBudget!['alert_threshold'] ?? 80;
      _isGlobal = _selectedCategoryId == null;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limitText = _limitController.text.replaceAll(',', '.');
    final limit = double.tryParse(limitText);

    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<BudgetProvider>();
    bool success;

    if (isEditing) {
      final budget = Budget.fromJson(widget.existingBudget!);
      success = await provider.updateBudget(
        budget.copyWith(
          monthlyLimit: limit,
          categoryId: _isGlobal ? null : _selectedCategoryId,
          alertThreshold: _alertThreshold,
        ),
      );
    } else {
      success = await provider.createBudget(
        monthlyLimit: limit,
        categoryId: _isGlobal ? null : _selectedCategoryId,
        alertThreshold: _alertThreshold,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le budget' : 'Nouveau budget'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteBudget,
            ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type de budget
                Text(
                  'Type de budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeOption(
                        label: 'Global',
                        icon: Icons.account_balance_wallet,
                        isSelected: _isGlobal,
                        onTap: () => setState(() => _isGlobal = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeOption(
                        label: 'Par catégorie',
                        icon: Icons.category,
                        isSelected: !_isGlobal,
                        onTap: () => setState(() => _isGlobal = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sélection catégorie
                if (!_isGlobal) ...[
                  Text(
                    'Catégorie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text('Sélectionnez une catégorie'),
                    items: categoryProvider.activeCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.iconData, color: cat.colorValue, size: 20),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Montant limite
                Text(
                  'Limite mensuelle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _limitController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '500,00',
                    suffixText: '€',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Seuil d'alerte
                Text(
                  'Alerte à $_alertThreshold%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _alertThreshold.toDouble(),
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '$_alertThreshold%',
                  onChanged: (value) {
                    setState(() => _alertThreshold = value.toInt());
                  },
                ),
                Text(
                  'Vous recevrez une notification quand $_alertThreshold% du budget sera utilisé',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),

                // Bouton sauvegarder
                CustomButton(
                  text: isEditing ? 'Enregistrer' : 'Créer le budget',
                  onPressed: _save,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<BudgetProvider>();
      final success =
          await provider.deleteBudget(widget.existingBudget!['id']);
      if (success && mounted) {
        context.pop();
      }
    }
  }
}
