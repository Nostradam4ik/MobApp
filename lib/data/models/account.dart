import 'package:equatable/equatable.dart';

/// Types de comptes
enum AccountType {
  cash('cash', 'Espèces', '💵', 0xFF4CAF50),
  checking('checking', 'Compte courant', '🏦', 0xFF2196F3),
  savings('savings', 'Épargne', '🐷', 0xFFFF9800),
  creditCard('credit_card', 'Carte de crédit', '💳', 0xFFF44336),
  investment('investment', 'Investissement', '📈', 0xFF9C27B0),
  loan('loan', 'Prêt', '📋', 0xFF795548),
  wallet('wallet', 'Portefeuille digital', '📱', 0xFF00BCD4),
  other('other', 'Autre', '💰', 0xFF607D8B);

  const AccountType(this.value, this.label, this.emoji, this.defaultColor);
  final String value;
  final String label;
  final String emoji;
  final int defaultColor;

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AccountType.other,
    );
  }
}

/// Modèle de compte bancaire/financier
class Account extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final String currency;
  final int color;
  final String? icon;
  final String? bankName;
  final String? accountNumber;
  final bool isDefault;
  final bool isArchived;
  final bool includeInTotal;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.currency = 'EUR',
    required this.color,
    this.icon,
    this.bankName,
    this.accountNumber,
    this.isDefault = false,
    this.isArchived = false,
    this.includeInTotal = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un Account depuis un JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    // Reconvertir la couleur signée de PostgreSQL en valeur unsigned Flutter
    final rawColor = json['color'] as int? ?? 0xFF2196F3;
    final color = rawColor < 0 ? rawColor + 0x100000000 : rawColor;

    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String? ?? 'other'),
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      color: color,
      icon: json['icon'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      includeInTotal: json['include_in_total'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    // Convertir la couleur en valeur signée pour PostgreSQL integer
    // Les couleurs Flutter utilisent des valeurs unsigned (0xFF...) qui peuvent dépasser int32 max
    final signedColor = color > 0x7FFFFFFF ? color - 0x100000000 : color;

    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.value,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'currency': currency,
      'color': signedColor,
      'icon': icon,
      'bank_name': bankName,
      'account_number': accountNumber,
      'is_default': isDefault,
      'is_archived': isArchived,
      'include_in_total': includeInTotal,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    String? currency,
    int? color,
    String? icon,
    String? bankName,
    String? accountNumber,
    bool? isDefault,
    bool? isArchived,
    bool? includeInTotal,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nom d'affichage complet
  String get displayName => bankName != null ? '$name ($bankName)' : name;

  /// Numéro de compte masqué
  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4) {
      return '****';
    }
    return '****${accountNumber!.substring(accountNumber!.length - 4)}';
  }

  /// Vérifie si le solde est positif
  bool get isPositive => currentBalance >= 0;

  /// Vérifie si c'est une carte de crédit (dette)
  bool get isDebt => type == AccountType.creditCard || type == AccountType.loan;

  /// Solde pour le calcul du total (négatif pour les dettes)
  double get balanceForTotal {
    if (!includeInTotal) return 0;
    return isDebt ? -currentBalance.abs() : currentBalance;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        initialBalance,
        currentBalance,
        currency,
        color,
        icon,
        bankName,
        accountNumber,
        isDefault,
        isArchived,
        includeInTotal,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}

/// Statistiques d'un compte
class AccountStats {
  final String accountId;
  final double totalIncome;
  final double totalExpenses;
  final double netFlow;
  final int transactionCount;
  final DateTime? lastTransaction;

  const AccountStats({
    required this.accountId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.transactionCount,
    this.lastTransaction,
  });
}
