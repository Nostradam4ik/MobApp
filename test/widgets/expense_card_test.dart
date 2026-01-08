// ============================================================================
// SmartSpend - Widget Tests: ExpenseCard
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartspend/data/models/expense.dart';
import 'package:smartspend/data/models/category.dart';
import 'package:smartspend/widgets/expense/expense_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('ExpenseCard Widget', () {
    final testCategory = Category(
      id: 'cat1',
      userId: 'user1',
      name: 'Alimentation',
      icon: 'restaurant',
      color: '#4CAF50',
      sortOrder: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testExpense = Expense(
      id: 'exp1',
      userId: 'user1',
      amount: 25.50,
      categoryId: 'cat1',
      expenseDate: DateTime.now(),
      note: 'Déjeuner',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: testCategory,
    );

    testWidgets('affiche le montant correctement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: testExpense,
              onTap: () {},
            ),
          ),
        ),
      );

      // Le montant devrait être affiché
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('affiche le nom de la catégorie', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: testExpense,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Alimentation'), findsOneWidget);
    });

    testWidgets('affiche la note si présente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: testExpense,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Déjeuner'), findsOneWidget);
    });

    testWidgets('appelle onTap quand tapé', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: testExpense,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExpenseCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('affiche sans note quand note est null', (tester) async {
      final expenseWithoutNote = Expense(
        id: 'exp2',
        userId: 'user1',
        amount: 15.00,
        categoryId: 'cat1',
        expenseDate: DateTime.now(),
        note: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: testCategory,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: expenseWithoutNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // La carte devrait s'afficher sans erreur
      expect(find.byType(ExpenseCard), findsOneWidget);
    });

    testWidgets('affiche l\'icône de la catégorie', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: testExpense,
              onTap: () {},
            ),
          ),
        ),
      );

      // Vérifie qu'une icône est présente
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
