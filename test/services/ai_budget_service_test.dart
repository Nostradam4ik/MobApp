// ============================================================================
// SmartSpend - Tests du service IA Budget
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/services/ai_budget_service.dart';
import 'package:smartspend/data/models/expense.dart';
import 'package:smartspend/data/models/category.dart';
import 'package:smartspend/data/models/budget.dart';

void main() {
  group('AIBudgetService', () {
    final testCategories = [
      Category(
        id: 'cat1',
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
        id: 'cat2',
        userId: 'user1',
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
        sortOrder: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    group('AISuggestion', () {
      test('devrait avoir les bonnes propriétés', () {
        final suggestion = AISuggestion(
          id: 'test_1',
          type: SuggestionType.budgetOptimization,
          priority: SuggestionPriority.high,
          title: 'Test Title',
          description: 'Test Description',
          potentialSaving: 50.0,
        );

        expect(suggestion.id, 'test_1');
        expect(suggestion.type, SuggestionType.budgetOptimization);
        expect(suggestion.priority, SuggestionPriority.high);
        expect(suggestion.title, 'Test Title');
        expect(suggestion.description, 'Test Description');
        expect(suggestion.potentialSaving, 50.0);
        expect(suggestion.isRead, false);
        expect(suggestion.isDismissed, false);
      });

      test('devrait avoir une icône pour chaque type', () {
        for (final type in SuggestionType.values) {
          final suggestion = AISuggestion(
            id: 'test',
            type: type,
            priority: SuggestionPriority.low,
            title: 'Test',
            description: 'Test',
          );
          expect(suggestion.icon, isNotEmpty);
        }
      });

      test('devrait avoir une couleur pour chaque priorité', () {
        for (final priority in SuggestionPriority.values) {
          final suggestion = AISuggestion(
            id: 'test',
            type: SuggestionType.savingOpportunity,
            priority: priority,
            title: 'Test',
            description: 'Test',
          );
          expect(suggestion.priorityColor, isPositive);
        }
      });
    });

    group('analyzeAndSuggest', () {
      test('devrait retourner une liste vide pour des listes vides', () {
        final suggestions = AIBudgetService.analyzeAndSuggest(
          expenses: [],
          categories: [],
          budgets: [],
        );

        expect(suggestions, isEmpty);
      });

      test('devrait détecter un budget dépassé', () {
        final budget = Budget(
          id: 'budget1',
          userId: 'user1',
          monthlyLimit: 500,
          spent: 600, // Dépassé
          alertThreshold: 80,
          periodStart: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final suggestions = AIBudgetService.analyzeAndSuggest(
          expenses: [],
          categories: testCategories,
          budgets: [budget],
        );

        final budgetAlert = suggestions.where((s) =>
          s.type == SuggestionType.spendingAlert &&
          s.priority == SuggestionPriority.critical
        );

        expect(budgetAlert, isNotEmpty);
      });

      test('devrait détecter un budget presque épuisé', () {
        final budget = Budget(
          id: 'budget1',
          userId: 'user1',
          monthlyLimit: 500,
          spent: 475, // 95%
          alertThreshold: 80,
          periodStart: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final suggestions = AIBudgetService.analyzeAndSuggest(
          expenses: [],
          categories: testCategories,
          budgets: [budget],
        );

        final budgetWarning = suggestions.where((s) =>
          s.type == SuggestionType.budgetOptimization &&
          s.priority == SuggestionPriority.high
        );

        expect(budgetWarning, isNotEmpty);
      });

      test('devrait suggérer un taux d\'épargne si revenu faible', () {
        final now = DateTime.now();
        final expenses = List.generate(5, (i) => Expense(
          id: 'exp_$i',
          userId: 'user1',
          amount: 200.0,
          expenseDate: DateTime(now.year, now.month, now.day - i),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final suggestions = AIBudgetService.analyzeAndSuggest(
          expenses: expenses,
          categories: testCategories,
          budgets: [],
          monthlyIncome: 1100, // Revenus de 1100€, dépenses de 1000€
        );

        final savingsSuggestion = suggestions.where((s) =>
          s.type == SuggestionType.smartSaving
        );

        expect(savingsSuggestion, isNotEmpty);
      });
    });

    group('generateAISummary', () {
      test('devrait générer un résumé quand pas de suggestions', () {
        final summary = AIBudgetService.generateAISummary(
          expenses: [],
          categories: [],
          budgets: [],
        );

        expect(summary, contains('bon état'));
      });

      test('devrait inclure les économies potentielles', () {
        final budget = Budget(
          id: 'budget1',
          userId: 'user1',
          monthlyLimit: 500,
          spent: 600,
          alertThreshold: 80,
          periodStart: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final summary = AIBudgetService.generateAISummary(
          expenses: [],
          categories: testCategories,
          budgets: [budget],
        );

        expect(summary, isNotEmpty);
      });
    });
  });

  group('SuggestionType', () {
    test('devrait avoir tous les types requis', () {
      expect(SuggestionType.values, contains(SuggestionType.budgetOptimization));
      expect(SuggestionType.values, contains(SuggestionType.savingOpportunity));
      expect(SuggestionType.values, contains(SuggestionType.spendingAlert));
      expect(SuggestionType.values, contains(SuggestionType.trendAnalysis));
      expect(SuggestionType.values, contains(SuggestionType.unusualSpending));
      expect(SuggestionType.values, contains(SuggestionType.recurringExpenseAlert));
    });
  });

  group('SuggestionPriority', () {
    test('devrait avoir les priorités dans le bon ordre', () {
      expect(SuggestionPriority.low.index, lessThan(SuggestionPriority.medium.index));
      expect(SuggestionPriority.medium.index, lessThan(SuggestionPriority.high.index));
      expect(SuggestionPriority.high.index, lessThan(SuggestionPriority.critical.index));
    });
  });
}
