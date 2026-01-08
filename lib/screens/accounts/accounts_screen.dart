import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../services/currency_service.dart';

/// Écran de gestion des comptes
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes comptes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un compte',
            onPressed: () => context.push(AppRoutes.accountForm),
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = provider.accounts;
          final archivedAccounts = provider.archivedAccounts;

          return RefreshIndicator(
            onRefresh: () => provider.loadAccounts(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Solde total
                _buildTotalBalanceCard(context, provider, isDark),

                const SizedBox(height: 24),

                // Liste des comptes actifs
                if (accounts.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Comptes actifs', accounts.length),
                  const SizedBox(height: 12),
                  ...accounts.map((account) => _buildAccountCard(
                        context,
                        account,
                        provider,
                        isDark,
                      )),
                ],

                // Comptes archivés
                if (archivedAccounts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    'Comptes archivés',
                    archivedAccounts.length,
                  ),
                  const SizedBox(height: 12),
                  ...archivedAccounts.map((account) => _buildAccountCard(
                        context,
                        account,
                        provider,
                        isDark,
                        isArchived: true,
                      )),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransferDialog(context),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Transfert'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildTotalBalanceCard(
    BuildContext context,
    AccountProvider provider,
    bool isDark,
  ) {
    final total = provider.totalBalance;
    final isPositive = total >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
              : [Colors.red.shade700, Colors.red.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primary : Colors.red).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Solde total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyService.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.accounts.length} compte${provider.accounts.length > 1 ? 's' : ''} actif${provider.accounts.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    AccountProvider provider,
    bool isDark, {
    bool isArchived = false,
  }) {
    return Opacity(
      opacity: isArchived ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: account.isDefault
              ? BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(
            AppRoutes.accountForm,
            extra: account,
          ),
          onLongPress: () => _showAccountOptions(context, account, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône du compte
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(account.color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      account.type.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (account.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.type.label,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      if (account.bankName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          account.bankName!,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Solde
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyService.format(account.currentBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: account.currentBalance >= 0
                            ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                            : Colors.red,
                      ),
                    ),
                    if (!account.includeInTotal)
                      Text(
                        'Exclu du total',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
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

  void _showAccountOptions(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.accountForm, extra: account);
                },
              ),
              if (!account.isDefault && !account.isArchived)
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Définir comme principal'),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.updateAccount(
                      account.copyWith(isDefault: true),
                    );
                  },
                ),
              if (!account.isArchived)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Archiver'),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.archiveAccount(account.id);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.unarchive),
                  title: const Text('Désarchiver'),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.unarchiveAccount(account.id);
                  },
                ),
              if (provider.accounts.length > 1 || account.isArchived)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, account, provider);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Text(
          'Le compte "${account.name}" sera supprimé définitivement. '
          'Les dépenses associées seront conservées mais sans compte associé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteAccount(account.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    final provider = context.read<AccountProvider>();
    final accounts = provider.accounts;

    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez besoin d\'au moins 2 comptes pour faire un transfert'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? fromAccountId = accounts.first.id;
    String? toAccountId = accounts.length > 1 ? accounts[1].id : null;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transfert entre comptes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Compte source
                  const Text('De', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: fromAccountId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.type.emoji} ${account.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        fromAccountId = value;
                        if (toAccountId == value) {
                          toAccountId = accounts.firstWhere((a) => a.id != value).id;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Compte destination
                  const Text('Vers', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: toAccountId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: accounts
                        .where((a) => a.id != fromAccountId)
                        .map((account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.type.emoji} ${account.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => toAccountId = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Montant
                  const Text('Montant', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '0.00',
                      suffixText: '€',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text('Description (optionnel)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Ex: Virement épargne',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(
                          amountController.text.replaceAll(',', '.'),
                        );

                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Montant invalide'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (fromAccountId == null || toAccountId == null) {
                          return;
                        }

                        final success = await provider.transfer(
                          fromAccountId: fromAccountId!,
                          toAccountId: toAccountId!,
                          amount: amount,
                          description: descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Transfert effectué'
                                    : provider.error ?? 'Erreur',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Effectuer le transfert'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
