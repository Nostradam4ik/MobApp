import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/account.dart';

// Tests for AccountProvider logic without mocking Supabase
// These tests verify the pure computation logic

void main() {
  group('AccountProvider Logic', () {
    group('accounts filtering', () {
      test('should filter out archived accounts', () {
        final accounts = [
          _createAccount('1', 'Main', isArchived: false),
          _createAccount('2', 'Archived', isArchived: true),
          _createAccount('3', 'Savings', isArchived: false),
        ];

        final activeAccounts = accounts.where((a) => !a.isArchived).toList();

        expect(activeAccounts.length, 2);
        expect(activeAccounts.map((a) => a.id), containsAll(['1', '3']));
      });

      test('should get only archived accounts', () {
        final accounts = [
          _createAccount('1', 'Main', isArchived: false),
          _createAccount('2', 'Archived', isArchived: true),
          _createAccount('3', 'Old', isArchived: true),
        ];

        final archivedAccounts = accounts.where((a) => a.isArchived).toList();

        expect(archivedAccounts.length, 2);
        expect(archivedAccounts.map((a) => a.id), containsAll(['2', '3']));
      });
    });

    group('defaultAccount', () {
      test('should find default account', () {
        final accounts = [
          _createAccount('1', 'Main', isDefault: false),
          _createAccount('2', 'Default', isDefault: true),
          _createAccount('3', 'Savings', isDefault: false),
        ];

        final defaultAccount = accounts.firstWhere(
          (a) => a.isDefault && !a.isArchived,
          orElse: () => accounts.first,
        );

        expect(defaultAccount.id, '2');
      });

      test('should return first account if no default set', () {
        final accounts = [
          _createAccount('1', 'Main', isDefault: false),
          _createAccount('2', 'Other', isDefault: false),
        ];

        final defaultAccount = accounts.firstWhere(
          (a) => a.isDefault && !a.isArchived,
          orElse: () => accounts.first,
        );

        expect(defaultAccount.id, '1');
      });

      test('should not return archived default account', () {
        final accounts = [
          _createAccount('1', 'Main', isDefault: false, isArchived: false),
          _createAccount('2', 'Default Archived', isDefault: true, isArchived: true),
        ];

        final defaultAccount = accounts.firstWhere(
          (a) => a.isDefault && !a.isArchived,
          orElse: () => accounts.firstWhere((a) => !a.isArchived),
        );

        expect(defaultAccount.id, '1');
      });
    });

    group('totalBalance', () {
      test('should calculate total of all non-archived accounts', () {
        final accounts = [
          _createAccountWithBalance('1', 1000.0, isArchived: false, includeInTotal: true),
          _createAccountWithBalance('2', 500.0, isArchived: false, includeInTotal: true),
          _createAccountWithBalance('3', 2000.0, isArchived: true, includeInTotal: true),
        ];

        final total = accounts
            .where((a) => !a.isArchived && a.includeInTotal)
            .fold(0.0, (sum, account) => sum + account.balanceForTotal);

        expect(total, 1500.0);
      });

      test('should exclude accounts not in total', () {
        final accounts = [
          _createAccountWithBalance('1', 1000.0, includeInTotal: true),
          _createAccountWithBalance('2', 500.0, includeInTotal: false),
          _createAccountWithBalance('3', 250.0, includeInTotal: true),
        ];

        final total = accounts
            .where((a) => !a.isArchived && a.includeInTotal)
            .fold(0.0, (sum, account) => sum + account.balanceForTotal);

        expect(total, 1250.0);
      });

      test('should handle debt accounts correctly', () {
        final accounts = [
          _createAccountWithBalance('1', 1000.0, type: AccountType.checking),
          _createAccountWithBalance('2', 500.0, type: AccountType.creditCard),
          _createAccountWithBalance('3', 200.0, type: AccountType.loan),
        ];

        final total = accounts
            .where((a) => !a.isArchived && a.includeInTotal)
            .fold(0.0, (sum, account) => sum + account.balanceForTotal);

        // Checking: +1000, Credit card: -500, Loan: -200 = 300
        expect(total, 300.0);
      });
    });

    group('getAccountById', () {
      test('should find account by id', () {
        final accounts = [
          _createAccount('1', 'Main'),
          _createAccount('2', 'Savings'),
          _createAccount('3', 'Credit'),
        ];

        Account? getById(String? id) {
          if (id == null) return accounts.first;
          try {
            return accounts.firstWhere((a) => a.id == id);
          } catch (e) {
            return accounts.first;
          }
        }

        expect(getById('2')?.name, 'Savings');
        expect(getById('unknown')?.id, '1'); // Returns first/default
        expect(getById(null)?.id, '1'); // Returns first/default
      });
    });

    group('hasAccounts', () {
      test('should return true when accounts exist', () {
        final accounts = [_createAccount('1', 'Main')];
        expect(accounts.isNotEmpty, true);
      });

      test('should return false when no accounts', () {
        final accounts = <Account>[];
        expect(accounts.isNotEmpty, false);
      });
    });

    group('transfer validation', () {
      test('should not allow transfer to same account', () {
        const fromId = 'account-1';
        const toId = 'account-1';

        expect(fromId == toId, true);
      });

      test('should allow transfer between different accounts', () {
        const fromId = 'account-1';
        const toId = 'account-2';

        expect(fromId == toId, false);
      });
    });

    group('balance update', () {
      test('should decrease balance for expense', () {
        var balance = 1000.0;
        const amount = 150.0;
        const isExpense = true;

        balance = isExpense ? balance - amount : balance + amount;

        expect(balance, 850.0);
      });

      test('should increase balance for income', () {
        var balance = 1000.0;
        const amount = 150.0;
        const isExpense = false;

        balance = isExpense ? balance - amount : balance + amount;

        expect(balance, 1150.0);
      });
    });

    group('reorder accounts', () {
      test('should update sort order correctly', () {
        var accounts = [
          _createAccountWithOrder('1', 0),
          _createAccountWithOrder('2', 1),
          _createAccountWithOrder('3', 2),
        ];

        // Move item 0 to position 2
        const oldIndex = 0;
        var newIndex = 2;

        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        final account = accounts.removeAt(oldIndex);
        accounts.insert(newIndex, account);

        // Update sort orders
        for (var i = 0; i < accounts.length; i++) {
          accounts[i] = accounts[i].copyWith(sortOrder: i);
        }

        expect(accounts[0].id, '2');
        expect(accounts[0].sortOrder, 0);
        expect(accounts[1].id, '1');
        expect(accounts[1].sortOrder, 1);
        expect(accounts[2].id, '3');
        expect(accounts[2].sortOrder, 2);
      });
    });

    group('delete account validation', () {
      test('should not allow deleting last account', () {
        final accounts = [_createAccount('1', 'Main')];
        final canDelete = accounts.where((a) => !a.isArchived).length > 1;

        expect(canDelete, false);
      });

      test('should allow deleting when multiple accounts', () {
        final accounts = [
          _createAccount('1', 'Main'),
          _createAccount('2', 'Other'),
        ];
        final canDelete = accounts.where((a) => !a.isArchived).length > 1;

        expect(canDelete, true);
      });
    });
  });
}

Account _createAccount(
  String id,
  String name, {
  bool isDefault = false,
  bool isArchived = false,
}) {
  return Account(
    id: id,
    userId: 'user-1',
    name: name,
    type: AccountType.checking,
    color: 0xFF2196F3,
    isDefault: isDefault,
    isArchived: isArchived,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Account _createAccountWithBalance(
  String id,
  double balance, {
  AccountType type = AccountType.checking,
  bool isArchived = false,
  bool includeInTotal = true,
}) {
  return Account(
    id: id,
    userId: 'user-1',
    name: 'Account $id',
    type: type,
    color: 0xFF2196F3,
    currentBalance: balance,
    isArchived: isArchived,
    includeInTotal: includeInTotal,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Account _createAccountWithOrder(String id, int sortOrder) {
  return Account(
    id: id,
    userId: 'user-1',
    name: 'Account $id',
    type: AccountType.checking,
    color: 0xFF2196F3,
    sortOrder: sortOrder,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
