// ============================================================================
// SmartSpend - Écran d'import bancaire
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/bank_import_service.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';

/// Écran d'import bancaire
class BankImportScreen extends StatefulWidget {
  const BankImportScreen({super.key});

  @override
  State<BankImportScreen> createState() => _BankImportScreenState();
}

class _BankImportScreenState extends State<BankImportScreen> {
  BankType? _selectedBank;
  ImportResult? _importResult;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import bancaire'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: [
          Step(
            title: const Text('Choisir la banque'),
            content: _buildBankSelection(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Importer le fichier'),
            content: _buildFileImport(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Vérifier les transactions'),
            content: _buildTransactionReview(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Terminé'),
            content: _buildCompletion(),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection() {
    final banks = BankImportService.supportedBanks;
    final frenchBanks = banks.where((b) => b.country == 'FR').toList();
    final neoBanks = banks.where((b) => b.type == BankType.n26 || b.type == BankType.revolut).toList();
    final genericImport = banks.where((b) => b.country == 'ALL').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez votre banque pour un import optimisé',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Banques françaises
        Text(
          'Banques françaises',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: frenchBanks.map((bank) => _buildBankChip(bank)).toList(),
        ),

        const SizedBox(height: 16),

        // Néobanques
        Text(
          'Néobanques',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: neoBanks.map((bank) => _buildBankChip(bank)).toList(),
        ),

        const SizedBox(height: 16),

        // Import générique
        Text(
          'Import de fichier',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genericImport.map((bank) => _buildBankChip(bank)).toList(),
        ),
      ],
    );
  }

  Widget _buildBankChip(BankInfo bank) {
    final isSelected = _selectedBank == bank.type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(bank.logo, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(bank.name),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedBank = selected ? bank.type : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
    );
  }

  Widget _buildFileImport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importez votre relevé bancaire',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Comment exporter depuis votre banque',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('1. Connectez-vous à votre espace bancaire'),
              const Text('2. Accédez à "Historique" ou "Relevés"'),
              const Text('3. Sélectionnez "Exporter" en CSV ou OFX'),
              const Text('4. Téléchargez le fichier sur votre appareil'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bouton d'import
        Center(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isLoading ? 'Analyse en cours...' : 'Sélectionner un fichier'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),

        if (_importResult != null && !_importResult!.success) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importResult!.error ?? 'Erreur lors de l\'import',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionReview() {
    if (_importResult == null || _importResult!.transactions.isEmpty) {
      return const Center(
        child: Text('Aucune transaction à importer'),
      );
    }

    final categories = context.read<CategoryProvider>().activeCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total', _importResult!.totalTransactions.toString()),
                  _buildStat('À importer', _importResult!.transactions.length.toString()),
                  _buildStat('Ignorées', _importResult!.skippedCount.toString()),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Transactions à importer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Liste des transactions
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _importResult!.transactions.length,
            itemBuilder: (context, index) {
              final transaction = _importResult!.transactions[index];

              // Auto-catégorisation
              final suggestedCategoryId = BankImportService.autoCategorizе(
                transaction.description,
                categories,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction.isDebit
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    child: Icon(
                      transaction.isDebit ? Icons.remove : Icons.add,
                      color: transaction.isDebit ? AppColors.error : AppColors.success,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                  ),
                  trailing: Text(
                    '${transaction.isDebit ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction.isDebit ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Import terminé !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_importResult?.importedCount ?? 0} transactions importées',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    // Dans une vraie implémentation, utiliser file_picker
    // Pour l'instant, simuler un import

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    // Simuler des transactions
    final mockTransactions = List.generate(15, (i) {
      return BankTransaction(
        id: 'mock_$i',
        date: DateTime.now().subtract(Duration(days: i)),
        description: [
          'CARREFOUR PARIS',
          'SNCF INTERNET',
          'AMAZON PRIME',
          'UBER EATS',
          'SPOTIFY',
        ][i % 5],
        amount: (15.0 + i * 5.0) + (i * 0.99),
        isDebit: true,
      );
    });

    setState(() {
      _isLoading = false;
      _importResult = ImportResult(
        success: true,
        totalTransactions: mockTransactions.length,
        importedCount: mockTransactions.length,
        transactions: mockTransactions,
      );
    });
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une banque')),
      );
      return;
    }

    if (_currentStep == 1 && (_importResult == null || !_importResult!.success)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez importer un fichier')),
      );
      return;
    }

    if (_currentStep == 2) {
      // Importer les transactions
      _importTransactions();
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _importTransactions() async {
    if (_importResult == null) return;

    final expenseProvider = context.read<ExpenseProvider>();
    final categories = context.read<CategoryProvider>().activeCategories;

    for (final transaction in _importResult!.transactions) {
      if (transaction.isDebit) {
        final categoryId = BankImportService.autoCategorizе(
          transaction.description,
          categories,
        );

        await expenseProvider.createExpense(
          amount: transaction.amount,
          categoryId: categoryId,
          date: transaction.date,
          note: transaction.description,
        );
      }
    }
  }
}
