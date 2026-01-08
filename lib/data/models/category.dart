import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modèle de catégorie de dépense
class Category extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    this.icon = 'category',
    this.color = '#6366F1',
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une Category depuis un JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#6366F1',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
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
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  /// Copie avec modifications
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne la couleur Flutter
  Color get colorValue => AppColors.fromHex(color);

  /// Retourne l'IconData correspondant au nom d'icône
  IconData get iconData => _iconMap[icon] ?? Icons.category;

  /// Map des icônes disponibles
  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'sports_esports': Icons.sports_esports,
    'shopping_bag': Icons.shopping_bag,
    'medical_services': Icons.medical_services,
    'receipt_long': Icons.receipt_long,
    'coffee': Icons.coffee,
    'subscriptions': Icons.subscriptions,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'local_bar': Icons.local_bar,
    'flight': Icons.flight,
    'school': Icons.school,
    'pets': Icons.pets,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'phone_android': Icons.phone_android,
    'card_giftcard': Icons.card_giftcard,
    'attach_money': Icons.attach_money,
    'savings': Icons.savings,
    'work': Icons.work,
    'child_care': Icons.child_care,
    'local_grocery_store': Icons.local_grocery_store,
  };

  /// Liste des icônes disponibles
  static List<String> get availableIcons => _iconMap.keys.toList();

  /// Retourne l'IconData pour un nom donné
  static IconData getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.category;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        color,
        isDefault,
        isActive,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
