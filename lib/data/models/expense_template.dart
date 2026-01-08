import 'package:equatable/equatable.dart';

/// Modèle de template de dépense
/// Permet de créer rapidement des dépenses fréquentes
class ExpenseTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double? amount;
  final String? categoryId;
  final String? accountId;
  final String? note;
  final List<String>? tagIds;
  final String? icon;
  final int color;
  final int usageCount;
  final DateTime? lastUsed;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.amount,
    this.categoryId,
    this.accountId,
    this.note,
    this.tagIds,
    this.icon,
    this.color = 0xFF2196F3,
    this.usageCount = 0,
    this.lastUsed,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un ExpenseTemplate depuis un JSON
  factory ExpenseTemplate.fromJson(Map<String, dynamic> json) {
    return ExpenseTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?,
      note: json['note'] as String?,
      tagIds: (json['tag_ids'] as List<dynamic>?)?.cast<String>(),
      icon: json['icon'] as String?,
      color: json['color'] as int? ?? 0xFF2196F3,
      usageCount: json['usage_count'] as int? ?? 0,
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'note': note,
      'tag_ids': tagIds,
      'icon': icon,
      'color': color,
      'usage_count': usageCount,
      'last_used': lastUsed?.toIso8601String(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  /// Copie avec modifications
  ExpenseTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? categoryId,
    String? accountId,
    String? note,
    List<String>? tagIds,
    String? icon,
    int? color,
    int? usageCount,
    DateTime? lastUsed,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      tagIds: tagIds ?? this.tagIds,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Incrémente le compteur d'utilisation
  ExpenseTemplate incrementUsage() {
    return copyWith(
      usageCount: usageCount + 1,
      lastUsed: DateTime.now(),
    );
  }

  /// Vérifie si le template a un montant fixe
  bool get hasFixedAmount => amount != null && amount! > 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        amount,
        categoryId,
        accountId,
        note,
        tagIds,
        icon,
        color,
        usageCount,
        lastUsed,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Templates prédéfinis suggérés
class SuggestedTemplates {
  static List<Map<String, dynamic>> getDefaults() {
    return [
      {
        'name': 'Café',
        'icon': '☕',
        'amount': 3.50,
        'color': 0xFF795548,
      },
      {
        'name': 'Déjeuner',
        'icon': '🍽️',
        'amount': 12.00,
        'color': 0xFFFF9800,
      },
      {
        'name': 'Transport',
        'icon': '🚇',
        'amount': 2.00,
        'color': 0xFF2196F3,
      },
      {
        'name': 'Courses',
        'icon': '🛒',
        'color': 0xFF4CAF50,
      },
      {
        'name': 'Essence',
        'icon': '⛽',
        'color': 0xFFF44336,
      },
      {
        'name': 'Pharmacie',
        'icon': '💊',
        'color': 0xFF00BCD4,
      },
    ];
  }
}
