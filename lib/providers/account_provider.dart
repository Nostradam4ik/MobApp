import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/account.dart';

/// Provider pour gérer les comptes bancaires/financiers
class AccountProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<Account> _accounts = [];
  Account? _selectedAccount;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // Getters
  List<Account> get accounts => _accounts.where((a) => !a.isArchived).toList();
  List<Account> get allAccounts => _accounts;
  List<Account> get archivedAccounts => _accounts.where((a) => a.isArchived).toList();
  Account? get selectedAccount => _selectedAccount;
  Account? get defaultAccount => _accounts.firstWhere(
        (a) => a.isDefault && !a.isArchived,
        orElse: () => _accounts.isNotEmpty ? _accounts.first : _createDefaultAccount(),
      );
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAccounts => _accounts.isNotEmpty;

  /// Solde total de tous les comptes
  double get totalBalance {
    return _accounts
        .where((a) => !a.isArchived && a.includeInTotal)
        .fold(0.0, (sum, account) => sum + account.balanceForTotal);
  }

  /// Met à jour l'ID utilisateur et charge les comptes
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadAccounts();
      } else {
        _accounts = [];
        notifyListeners();
      }
    }
  }

  /// Charge les comptes depuis la base de données
  Future<void> loadAccounts() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', _userId!)
          .order('sort_order', ascending: true);

      _accounts = (response as List)
          .map((json) => Account.fromJson(json))
          .toList();

      // Si aucun compte, créer le compte par défaut
      if (_accounts.isEmpty) {
        await _createInitialAccount();
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des comptes: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Crée le compte initial par défaut
  Future<void> _createInitialAccount() async {
    if (_userId == null) return;

    final defaultAccount = Account(
      id: _uuid.v4(),
      userId: _userId!,
      name: 'Compte principal',
      type: AccountType.checking,
      initialBalance: 0,
      currentBalance: 0,
      currency: 'EUR',
      color: AccountType.checking.defaultColor,
      isDefault: true,
      includeInTotal: true,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _supabase.from('accounts').insert(defaultAccount.toJson());
      _accounts = [defaultAccount];
    } catch (e) {
      debugPrint('Erreur création compte initial: $e');
      // Ajouter localement même si l'insertion échoue
      _accounts = [defaultAccount];
    }
  }

  /// Crée un compte par défaut (pour le getter)
  Account _createDefaultAccount() {
    return Account(
      id: 'default',
      userId: _userId ?? '',
      name: 'Compte principal',
      type: AccountType.checking,
      color: AccountType.checking.defaultColor,
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Ajoute un nouveau compte
  Future<bool> addAccount(Account account) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAccount = account.copyWith(
        id: _uuid.v4(),
        userId: _userId,
        sortOrder: _accounts.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Si c'est le compte par défaut, retirer le flag des autres
      if (newAccount.isDefault) {
        await _removeDefaultFlag();
      }

      await _supabase.from('accounts').insert(newAccount.toJson());
      _accounts.add(newAccount);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du compte: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour un compte existant
  Future<bool> updateAccount(Account account) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAccount = account.copyWith(
        updatedAt: DateTime.now(),
      );

      // Si c'est le compte par défaut, retirer le flag des autres
      if (updatedAccount.isDefault) {
        await _removeDefaultFlag(exceptId: updatedAccount.id);
      }

      await _supabase
          .from('accounts')
          .update(updatedAccount.toJson())
          .eq('id', updatedAccount.id);

      final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime un compte
  Future<bool> deleteAccount(String accountId) async {
    // Ne pas supprimer le dernier compte
    if (_accounts.where((a) => !a.isArchived).length <= 1) {
      _error = 'Impossible de supprimer le dernier compte';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('accounts').delete().eq('id', accountId);
      _accounts.removeWhere((a) => a.id == accountId);

      // Si on a supprimé le compte par défaut, en définir un autre
      if (!_accounts.any((a) => a.isDefault && !a.isArchived)) {
        final first = _accounts.firstWhere((a) => !a.isArchived);
        await updateAccount(first.copyWith(isDefault: true));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Archive un compte
  Future<bool> archiveAccount(String accountId) async {
    final account = _accounts.firstWhere((a) => a.id == accountId);
    return updateAccount(account.copyWith(isArchived: true, isDefault: false));
  }

  /// Désarchive un compte
  Future<bool> unarchiveAccount(String accountId) async {
    final account = _accounts.firstWhere((a) => a.id == accountId);
    return updateAccount(account.copyWith(isArchived: false));
  }

  /// Met à jour le solde d'un compte
  Future<void> updateBalance(String accountId, double amount, {bool isExpense = true}) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return;

    final account = _accounts[index];
    final newBalance = isExpense
        ? account.currentBalance - amount
        : account.currentBalance + amount;

    final updatedAccount = account.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );

    try {
      await _supabase
          .from('accounts')
          .update({'current_balance': newBalance, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', accountId);

      _accounts[index] = updatedAccount;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur mise à jour solde: $e');
    }
  }

  /// Effectue un transfert entre deux comptes
  Future<bool> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
  }) async {
    if (fromAccountId == toAccountId) {
      _error = 'Impossible de transférer vers le même compte';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Débiter le compte source
      await updateBalance(fromAccountId, amount, isExpense: true);

      // Créditer le compte destination
      await updateBalance(toAccountId, amount, isExpense: false);

      // Enregistrer le transfert
      await _supabase.from('account_transfers').insert({
        'id': _uuid.v4(),
        'user_id': _userId,
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount,
        'description': description,
        'transfer_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors du transfert: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sélectionne un compte
  void selectAccount(Account? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  /// Récupère un compte par son ID
  Account? getAccountById(String? id) {
    if (id == null) return defaultAccount;
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return defaultAccount;
    }
  }

  /// Retire le flag isDefault de tous les comptes
  Future<void> _removeDefaultFlag({String? exceptId}) async {
    for (var i = 0; i < _accounts.length; i++) {
      if (_accounts[i].isDefault && _accounts[i].id != exceptId) {
        _accounts[i] = _accounts[i].copyWith(isDefault: false);
        await _supabase
            .from('accounts')
            .update({'is_default': false})
            .eq('id', _accounts[i].id);
      }
    }
  }

  /// Réordonne les comptes
  Future<void> reorderAccounts(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final account = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, account);

    // Mettre à jour les ordres
    for (var i = 0; i < _accounts.length; i++) {
      _accounts[i] = _accounts[i].copyWith(sortOrder: i);
      await _supabase
          .from('accounts')
          .update({'sort_order': i})
          .eq('id', _accounts[i].id);
    }

    notifyListeners();
  }
}
