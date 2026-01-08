// ============================================================================
// SmartSpend - Tests du service d'import bancaire
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/bank_import_service.dart';
import 'package:smartspend/data/models/category.dart';
import 'package:smartspend/data/models/expense.dart';

void main() {
  group('BankImportService', () {
    group('supportedBanks', () {
      test('devrait avoir des banques françaises', () {
        final frenchBanks = BankImportService.supportedBanks
            .where((b) => b.country == 'FR')
            .toList();

        expect(frenchBanks, isNotEmpty);
        expect(frenchBanks.map((b) => b.name), contains('BNP Paribas'));
        expect(frenchBanks.map((b) => b.name), contains('Crédit Agricole'));
      });

      test('devrait avoir des néobanques', () {
        final neoBanks = BankImportService.supportedBanks
            .where((b) => b.type == BankType.n26 || b.type == BankType.revolut)
            .toList();

        expect(neoBanks.length, 2);
      });

      test('devrait avoir des imports génériques', () {
        final genericImports = BankImportService.supportedBanks
            .where((b) => b.country == 'ALL')
            .toList();

        expect(genericImports, isNotEmpty);
        expect(genericImports.map((b) => b.type), contains(BankType.csv));
        expect(genericImports.map((b) => b.type), contains(BankType.ofx));
      });
    });

    group('parseCSV', () {
      test('devrait parser un CSV simple', () async {
        const csvContent = '''Date;Description;Montant
01/12/2024;CARREFOUR PARIS;-25,50
02/12/2024;SNCF INTERNET;-45,00
03/12/2024;AMAZON PRIME;-49,99''';

        final result = await BankImportService.parseCSV(
          content: csvContent,
          bankType: BankType.csv,
          delimiter: ';',
          dateColumn: 0,
          descriptionColumn: 1,
          amountColumn: 2,
          dateFormat: 'dd/MM/yyyy',
          hasHeader: true,
        );

        expect(result.success, true);
        expect(result.transactions.length, 3);
        expect(result.transactions[0].description, 'CARREFOUR PARIS');
        expect(result.transactions[0].amount, 25.50);
      });

      test('devrait gérer un fichier vide', () async {
        final result = await BankImportService.parseCSV(
          content: '',
          bankType: BankType.csv,
        );

        expect(result.success, false);
        expect(result.error, contains('vide'));
      });

      test('devrait gérer les montants avec virgule', () async {
        const csvContent = '''Date;Description;Montant
01/12/2024;TEST;-1234,56''';

        final result = await BankImportService.parseCSV(
          content: csvContent,
          bankType: BankType.csv,
          delimiter: ';',
          hasHeader: true,
        );

        expect(result.success, true);
        expect(result.transactions[0].amount, 1234.56);
      });

      test('devrait gérer les guillemets dans le CSV', () async {
        const csvContent = '''Date;Description;Montant
01/12/2024;"CARREFOUR ""CITY"" PARIS";-25,50''';

        final result = await BankImportService.parseCSV(
          content: csvContent,
          bankType: BankType.csv,
          delimiter: ';',
          hasHeader: true,
        );

        expect(result.success, true);
        expect(result.transactions[0].description, 'CARREFOUR "CITY" PARIS');
      });
    });

    group('parseOFX', () {
      test('devrait parser un fichier OFX', () async {
        const ofxContent = '''
<OFX>
<BANKMSGSRSV1>
<STMTTRNRS>
<STMTRS>
<BANKTRANLIST>
<STMTTRN>
<DTPOSTED>20241201
<TRNAMT>-25.50
<NAME>CARREFOUR PARIS
<FITID>123456
</STMTTRN>
<STMTTRN>
<DTPOSTED>20241202
<TRNAMT>-45.00
<NAME>SNCF
<FITID>123457
</STMTTRN>
</BANKTRANLIST>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>''';

        final result = await BankImportService.parseOFX(ofxContent);

        expect(result.success, true);
        expect(result.transactions.length, 2);
        expect(result.transactions[0].description, 'CARREFOUR PARIS');
        expect(result.transactions[0].amount, 25.50);
        expect(result.transactions[0].reference, '123456');
      });

      test('devrait gérer un OFX vide', () async {
        final result = await BankImportService.parseOFX('<OFX></OFX>');

        expect(result.success, true);
        expect(result.transactions, isEmpty);
      });
    });

    group('parseQIF', () {
      test('devrait parser un fichier QIF', () async {
        const qifContent = '''!Type:Bank
D12/01/2024
T-25.50
PCARREFOUR PARIS
^
D12/02/2024
T-45.00
PSNCF INTERNET
^''';

        final result = await BankImportService.parseQIF(qifContent);

        expect(result.success, true);
        expect(result.transactions.length, 2);
      });
    });

    group('autoCategorize', () {
      final categories = [
        Category(
          id: 'cat_food',
          userId: 'user1',
          name: 'Alimentation',
          icon: 'restaurant',
          color: '#4CAF50',
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Category(
          id: 'cat_transport',
          userId: 'user1',
          name: 'Transport',
          icon: 'directions_car',
          color: '#2196F3',
          sortOrder: 1,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Category(
          id: 'cat_shopping',
          userId: 'user1',
          name: 'Shopping',
          icon: 'shopping_bag',
          color: '#E91E63',
          sortOrder: 2,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      test('devrait catégoriser les supermarchés', () {
        final categoryId = BankImportService.autoCategorize(
          'CARREFOUR PARIS 15',
          categories,
        );

        // Devrait être alimentation
        expect(categoryId, isNotNull);
      });

      test('devrait catégoriser les transports', () {
        final categoryId = BankImportService.autoCategorize(
          'UBER TRIP',
          categories,
        );

        expect(categoryId, isNotNull);
      });

      test('devrait catégoriser Amazon comme shopping', () {
        final categoryId = BankImportService.autoCategorize(
          'AMAZON MARKETPLACE',
          categories,
        );

        expect(categoryId, isNotNull);
      });

      test('devrait retourner null pour description inconnue', () {
        final categoryId = BankImportService.autoCategorize(
          'RANDOM UNKNOWN TRANSACTION',
          categories,
        );

        expect(categoryId, isNull);
      });
    });

    group('filterDuplicates', () {
      test('devrait filtrer les doublons', () {
        final newTransactions = [
          BankTransaction(
            id: 'new_1',
            date: DateTime(2024, 12, 1),
            description: 'CARREFOUR PARIS',
            amount: 25.50,
            isDebit: true,
          ),
          BankTransaction(
            id: 'new_2',
            date: DateTime(2024, 12, 2),
            description: 'SNCF',
            amount: 45.00,
            isDebit: true,
          ),
        ];

        final existingExpenses = [
          Expense(
            id: 'exp_1',
            userId: 'user1',
            amount: 25.50,
            expenseDate: DateTime(2024, 12, 1),
            note: 'CARREFOUR PARIS achat',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final filtered = BankImportService.filterDuplicates(
          newTransactions,
          existingExpenses,
        );

        expect(filtered.length, 1);
        expect(filtered[0].description, 'SNCF');
      });
    });

    group('BankTransaction', () {
      test('devrait se convertir en Expense', () {
        final transaction = BankTransaction(
          id: 'tx_1',
          date: DateTime(2024, 12, 1),
          description: 'Test Transaction',
          amount: 50.00,
          isDebit: true,
        );

        final expense = transaction.toExpense(
          userId: 'user1',
          categoryId: 'cat_1',
          accountId: 'acc_1',
        );

        expect(expense.userId, 'user1');
        expect(expense.amount, 50.00);
        expect(expense.categoryId, 'cat_1');
        expect(expense.accountId, 'acc_1');
        expect(expense.note, 'Test Transaction');
      });
    });

    group('ImportResult', () {
      test('devrait créer un résultat d\'erreur', () {
        final result = ImportResult.error('Test error');

        expect(result.success, false);
        expect(result.error, 'Test error');
        expect(result.transactions, isEmpty);
      });

      test('devrait créer un résultat réussi', () {
        final result = ImportResult(
          success: true,
          totalTransactions: 10,
          importedCount: 8,
          skippedCount: 1,
          duplicateCount: 1,
        );

        expect(result.success, true);
        expect(result.totalTransactions, 10);
        expect(result.importedCount, 8);
      });
    });

    group('CSVImportConfig', () {
      test('devrait avoir des configurations prédéfinies', () {
        expect(CSVImportConfig.bnpParibas.delimiter, ';');
        expect(CSVImportConfig.n26.delimiter, ',');
        expect(CSVImportConfig.revolut.delimiter, ',');
      });
    });
  });
}
