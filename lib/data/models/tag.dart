import 'package:equatable/equatable.dart';

/// Modèle de tag personnalisé
class Tag extends Equatable {
  final String id;
  final String name;
  final String color; // Hex color code
  final String? icon;
  final DateTime createdAt;
  final int usageCount;

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
    this.usageCount = 0,
  });

  /// Couleurs prédéfinies pour les tags
  static const List<String> predefinedColors = [
    '#FF6B6B', // Rouge
    '#4ECDC4', // Turquoise
    '#45B7D1', // Bleu clair
    '#96CEB4', // Vert menthe
    '#FFEAA7', // Jaune
    '#DDA0DD', // Prune
    '#98D8C8', // Vert d'eau
    '#F7DC6F', // Or
    '#BB8FCE', // Violet
    '#85C1E9', // Bleu ciel
    '#F8B500', // Orange
    '#58D68D', // Vert
    '#EC7063', // Corail
    '#5DADE2', // Bleu
    '#AF7AC5', // Mauve
    '#48C9B0', // Émeraude
  ];

  /// Icônes suggérées pour les tags
  static const List<String> suggestedIcons = [
    '🏷️', '⭐', '💡', '🎯', '🔥', '💰', '🎁', '🏠',
    '🚗', '✈️', '🍔', '☕', '🎬', '📚', '💊', '🏃',
    '👔', '🎮', '🐕', '👶', '💳', '📱', '🔧', '🎵',
  ];

  /// Tags suggérés pour démarrer
  static List<Tag> get suggestedTags => [
    Tag(
      id: 'suggested-urgent',
      name: 'Urgent',
      color: '#FF6B6B',
      icon: '🔥',
      createdAt: DateTime.now(),
    ),
    Tag(
      id: 'suggested-recurring',
      name: 'Récurrent',
      color: '#4ECDC4',
      icon: '🔄',
      createdAt: DateTime.now(),
    ),
    Tag(
      id: 'suggested-optional',
      name: 'Optionnel',
      color: '#FFEAA7',
      icon: '💡',
      createdAt: DateTime.now(),
    ),
    Tag(
      id: 'suggested-essential',
      name: 'Essentiel',
      color: '#58D68D',
      icon: '✅',
      createdAt: DateTime.now(),
    ),
    Tag(
      id: 'suggested-savings',
      name: 'Économie',
      color: '#85C1E9',
      icon: '🐷',
      createdAt: DateTime.now(),
    ),
    Tag(
      id: 'suggested-pleasure',
      name: 'Plaisir',
      color: '#DDA0DD',
      icon: '🎉',
      createdAt: DateTime.now(),
    ),
  ];

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Incrémente le compteur d'utilisation
  Tag incrementUsage() {
    return copyWith(usageCount: usageCount + 1);
  }

  /// Décrémente le compteur d'utilisation
  Tag decrementUsage() {
    return copyWith(usageCount: usageCount > 0 ? usageCount - 1 : 0);
  }

  @override
  List<Object?> get props => [id, name, color, icon];
}

/// Association entre dépense et tag
class ExpenseTag extends Equatable {
  final String expenseId;
  final String tagId;

  const ExpenseTag({
    required this.expenseId,
    required this.tagId,
  });

  factory ExpenseTag.fromJson(Map<String, dynamic> json) {
    return ExpenseTag(
      expenseId: json['expense_id'] as String,
      tagId: json['tag_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'tag_id': tagId,
    };
  }

  @override
  List<Object?> get props => [expenseId, tagId];
}

/// Statistiques d'un tag
class TagStats {
  final Tag tag;
  final int expenseCount;
  final double totalAmount;
  final double averageAmount;
  final DateTime? lastUsed;

  const TagStats({
    required this.tag,
    required this.expenseCount,
    required this.totalAmount,
    required this.averageAmount,
    this.lastUsed,
  });
}
