import 'package:equatable/equatable.dart';
import 'category.dart';

/// Modèle de budget
class Budget extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final double monthlyLimit;
  final int alertThreshold;
  final bool isActive;
  final DateTime periodStart;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relation
  final Category? category;

  // Calculé
  final double spent;

  const Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.monthlyLimit,
    this.alertThreshold = 80,
    this.isActive = true,
    required this.periodStart,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.spent = 0,
  });

  /// Crée un Budget depuis un JSON
  factory Budget.fromJson(Map<String, dynamic> json, {double spent = 0}) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      alertThreshold: json['alert_threshold'] as int? ?? 80,
      isActive: json['is_active'] as bool? ?? true,
      periodStart: DateTime.parse(json['period_start'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      spent: spent,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
      'alert_threshold': alertThreshold,
      'is_active': isActive,
      'period_start': periodStart.toIso8601String().split('T')[0],
    };
  }

  /// Copie avec modifications
  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? monthlyLimit,
    int? alertThreshold,
    bool? isActive,
    DateTime? periodStart,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      periodStart: periodStart ?? this.periodStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      spent: spent ?? this.spent,
    );
  }

  /// Montant restant
  double get remaining => monthlyLimit - spent;

  /// Pourcentage utilisé
  double get percentUsed => (spent / monthlyLimit * 100).clamp(0, 100);

  /// Vérifie si le budget est dépassé
  bool get isOverBudget => spent >= monthlyLimit;

  /// Vérifie si l'alerte doit être affichée
  bool get shouldAlert => percentUsed >= alertThreshold;

  /// Retourne le statut du budget
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.exceeded;
    if (percentUsed >= alertThreshold) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }

  /// Nom d'affichage (catégorie ou "Budget global")
  String get displayName => category?.name ?? 'Budget global';

  /// Vérifie si c'est un budget global
  bool get isGlobal => categoryId == null;

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        monthlyLimit,
        alertThreshold,
        isActive,
        periodStart,
        createdAt,
        updatedAt,
        spent,
      ];
}

/// Statut du budget
enum BudgetStatus {
  ok,
  warning,
  exceeded,
}
