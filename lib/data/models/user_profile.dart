import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Modèle de profil utilisateur
class UserProfile extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String currency;
  final IncomeType incomeType;
  final double monthlyIncome;
  final bool notificationEnabled;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.currency = 'EUR',
    this.incomeType = IncomeType.fixed,
    this.monthlyIncome = 0,
    this.notificationEnabled = true,
    this.isPremium = false,
    this.premiumExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un UserProfile depuis un JSON (Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      incomeType: IncomeType.fromString(json['income_type'] as String? ?? 'fixed'),
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'currency': currency,
      'income_type': incomeType.value,
      'monthly_income': monthlyIncome,
      'notification_enabled': notificationEnabled,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
    };
  }

  /// Copie avec modifications
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? currency,
    IncomeType? incomeType,
    double? monthlyIncome,
    bool? notificationEnabled,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currency: currency ?? this.currency,
      incomeType: incomeType ?? this.incomeType,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si le premium est actif
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Retourne les initiales du nom
  String get initials {
    if (name == null || name!.isEmpty) {
      return email?.substring(0, 1).toUpperCase() ?? '?';
    }
    final parts = name!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        currency,
        incomeType,
        monthlyIncome,
        notificationEnabled,
        isPremium,
        premiumExpiresAt,
        createdAt,
        updatedAt,
      ];
}
