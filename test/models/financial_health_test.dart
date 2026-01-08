import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/financial_health.dart';

void main() {
  group('HealthLevel', () {
    test('should have correct labels', () {
      expect(HealthLevel.excellent.label, 'Excellent');
      expect(HealthLevel.good.label, 'Bon');
      expect(HealthLevel.fair.label, 'Moyen');
      expect(HealthLevel.poor.label, 'Faible');
      expect(HealthLevel.critical.label, 'Critique');
    });

    test('should have emojis', () {
      expect(HealthLevel.excellent.emoji, '🌟');
      expect(HealthLevel.good.emoji, '😊');
      expect(HealthLevel.fair.emoji, '😐');
      expect(HealthLevel.poor.emoji, '😟');
      expect(HealthLevel.critical.emoji, '🚨');
    });

    test('should have colors', () {
      expect(HealthLevel.excellent.color, '#4CAF50');
      expect(HealthLevel.good.color, '#8BC34A');
      expect(HealthLevel.fair.color, '#FFC107');
      expect(HealthLevel.poor.color, '#FF9800');
      expect(HealthLevel.critical.color, '#F44336');
    });
  });

  group('HealthComponent', () {
    test('should create HealthComponent with all fields', () {
      const component = HealthComponent(
        name: 'Budget',
        description: 'Respect du budget',
        score: 80,
        maxScore: 100,
        icon: '💰',
        tips: ['Conseil 1', 'Conseil 2'],
      );

      expect(component.name, 'Budget');
      expect(component.description, 'Respect du budget');
      expect(component.score, 80);
      expect(component.maxScore, 100);
      expect(component.icon, '💰');
      expect(component.tips.length, 2);
    });

    test('percentage should calculate correctly', () {
      const component = HealthComponent(
        name: 'Test',
        description: 'Test',
        score: 75,
        maxScore: 100,
        icon: '📊',
      );

      expect(component.percentage, 0.75);
    });

    test('percentage should clamp between 0 and 1', () {
      const overScore = HealthComponent(
        name: 'Test',
        description: 'Test',
        score: 150,
        maxScore: 100,
        icon: '📊',
      );
      expect(overScore.percentage, 1.0);

      const negativeScore = HealthComponent(
        name: 'Test',
        description: 'Test',
        score: -10,
        maxScore: 100,
        icon: '📊',
      );
      expect(negativeScore.percentage, 0.0);
    });

    test('percentage should handle different maxScore', () {
      const component = HealthComponent(
        name: 'Test',
        description: 'Test',
        score: 15,
        maxScore: 20,
        icon: '📊',
      );

      expect(component.percentage, 0.75);
    });
  });

  group('FinancialHealth', () {
    final now = DateTime.now();

    const budgetScore = HealthComponent(
      name: 'Budget',
      description: 'Respect du budget',
      score: 90,
      icon: '💰',
    );

    const savingsScore = HealthComponent(
      name: 'Épargne',
      description: 'Capacité d\'épargne',
      score: 70,
      icon: '🐷',
    );

    const consistencyScore = HealthComponent(
      name: 'Régularité',
      description: 'Suivi régulier',
      score: 85,
      icon: '📊',
    );

    const goalsScore = HealthComponent(
      name: 'Objectifs',
      description: 'Progression vers les objectifs',
      score: 60,
      icon: '🎯',
    );

    const billsScore = HealthComponent(
      name: 'Factures',
      description: 'Paiement des factures',
      score: 95,
      icon: '📋',
    );

    final testHealth = FinancialHealth(
      overallScore: 80,
      level: HealthLevel.good,
      budgetScore: budgetScore,
      savingsScore: savingsScore,
      consistencyScore: consistencyScore,
      goalsScore: goalsScore,
      billsScore: billsScore,
      calculatedAt: now,
      trend: 1,
      previousScore: 75,
    );

    group('getLevelFromScore', () {
      test('should return excellent for score >= 85', () {
        expect(FinancialHealth.getLevelFromScore(85), HealthLevel.excellent);
        expect(FinancialHealth.getLevelFromScore(100), HealthLevel.excellent);
        expect(FinancialHealth.getLevelFromScore(90), HealthLevel.excellent);
      });

      test('should return good for score 70-84', () {
        expect(FinancialHealth.getLevelFromScore(70), HealthLevel.good);
        expect(FinancialHealth.getLevelFromScore(84), HealthLevel.good);
        expect(FinancialHealth.getLevelFromScore(75), HealthLevel.good);
      });

      test('should return fair for score 50-69', () {
        expect(FinancialHealth.getLevelFromScore(50), HealthLevel.fair);
        expect(FinancialHealth.getLevelFromScore(69), HealthLevel.fair);
        expect(FinancialHealth.getLevelFromScore(55), HealthLevel.fair);
      });

      test('should return poor for score 30-49', () {
        expect(FinancialHealth.getLevelFromScore(30), HealthLevel.poor);
        expect(FinancialHealth.getLevelFromScore(49), HealthLevel.poor);
        expect(FinancialHealth.getLevelFromScore(40), HealthLevel.poor);
      });

      test('should return critical for score < 30', () {
        expect(FinancialHealth.getLevelFromScore(29), HealthLevel.critical);
        expect(FinancialHealth.getLevelFromScore(0), HealthLevel.critical);
        expect(FinancialHealth.getLevelFromScore(15), HealthLevel.critical);
      });
    });

    group('components', () {
      test('should return all 5 components', () {
        expect(testHealth.components.length, 5);
        expect(testHealth.components, contains(budgetScore));
        expect(testHealth.components, contains(savingsScore));
        expect(testHealth.components, contains(goalsScore));
      });
    });

    group('weakestComponent', () {
      test('should return component with lowest percentage', () {
        final weakest = testHealth.weakestComponent;
        expect(weakest.name, 'Objectifs'); // score 60, lowest
      });
    });

    group('strongestComponent', () {
      test('should return component with highest percentage', () {
        final strongest = testHealth.strongestComponent;
        expect(strongest.name, 'Factures'); // score 95, highest
      });
    });

    group('motivationMessage', () {
      test('should return correct message for excellent', () {
        final excellent = FinancialHealth(
          overallScore: 90,
          level: HealthLevel.excellent,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(excellent.motivationMessage, contains('Félicitations'));
      });

      test('should return correct message for good', () {
        expect(testHealth.motivationMessage, contains('Très bien'));
      });

      test('should return correct message for fair', () {
        final fair = FinancialHealth(
          overallScore: 55,
          level: HealthLevel.fair,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(fair.motivationMessage, contains('Pas mal'));
      });

      test('should return correct message for poor', () {
        final poor = FinancialHealth(
          overallScore: 35,
          level: HealthLevel.poor,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(poor.motivationMessage, contains('travail'));
      });

      test('should return correct message for critical', () {
        final critical = FinancialHealth(
          overallScore: 20,
          level: HealthLevel.critical,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(critical.motivationMessage, contains('reprendre le contrôle'));
      });
    });

    group('equality', () {
      test('should be equal for same overallScore, level, calculatedAt', () {
        final health1 = FinancialHealth(
          overallScore: 80,
          level: HealthLevel.good,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        final health2 = FinancialHealth(
          overallScore: 80,
          level: HealthLevel.good,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
          trend: -1, // Different but not in props
          previousScore: 90, // Different but not in props
        );

        expect(health1, equals(health2));
      });

      test('should not be equal for different score', () {
        final health1 = FinancialHealth(
          overallScore: 80,
          level: HealthLevel.good,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        final health2 = FinancialHealth(
          overallScore: 90,
          level: HealthLevel.excellent,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(health1, isNot(equals(health2)));
      });
    });

    group('default values', () {
      test('should have default trend and previousScore', () {
        final health = FinancialHealth(
          overallScore: 70,
          level: HealthLevel.good,
          budgetScore: budgetScore,
          savingsScore: savingsScore,
          consistencyScore: consistencyScore,
          goalsScore: goalsScore,
          billsScore: billsScore,
          calculatedAt: now,
        );

        expect(health.trend, 0);
        expect(health.previousScore, 0);
      });
    });
  });
}
