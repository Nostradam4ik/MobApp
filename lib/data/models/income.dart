import 'package:equatable/equatable.dart';

/// Types de revenus
enum IncomeType {
  salary('salary', 'Salaire', '💼'),
  freelance('freelance', 'Freelance', '💻'),
  rental('rental', 'Location', '🏠'),
  investment('investment', 'Investissement', '📈'),
  gift('gift', 'Cadeau', '🎁'),
  refund('refund', 'Remboursement', '↩️'),
  bonus('bonus', 'Prime', '🎉'),
  pension('pension', 'Pension', '👴'),
  allowance('allowance', 'Allocation', '📋'),
  other('other', 'Autre', '💰');

  const IncomeType(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static IncomeType fromString(String value) {
    return IncomeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IncomeType.other,
    );
  }
}

/// Fréquence de récurrence
enum IncomeFrequency {
  once('once', 'Unique'),
  weekly('weekly', 'Hebdomadaire'),
  biweekly('biweekly', 'Bi-mensuel'),
  monthly('monthly', 'Mensuel'),
  quarterly('quarterly', 'Trimestriel'),
  yearly('yearly', 'Annuel');

  const IncomeFrequency(this.value, this.label);
  final String value;
  final String label;

  static IncomeFrequency fromString(String value) {
    return IncomeFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IncomeFrequency.once,
    );
  }
}

/// Modèle de revenu
class Income extends Equatable {
  final String id;
  final String userId;
  final String? accountId;
  final double amount;
  final IncomeType type;
  final String? source;
  final String? note;
  final DateTime date;
  final bool isRecurring;
  final IncomeFrequency frequency;
  final DateTime? nextOccurrence;
  final bool isConfirmed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Income({
    required this.id,
    required this.userId,
    this.accountId,
    required this.amount,
    required this.type,
    this.source,
    this.note,
    required this.date,
    this.isRecurring = false,
    this.frequency = IncomeFrequency.once,
    this.nextOccurrence,
    this.isConfirmed = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un Income depuis un JSON
  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: IncomeType.fromString(json['type'] as String? ?? 'other'),
      source: json['source'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      frequency: IncomeFrequency.fromString(json['frequency'] as String? ?? 'once'),
      nextOccurrence: json['next_occurrence'] != null
          ? DateTime.parse(json['next_occurrence'] as String)
          : null,
      isConfirmed: json['is_confirmed'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'amount': amount,
      'type': type.value,
      'source': source,
      'note': note,
      'date': date.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'frequency': frequency.value,
      'next_occurrence': nextOccurrence?.toIso8601String().split('T')[0],
      'is_confirmed': isConfirmed,
    };
  }

  /// Copie avec modifications
  Income copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    IncomeType? type,
    String? source,
    String? note,
    DateTime? date,
    bool? isRecurring,
    IncomeFrequency? frequency,
    DateTime? nextOccurrence,
    bool? isConfirmed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      note: note ?? this.note,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nom d'affichage
  String get displayName => source ?? type.label;

  /// Calcule la prochaine occurrence pour les revenus récurrents
  DateTime? calculateNextOccurrence() {
    if (!isRecurring) return null;

    final now = DateTime.now();
    var next = date;

    while (next.isBefore(now)) {
      switch (frequency) {
        case IncomeFrequency.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case IncomeFrequency.biweekly:
          next = next.add(const Duration(days: 14));
          break;
        case IncomeFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case IncomeFrequency.quarterly:
          next = DateTime(next.year, next.month + 3, next.day);
          break;
        case IncomeFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
        case IncomeFrequency.once:
          return null;
      }
    }

    return next;
  }

  /// Montant mensuel estimé
  double get monthlyAmount {
    switch (frequency) {
      case IncomeFrequency.weekly:
        return amount * 4.33;
      case IncomeFrequency.biweekly:
        return amount * 2.17;
      case IncomeFrequency.monthly:
        return amount;
      case IncomeFrequency.quarterly:
        return amount / 3;
      case IncomeFrequency.yearly:
        return amount / 12;
      case IncomeFrequency.once:
        return 0;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        amount,
        type,
        source,
        note,
        date,
        isRecurring,
        frequency,
        nextOccurrence,
        isConfirmed,
        createdAt,
        updatedAt,
      ];
}
