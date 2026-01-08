import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/account.dart';

void main() {
  group('AccountType', () {
    test('should have correct values for all types', () {
      expect(AccountType.cash.value, 'cash');
      expect(AccountType.checking.value, 'checking');
      expect(AccountType.savings.value, 'savings');
      expect(AccountType.creditCard.value, 'credit_card');
      expect(AccountType.investment.value, 'investment');
      expect(AccountType.loan.value, 'loan');
      expect(AccountType.wallet.value, 'wallet');
      expect(AccountType.other.value, 'other');
    });

    test('should have labels for all types', () {
      expect(AccountType.cash.label, 'Espèces');
      expect(AccountType.checking.label, 'Compte courant');
      expect(AccountType.savings.label, 'Épargne');
      expect(AccountType.creditCard.label, 'Carte de crédit');
    });

    test('should have emojis for all types', () {
      expect(AccountType.cash.emoji, isNotEmpty);
      expect(AccountType.checking.emoji, isNotEmpty);
      expect(AccountType.savings.emoji, isNotEmpty);
      expect(AccountType.creditCard.emoji, isNotEmpty);
    });

    test('fromString should return correct type', () {
      expect(AccountType.fromString('cash'), AccountType.cash);
      expect(AccountType.fromString('checking'), AccountType.checking);
      expect(AccountType.fromString('savings'), AccountType.savings);
      expect(AccountType.fromString('credit_card'), AccountType.creditCard);
      expect(AccountType.fromString('investment'), AccountType.investment);
      expect(AccountType.fromString('loan'), AccountType.loan);
      expect(AccountType.fromString('wallet'), AccountType.wallet);
    });

    test('fromString should return other for unknown value', () {
      expect(AccountType.fromString('unknown'), AccountType.other);
      expect(AccountType.fromString(''), AccountType.other);
      expect(AccountType.fromString('invalid'), AccountType.other);
    });
  });

  group('Account', () {
    final now = DateTime.now();
    final testAccount = Account(
      id: 'acc-123',
      userId: 'user-456',
      name: 'Compte Principal',
      type: AccountType.checking,
      initialBalance: 1000.0,
      currentBalance: 1500.0,
      currency: 'EUR',
      color: 0xFF2196F3,
      bankName: 'BNP Paribas',
      accountNumber: '1234',
      isDefault: true,
      isArchived: false,
      includeInTotal: true,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create Account from valid JSON', () {
        final json = {
          'id': 'acc-123',
          'user_id': 'user-456',
          'name': 'Compte Test',
          'type': 'checking',
          'initial_balance': 1000.0,
          'current_balance': 1500.0,
          'currency': 'EUR',
          'color': 0xFF2196F3,
          'bank_name': 'BNP',
          'account_number': '5678',
          'is_default': true,
          'is_archived': false,
          'include_in_total': true,
          'sort_order': 0,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final account = Account.fromJson(json);

        expect(account.id, 'acc-123');
        expect(account.userId, 'user-456');
        expect(account.name, 'Compte Test');
        expect(account.type, AccountType.checking);
        expect(account.initialBalance, 1000.0);
        expect(account.currentBalance, 1500.0);
        expect(account.currency, 'EUR');
        expect(account.bankName, 'BNP');
        expect(account.isDefault, true);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'acc-123',
          'user_id': 'user-456',
          'name': 'Compte Test',
          'type': 'savings',
          'color': 0xFF4CAF50,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final account = Account.fromJson(json);

        expect(account.bankName, isNull);
        expect(account.accountNumber, isNull);
        expect(account.icon, isNull);
        expect(account.initialBalance, 0.0);
        expect(account.currentBalance, 0.0);
        expect(account.isDefault, false);
        expect(account.isArchived, false);
        expect(account.includeInTotal, true);
      });

      test('should handle negative color (signed int from PostgreSQL)', () {
        // PostgreSQL stores colors as signed int, so 0xFFF44336 becomes negative
        final signedColor = 0xFFF44336 - 0x100000000; // -769226
        final json = {
          'id': 'acc-123',
          'user_id': 'user-456',
          'name': 'Carte Credit',
          'type': 'credit_card',
          'color': signedColor,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final account = Account.fromJson(json);

        // Should convert back to unsigned Flutter color
        expect(account.color, 0xFFF44336);
      });

      test('should handle positive color values', () {
        final json = {
          'id': 'acc-123',
          'user_id': 'user-456',
          'name': 'Compte Test',
          'type': 'checking',
          'color': 0x7F2196F3, // Positive color (alpha < 0x80)
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final account = Account.fromJson(json);

        expect(account.color, 0x7F2196F3);
      });
    });

    group('toJson', () {
      test('should convert Account to JSON', () {
        final json = testAccount.toJson();

        expect(json['id'], 'acc-123');
        expect(json['user_id'], 'user-456');
        expect(json['name'], 'Compte Principal');
        expect(json['type'], 'checking');
        expect(json['initial_balance'], 1000.0);
        expect(json['current_balance'], 1500.0);
        expect(json['currency'], 'EUR');
        expect(json['bank_name'], 'BNP Paribas');
        expect(json['account_number'], '1234');
        expect(json['is_default'], true);
        expect(json['is_archived'], false);
        expect(json['include_in_total'], true);
        expect(json['sort_order'], 0);
      });

      test('should convert large color to signed int for PostgreSQL', () {
        final accountWithLargeColor = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.creditCard,
          color: 0xFFF44336, // Large unsigned color
          createdAt: now,
          updatedAt: now,
        );

        final json = accountWithLargeColor.toJson();

        // Should be converted to signed int for PostgreSQL
        expect(json['color'], lessThan(0));
        expect(json['color'], 0xFFF44336 - 0x100000000);
      });

      test('should keep small color as positive', () {
        final accountWithSmallColor = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          color: 0x7F2196F3, // Small color (alpha < 0x80)
          createdAt: now,
          updatedAt: now,
        );

        final json = accountWithSmallColor.toJson();

        expect(json['color'], greaterThanOrEqualTo(0));
        expect(json['color'], 0x7F2196F3);
      });

      test('should include timestamps in ISO format', () {
        final json = testAccount.toJson();

        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
        expect(json['created_at'], contains('T'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testAccount.copyWith(name: 'Nouveau Nom');

        expect(copy.name, 'Nouveau Nom');
        expect(copy.id, testAccount.id);
        expect(copy.userId, testAccount.userId);
        expect(copy.currentBalance, testAccount.currentBalance);
      });

      test('should create copy with updated balance', () {
        final copy = testAccount.copyWith(currentBalance: 2000.0);

        expect(copy.currentBalance, 2000.0);
        expect(copy.initialBalance, testAccount.initialBalance);
      });

      test('should create copy with multiple updates', () {
        final copy = testAccount.copyWith(
          name: 'Updated Name',
          currentBalance: 3000.0,
          isDefault: false,
          isArchived: true,
        );

        expect(copy.name, 'Updated Name');
        expect(copy.currentBalance, 3000.0);
        expect(copy.isDefault, false);
        expect(copy.isArchived, true);
        expect(copy.id, testAccount.id);
      });
    });

    group('displayName', () {
      test('should return name with bank name when available', () {
        expect(testAccount.displayName, 'Compte Principal (BNP Paribas)');
      });

      test('should return only name when no bank name', () {
        final accountWithoutBank = testAccount.copyWith(bankName: null);
        // Note: copyWith doesn't support setting to null, so we create a new account
        final account = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Compte Test',
          type: AccountType.checking,
          color: 0xFF2196F3,
          createdAt: now,
          updatedAt: now,
        );

        expect(account.displayName, 'Compte Test');
      });
    });

    group('maskedAccountNumber', () {
      test('should mask account number showing last 4 digits', () {
        expect(testAccount.maskedAccountNumber, '****1234');
      });

      test('should return **** for null account number', () {
        final account = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          color: 0xFF2196F3,
          createdAt: now,
          updatedAt: now,
        );

        expect(account.maskedAccountNumber, '****');
      });

      test('should return **** for short account number', () {
        final account = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          color: 0xFF2196F3,
          accountNumber: '12',
          createdAt: now,
          updatedAt: now,
        );

        expect(account.maskedAccountNumber, '****');
      });
    });

    group('isPositive', () {
      test('should return true for positive balance', () {
        expect(testAccount.isPositive, true);
      });

      test('should return true for zero balance', () {
        final account = testAccount.copyWith(currentBalance: 0.0);
        expect(account.isPositive, true);
      });

      test('should return false for negative balance', () {
        final account = testAccount.copyWith(currentBalance: -100.0);
        expect(account.isPositive, false);
      });
    });

    group('isDebt', () {
      test('should return true for credit card', () {
        final creditCard = testAccount.copyWith(type: AccountType.creditCard);
        expect(creditCard.isDebt, true);
      });

      test('should return true for loan', () {
        final loan = testAccount.copyWith(type: AccountType.loan);
        expect(loan.isDebt, true);
      });

      test('should return false for checking account', () {
        expect(testAccount.isDebt, false);
      });

      test('should return false for savings account', () {
        final savings = testAccount.copyWith(type: AccountType.savings);
        expect(savings.isDebt, false);
      });
    });

    group('balanceForTotal', () {
      test('should return positive balance for non-debt accounts', () {
        final account = testAccount.copyWith(currentBalance: 1000.0);
        expect(account.balanceForTotal, 1000.0);
      });

      test('should return negative balance for credit card', () {
        final creditCard = Account(
          id: 'cc-1',
          userId: 'user-1',
          name: 'Carte Credit',
          type: AccountType.creditCard,
          currentBalance: 500.0,
          color: 0xFFF44336,
          includeInTotal: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(creditCard.balanceForTotal, -500.0);
      });

      test('should return negative balance for loan', () {
        final loan = Account(
          id: 'loan-1',
          userId: 'user-1',
          name: 'Pret Immo',
          type: AccountType.loan,
          currentBalance: 10000.0,
          color: 0xFF795548,
          includeInTotal: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(loan.balanceForTotal, -10000.0);
      });

      test('should return 0 when not included in total', () {
        final account = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Compte Exclu',
          type: AccountType.checking,
          currentBalance: 5000.0,
          color: 0xFF2196F3,
          includeInTotal: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(account.balanceForTotal, 0.0);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final account1 = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          initialBalance: 100.0,
          currentBalance: 100.0,
          currency: 'EUR',
          color: 0xFF2196F3,
          isDefault: false,
          isArchived: false,
          includeInTotal: true,
          sortOrder: 0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final account2 = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          initialBalance: 100.0,
          currentBalance: 100.0,
          currency: 'EUR',
          color: 0xFF2196F3,
          isDefault: false,
          isArchived: false,
          includeInTotal: true,
          sortOrder: 0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(account1, equals(account2));
      });

      test('should not be equal for different ids', () {
        final account1 = Account(
          id: 'acc-1',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          color: 0xFF2196F3,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final account2 = Account(
          id: 'acc-2',
          userId: 'user-1',
          name: 'Test',
          type: AccountType.checking,
          color: 0xFF2196F3,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(account1, isNot(equals(account2)));
      });
    });
  });

  group('AccountStats', () {
    test('should create AccountStats with all fields', () {
      final stats = AccountStats(
        accountId: 'acc-1',
        totalIncome: 5000.0,
        totalExpenses: 3000.0,
        netFlow: 2000.0,
        transactionCount: 50,
        lastTransaction: DateTime(2024, 1, 15),
      );

      expect(stats.accountId, 'acc-1');
      expect(stats.totalIncome, 5000.0);
      expect(stats.totalExpenses, 3000.0);
      expect(stats.netFlow, 2000.0);
      expect(stats.transactionCount, 50);
      expect(stats.lastTransaction, DateTime(2024, 1, 15));
    });

    test('should allow null lastTransaction', () {
      final stats = AccountStats(
        accountId: 'acc-1',
        totalIncome: 0.0,
        totalExpenses: 0.0,
        netFlow: 0.0,
        transactionCount: 0,
      );

      expect(stats.lastTransaction, isNull);
    });
  });
}
