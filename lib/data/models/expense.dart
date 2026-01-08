// ============================================================================
// SmartSpend - Modèle Expense
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:equatable/equatable.dart';
import 'category.dart';

/// Modèle de dépense
class Expense extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String? accountId;
  final double amount;
  final String? note;
  final DateTime expenseDate;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relation
  final Category? category;

  const Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    this.accountId,
    required this.amount,
    this.note,
    required this.expenseDate,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  /// Crée une Expense depuis un JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertit en JSON pour création
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      // Note: account_id n'est pas envoyé à Supabase car la colonne n'existe pas
      // La gestion des comptes est locale uniquement pour l'instant
      'amount': amount,
      'note': note,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
    };
  }

  /// Copie avec modifications
  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? accountId,
    double? amount,
    String? note,
    DateTime? expenseDate,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      expenseDate: expenseDate ?? this.expenseDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  /// Vérifie si la dépense est d'aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return expenseDate.year == now.year &&
        expenseDate.month == now.month &&
        expenseDate.day == now.day;
  }

  /// Vérifie si la dépense est de ce mois
  bool get isThisMonth {
    final now = DateTime.now();
    return expenseDate.year == now.year && expenseDate.month == now.month;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        accountId,
        amount,
        note,
        expenseDate,
        isRecurring,
        recurringFrequency,
        createdAt,
        updatedAt,
      ];
}
