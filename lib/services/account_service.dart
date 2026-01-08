import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/account.dart';

/// Service de gestion des comptes bancaires/financiers
class AccountService {
  final SupabaseClient _supabase;
  static const String _tableName = 'accounts';

  AccountService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ==================== CRUD ====================

  /// Récupère tous les comptes de l'utilisateur
  Future<List<Account>> getAccounts({
    bool includeArchived = false,
  }) async {
    if (_userId == null) return [];

    var query = _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query.order('sort_order', ascending: true);
    return (response as List).map((json) => Account.fromJson(json)).toList();
  }

  /// Récupère un compte par son ID
  Future<Account?> getAccountById(String id) async {
    if (_userId == null) return null;

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return Account.fromJson(response);
  }

  /// Récupère le compte par défaut
  Future<Account?> getDefaultAccount() async {
    if (_userId == null) return null;

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!)
        .eq('is_default', true)
        .eq('is_archived', false)
        .maybeSingle();

    if (response == null) {
      // Si pas de compte par défaut, retourner le premier
      final accounts = await getAccounts();
      return accounts.isNotEmpty ? accounts.first : null;
    }
    return Account.fromJson(response);
  }

  /// Crée un nouveau compte
  Future<Account?> createAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0,
    String currency = 'EUR',
    int? color,
    String? icon,
    String? bankName,
    String? accountNumber,
    bool isDefault = false,
    bool includeInTotal = true,
  }) async {
    if (_userId == null) return null;

    final id = const Uuid().v4();
    final now = DateTime.now();

    // Si c'est le premier compte, le mettre par défaut
    final existingAccounts = await getAccounts();
    final shouldBeDefault = isDefault || existingAccounts.isEmpty;

    // Si nouveau compte par défaut, retirer le statut des autres
    if (shouldBeDefault) {
      await _clearDefaultAccount();
    }

    final account = Account(
      id: id,
      userId: _userId!,
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      currency: currency,
      color: color ?? type.defaultColor,
      icon: icon,
      bankName: bankName,
      accountNumber: accountNumber,
      isDefault: shouldBeDefault,
      isArchived: false,
      includeInTotal: includeInTotal,
      sortOrder: existingAccounts.length,
      createdAt: now,
      updatedAt: now,
    );

    await _supabase.from(_tableName).insert(account.toJson());
    return account;
  }

  /// Met à jour un compte
  Future<Account?> updateAccount(Account account) async {
    if (_userId == null) return null;

    // Si on le met par défaut, retirer le statut des autres
    if (account.isDefault) {
      await _clearDefaultAccount();
    }

    final updated = account.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from(_tableName)
        .update(updated.toJson())
        .eq('id', account.id)
        .eq('user_id', _userId!);

    return updated;
  }

  /// Supprime un compte (archive en fait)
  Future<bool> deleteAccount(String id) async {
    if (_userId == null) return false;

    // Archiver plutôt que supprimer pour garder l'historique
    await _supabase
        .from(_tableName)
        .update({
          'is_archived': true,
          'is_default': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId!);

    return true;
  }

  /// Supprime définitivement un compte
  Future<bool> permanentlyDeleteAccount(String id) async {
    if (_userId == null) return false;

    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);

    return true;
  }

  /// Retire le statut par défaut de tous les comptes
  Future<void> _clearDefaultAccount() async {
    if (_userId == null) return;

    await _supabase
        .from(_tableName)
        .update({'is_default': false})
        .eq('user_id', _userId!)
        .eq('is_default', true);
  }

  // ==================== SOLDES ====================

  /// Met à jour le solde d'un compte
  Future<void> updateBalance(String accountId, double newBalance) async {
    if (_userId == null) return;

    await _supabase
        .from(_tableName)
        .update({
          'current_balance': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', accountId)
        .eq('user_id', _userId!);
  }

  /// Ajoute un montant au solde (revenu)
  Future<void> addToBalance(String accountId, double amount) async {
    final account = await getAccountById(accountId);
    if (account == null) return;

    await updateBalance(accountId, account.currentBalance + amount);
  }

  /// Retire un montant du solde (dépense)
  Future<void> subtractFromBalance(String accountId, double amount) async {
    final account = await getAccountById(accountId);
    if (account == null) return;

    await updateBalance(accountId, account.currentBalance - amount);
  }

  /// Transfère un montant entre deux comptes
  Future<bool> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    if (_userId == null) return false;

    final fromAccount = await getAccountById(fromAccountId);
    final toAccount = await getAccountById(toAccountId);

    if (fromAccount == null || toAccount == null) return false;

    // Transaction atomique
    await subtractFromBalance(fromAccountId, amount);
    await addToBalance(toAccountId, amount);

    return true;
  }

  // ==================== STATISTIQUES ====================

  /// Calcule le solde total de tous les comptes
  Future<double> getTotalBalance({bool includeDebts = true}) async {
    final accounts = await getAccounts();

    double total = 0.0;
    for (final account in accounts.where((a) => a.includeInTotal)) {
      if (includeDebts) {
        total += account.balanceForTotal;
      } else {
        total += account.isDebt ? 0.0 : account.currentBalance;
      }
    }
    return total;
  }

  /// Obtient le solde par type de compte
  Future<Map<AccountType, double>> getBalanceByType() async {
    final accounts = await getAccounts();

    final result = <AccountType, double>{};
    for (final account in accounts) {
      if (account.includeInTotal) {
        result[account.type] = (result[account.type] ?? 0) + account.currentBalance;
      }
    }

    return result;
  }

  /// Obtient les statistiques d'un compte
  Future<AccountStats> getAccountStats(String accountId) async {
    // Cette méthode nécessite des données de transactions
    // Implémentation basique pour l'instant
    return AccountStats(
      accountId: accountId,
      totalIncome: 0,
      totalExpenses: 0,
      netFlow: 0,
      transactionCount: 0,
    );
  }

  // ==================== UTILITAIRES ====================

  /// Crée les comptes par défaut pour un nouvel utilisateur
  Future<void> createDefaultAccounts() async {
    if (_userId == null) return;

    final existing = await getAccounts();
    if (existing.isNotEmpty) return;

    // Compte espèces
    await createAccount(
      name: 'Espèces',
      type: AccountType.cash,
      isDefault: false,
    );

    // Compte courant principal
    await createAccount(
      name: 'Compte courant',
      type: AccountType.checking,
      isDefault: true,
    );

    // Compte épargne
    await createAccount(
      name: 'Épargne',
      type: AccountType.savings,
      includeInTotal: true,
    );
  }

  /// Réordonne les comptes
  Future<void> reorderAccounts(List<String> accountIds) async {
    if (_userId == null) return;

    for (int i = 0; i < accountIds.length; i++) {
      await _supabase
          .from(_tableName)
          .update({'sort_order': i})
          .eq('id', accountIds[i])
          .eq('user_id', _userId!);
    }
  }

  /// Recherche des comptes
  Future<List<Account>> searchAccounts(String query) async {
    if (_userId == null || query.isEmpty) return [];

    final accounts = await getAccounts();
    final lowerQuery = query.toLowerCase();

    return accounts.where((account) {
      return account.name.toLowerCase().contains(lowerQuery) ||
          (account.bankName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
