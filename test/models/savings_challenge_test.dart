import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/savings_challenge.dart';

void main() {
  group('ChallengeType', () {
    test('should have correct labels', () {
      expect(ChallengeType.noSpend.label, 'Sans dépense');
      expect(ChallengeType.savingsTarget.label, 'Objectif épargne');
      expect(ChallengeType.spendingLimit.label, 'Limite dépense');
      expect(ChallengeType.streak.label, 'Série');
      expect(ChallengeType.weekly52.label, '52 semaines');
      expect(ChallengeType.roundUp.label, 'Arrondi');
      expect(ChallengeType.custom.label, 'Personnalisé');
    });

    test('should have icons', () {
      expect(ChallengeType.noSpend.icon, '🚫');
      expect(ChallengeType.savingsTarget.icon, '🎯');
      expect(ChallengeType.spendingLimit.icon, '💵');
      expect(ChallengeType.streak.icon, '🔥');
      expect(ChallengeType.weekly52.icon, '📅');
      expect(ChallengeType.roundUp.icon, '🔄');
      expect(ChallengeType.custom.icon, '⭐');
    });

    test('should have descriptions', () {
      expect(ChallengeType.noSpend.description, contains('catégorie'));
      expect(ChallengeType.savingsTarget.description, contains('Épargnez'));
      expect(ChallengeType.spendingLimit.description, contains('budget'));
      expect(ChallengeType.streak.description, contains('jours'));
      expect(ChallengeType.weekly52.description, contains('semaine'));
      expect(ChallengeType.roundUp.description, contains('Arrondissez'));
      expect(ChallengeType.custom.description, contains('propre'));
    });
  });

  group('ChallengeDifficulty', () {
    test('should have correct labels', () {
      expect(ChallengeDifficulty.easy.label, 'Facile');
      expect(ChallengeDifficulty.medium.label, 'Moyen');
      expect(ChallengeDifficulty.hard.label, 'Difficile');
      expect(ChallengeDifficulty.extreme.label, 'Extrême');
    });

    test('should have emojis', () {
      expect(ChallengeDifficulty.easy.emoji, '🌱');
      expect(ChallengeDifficulty.medium.emoji, '🌿');
      expect(ChallengeDifficulty.hard.emoji, '🌳');
      expect(ChallengeDifficulty.extreme.emoji, '🔥');
    });

    test('should have correct xpMultiplier', () {
      expect(ChallengeDifficulty.easy.xpMultiplier, 1);
      expect(ChallengeDifficulty.medium.xpMultiplier, 2);
      expect(ChallengeDifficulty.hard.xpMultiplier, 3);
      expect(ChallengeDifficulty.extreme.xpMultiplier, 5);
    });
  });

  group('ChallengeStatus', () {
    test('should have correct labels', () {
      expect(ChallengeStatus.notStarted.label, 'Non commencé');
      expect(ChallengeStatus.active.label, 'En cours');
      expect(ChallengeStatus.completed.label, 'Terminé');
      expect(ChallengeStatus.failed.label, 'Échoué');
      expect(ChallengeStatus.abandoned.label, 'Abandonné');
    });

    test('should have all 5 statuses', () {
      expect(ChallengeStatus.values.length, 5);
    });
  });

  group('SavingsChallenge enum parsing', () {
    test('ChallengeType should parse from name', () {
      for (final type in ChallengeType.values) {
        final parsed = ChallengeType.values.firstWhere(
          (t) => t.name == type.name,
        );
        expect(parsed, type);
      }
    });

    test('ChallengeDifficulty should parse from name', () {
      for (final diff in ChallengeDifficulty.values) {
        final parsed = ChallengeDifficulty.values.firstWhere(
          (d) => d.name == diff.name,
        );
        expect(parsed, diff);
      }
    });

    test('ChallengeStatus should parse from name', () {
      for (final status in ChallengeStatus.values) {
        final parsed = ChallengeStatus.values.firstWhere(
          (s) => s.name == status.name,
        );
        expect(parsed, status);
      }
    });
  });

  group('SavingsChallenge difficulty XP calculation', () {
    test('should calculate XP correctly for each difficulty', () {
      const baseXp = 100;

      expect(baseXp * ChallengeDifficulty.easy.xpMultiplier, 100);
      expect(baseXp * ChallengeDifficulty.medium.xpMultiplier, 200);
      expect(baseXp * ChallengeDifficulty.hard.xpMultiplier, 300);
      expect(baseXp * ChallengeDifficulty.extreme.xpMultiplier, 500);
    });
  });

  group('ChallengeType coverage', () {
    test('should have 7 challenge types', () {
      expect(ChallengeType.values.length, 7);
    });

    test('all types should have non-empty labels', () {
      for (final type in ChallengeType.values) {
        expect(type.label.isNotEmpty, true);
      }
    });

    test('all types should have non-empty icons', () {
      for (final type in ChallengeType.values) {
        expect(type.icon.isNotEmpty, true);
      }
    });

    test('all types should have non-empty descriptions', () {
      for (final type in ChallengeType.values) {
        expect(type.description.isNotEmpty, true);
      }
    });
  });

  group('ChallengeDifficulty coverage', () {
    test('should have 4 difficulty levels', () {
      expect(ChallengeDifficulty.values.length, 4);
    });

    test('xpMultiplier should increase with difficulty', () {
      expect(ChallengeDifficulty.easy.xpMultiplier,
          lessThan(ChallengeDifficulty.medium.xpMultiplier));
      expect(ChallengeDifficulty.medium.xpMultiplier,
          lessThan(ChallengeDifficulty.hard.xpMultiplier));
      expect(ChallengeDifficulty.hard.xpMultiplier,
          lessThan(ChallengeDifficulty.extreme.xpMultiplier));
    });
  });
}
