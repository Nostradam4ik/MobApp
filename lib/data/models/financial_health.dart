import 'package:equatable/equatable.dart';

/// Niveau de santé financière
enum HealthLevel {
  excellent,
  good,
  fair,
  poor,
  critical;

  String get label {
    switch (this) {
      case HealthLevel.excellent:
        return 'Excellent';
      case HealthLevel.good:
        return 'Bon';
      case HealthLevel.fair:
        return 'Moyen';
      case HealthLevel.poor:
        return 'Faible';
      case HealthLevel.critical:
        return 'Critique';
    }
  }

  String get emoji {
    switch (this) {
      case HealthLevel.excellent:
        return '🌟';
      case HealthLevel.good:
        return '😊';
      case HealthLevel.fair:
        return '😐';
      case HealthLevel.poor:
        return '😟';
      case HealthLevel.critical:
        return '🚨';
    }
  }

  String get color {
    switch (this) {
      case HealthLevel.excellent:
        return '#4CAF50';
      case HealthLevel.good:
        return '#8BC34A';
      case HealthLevel.fair:
        return '#FFC107';
      case HealthLevel.poor:
        return '#FF9800';
      case HealthLevel.critical:
        return '#F44336';
    }
  }
}

/// Composant du score de santé
class HealthComponent extends Equatable {
  final String name;
  final String description;
  final int score; // 0-100
  final int maxScore;
  final String icon;
  final List<String> tips;

  const HealthComponent({
    required this.name,
    required this.description,
    required this.score,
    this.maxScore = 100,
    required this.icon,
    this.tips = const [],
  });

  double get percentage => (score / maxScore).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [name, score, maxScore];
}

/// Score de santé financière global
class FinancialHealth extends Equatable {
  final int overallScore; // 0-100
  final HealthLevel level;
  final HealthComponent budgetScore;
  final HealthComponent savingsScore;
  final HealthComponent consistencyScore;
  final HealthComponent goalsScore;
  final HealthComponent billsScore;
  final DateTime calculatedAt;
  final int trend; // -1, 0, 1 (baisse, stable, hausse)
  final int previousScore;

  const FinancialHealth({
    required this.overallScore,
    required this.level,
    required this.budgetScore,
    required this.savingsScore,
    required this.consistencyScore,
    required this.goalsScore,
    required this.billsScore,
    required this.calculatedAt,
    this.trend = 0,
    this.previousScore = 0,
  });

  /// Obtient le niveau basé sur le score
  static HealthLevel getLevelFromScore(int score) {
    if (score >= 85) return HealthLevel.excellent;
    if (score >= 70) return HealthLevel.good;
    if (score >= 50) return HealthLevel.fair;
    if (score >= 30) return HealthLevel.poor;
    return HealthLevel.critical;
  }

  /// Liste de tous les composants
  List<HealthComponent> get components => [
        budgetScore,
        savingsScore,
        consistencyScore,
        goalsScore,
        billsScore,
      ];

  /// Composant le plus faible (à améliorer en priorité)
  HealthComponent get weakestComponent {
    return components.reduce((a, b) => a.percentage < b.percentage ? a : b);
  }

  /// Composant le plus fort
  HealthComponent get strongestComponent {
    return components.reduce((a, b) => a.percentage > b.percentage ? a : b);
  }

  /// Message de motivation basé sur le niveau
  String get motivationMessage {
    switch (level) {
      case HealthLevel.excellent:
        return 'Félicitations ! Vous gérez vos finances comme un pro ! 🎉';
      case HealthLevel.good:
        return 'Très bien ! Continuez sur cette lancée ! 💪';
      case HealthLevel.fair:
        return 'Pas mal ! Quelques ajustements et vous y êtes ! 📈';
      case HealthLevel.poor:
        return 'Il y a du travail, mais chaque petit pas compte ! 🚶';
      case HealthLevel.critical:
        return 'C\'est le moment de reprendre le contrôle ! Commencez petit. 🌱';
    }
  }

  @override
  List<Object?> get props => [overallScore, level, calculatedAt];
}
