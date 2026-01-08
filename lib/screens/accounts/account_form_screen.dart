import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../../providers/account_provider.dart';

/// Écran de création/modification de compte
class AccountFormScreen extends StatefulWidget {
  final Account? existingAccount;

  const AccountFormScreen({super.key, this.existingAccount});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();

  AccountType _selectedType = AccountType.checking;
  int _selectedColor = AccountType.checking.defaultColor;
  bool _isDefault = false;
  bool _includeInTotal = true;

  bool get isEditing => widget.existingAccount != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final account = widget.existingAccount!;
      _nameController.text = account.name;
      _bankNameController.text = account.bankName ?? '';
      _accountNumberController.text = account.accountNumber ?? '';
      _initialBalanceController.text = account.initialBalance.toString();
      _selectedType = account.type;
      _selectedColor = account.color;
      _isDefault = account.isDefault;
      _includeInTotal = account.includeInTotal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _initialBalanceController.dispose();
    _interestRateController.dispose();
    _creditLimitController.dispose();
    _loanAmountController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le compte' : 'Nouveau compte'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type de compte
            const Text(
              'Type de compte',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(isDark),

            const SizedBox(height: 24),

            // Nom du compte
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom du compte *',
                hintText: 'Ex: Compte courant BNP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Nom de la banque
            TextFormField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'Nom de la banque (optionnel)',
                hintText: 'Ex: BNP Paribas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance),
              ),
            ),

            const SizedBox(height: 16),

            // Numéro de compte
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Derniers chiffres du compte (optionnel)',
                hintText: 'Ex: 1234',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),

            const SizedBox(height: 16),

            // Champs spécifiques selon le type de compte
            ..._buildTypeSpecificFields(),

            const SizedBox(height: 24),

            // Couleur
            const Text(
              'Couleur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildColorSelector(),

            const SizedBox(height: 24),

            // Options
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Compte principal'),
              subtitle: const Text('Sélectionné par défaut pour les dépenses'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Inclure dans le solde total'),
              subtitle: const Text('Compter ce compte dans le patrimoine'),
              value: _includeInTotal,
              onChanged: (value) => setState(() => _includeInTotal = value),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEditing ? 'Enregistrer' : 'Créer le compte'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AccountType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
              _selectedColor = type.defaultColor;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(type.defaultColor).withOpacity(0.15)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Color(type.defaultColor)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Color(type.defaultColor) : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    final widgets = <Widget>[];

    // Solde initial / actuel (pour tous les types sauf prêt et carte de crédit)
    if (_selectedType != AccountType.loan && _selectedType != AccountType.creditCard) {
      widgets.add(
        TextFormField(
          controller: _initialBalanceController,
          decoration: InputDecoration(
            labelText: _selectedType == AccountType.investment
                ? 'Valeur du portefeuille'
                : 'Solde actuel',
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.euro),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Champs spécifiques pour Épargne
    if (_selectedType == AccountType.savings) {
      widgets.add(
        TextFormField(
          controller: _interestRateController,
          decoration: InputDecoration(
            labelText: 'Taux d\'intérêt (optionnel)',
            hintText: '3.0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.percent),
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Champs spécifiques pour Carte de crédit
    if (_selectedType == AccountType.creditCard) {
      widgets.add(
        TextFormField(
          controller: _creditLimitController,
          decoration: InputDecoration(
            labelText: 'Plafond de la carte',
            hintText: '1000.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.credit_score),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        TextFormField(
          controller: _initialBalanceController,
          decoration: InputDecoration(
            labelText: 'Encours actuel (dette)',
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.money_off),
            suffixText: '€',
            helperText: 'Montant actuellement dû sur la carte',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Champs spécifiques pour Prêt
    if (_selectedType == AccountType.loan) {
      widgets.add(
        TextFormField(
          controller: _loanAmountController,
          decoration: InputDecoration(
            labelText: 'Montant emprunté',
            hintText: '10000.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.account_balance),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        TextFormField(
          controller: _initialBalanceController,
          decoration: InputDecoration(
            labelText: 'Capital restant dû',
            hintText: '8000.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.money_off),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        TextFormField(
          controller: _monthlyPaymentController,
          decoration: InputDecoration(
            labelText: 'Mensualité (optionnel)',
            hintText: '200.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.event_repeat),
            suffixText: '€/mois',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        TextFormField(
          controller: _interestRateController,
          decoration: InputDecoration(
            labelText: 'Taux d\'intérêt (optionnel)',
            hintText: '2.5',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.percent),
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Champs spécifiques pour Investissement
    if (_selectedType == AccountType.investment) {
      widgets.add(
        TextFormField(
          controller: _interestRateController,
          decoration: InputDecoration(
            labelText: 'Performance annuelle (optionnel)',
            hintText: '5.0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.trending_up),
            suffixText: '%',
            helperText: 'Rendement moyen attendu',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildColorSelector() {
    final colors = [
      0xFF2196F3, // Bleu
      0xFF4CAF50, // Vert
      0xFFFF9800, // Orange
      0xFFF44336, // Rouge
      0xFF9C27B0, // Violet
      0xFF00BCD4, // Cyan
      0xFFE91E63, // Rose
      0xFF795548, // Marron
      0xFF607D8B, // Gris-bleu
      0xFF3F51B5, // Indigo
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(color).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AccountProvider>();
    final initialBalance = double.tryParse(
          _initialBalanceController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    // Calculer le currentBalance
    double currentBalance;
    if (isEditing) {
      // En mode édition, ajuster le currentBalance selon la différence du solde initial
      final oldInitialBalance = widget.existingAccount!.initialBalance;
      final difference = initialBalance - oldInitialBalance;
      currentBalance = widget.existingAccount!.currentBalance + difference;
    } else {
      // En création, currentBalance = initialBalance
      currentBalance = initialBalance;
    }

    final account = Account(
      id: widget.existingAccount?.id ?? '',
      userId: widget.existingAccount?.userId ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      currency: 'EUR',
      color: _selectedColor,
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim().isEmpty
          ? null
          : _accountNumberController.text.trim(),
      isDefault: _isDefault,
      includeInTotal: _includeInTotal,
      sortOrder: widget.existingAccount?.sortOrder ?? 0,
      createdAt: widget.existingAccount?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await provider.updateAccount(account);
    } else {
      success = await provider.addAccount(account);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Compte modifié' : 'Compte créé',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
