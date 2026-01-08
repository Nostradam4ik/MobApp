import 'package:equatable/equatable.dart';

/// Statut d'un remboursement
enum SplitStatus {
  pending,
  partiallyPaid,
  paid,
  cancelled;

  String get label {
    switch (this) {
      case SplitStatus.pending:
        return 'En attente';
      case SplitStatus.partiallyPaid:
        return 'Partiellement payé';
      case SplitStatus.paid:
        return 'Payé';
      case SplitStatus.cancelled:
        return 'Annulé';
    }
  }

  String get emoji {
    switch (this) {
      case SplitStatus.pending:
        return '⏳';
      case SplitStatus.partiallyPaid:
        return '💰';
      case SplitStatus.paid:
        return '✅';
      case SplitStatus.cancelled:
        return '❌';
    }
  }
}

/// Participant à un partage de dépense
class SplitParticipant extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final double amount;
  final double paidAmount;
  final SplitStatus status;
  final DateTime? paidAt;

  const SplitParticipant({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.amount,
    this.paidAmount = 0,
    this.status = SplitStatus.pending,
    this.paidAt,
  });

  /// Montant restant à payer
  double get remainingAmount => (amount - paidAmount).clamp(0, double.infinity);

  /// Est-ce que tout est payé ?
  bool get isFullyPaid => paidAmount >= amount;

  /// Pourcentage payé
  double get paidPercentage => amount > 0 ? (paidAmount / amount).clamp(0, 1) : 0;

  SplitParticipant copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? amount,
    double? paidAmount,
    SplitStatus? status,
    DateTime? paidAt,
  }) {
    return SplitParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'amount': amount,
      'paid_amount': paidAmount,
      'status': status.name,
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      status: SplitStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SplitStatus.pending,
      ),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, amount, paidAmount, status];
}

/// Mode de partage
enum SplitMode {
  equal,       // Parts égales
  percentage,  // Par pourcentage
  exact,       // Montants exacts
  shares;      // Par nombre de parts

  String get label {
    switch (this) {
      case SplitMode.equal:
        return 'Parts égales';
      case SplitMode.percentage:
        return 'Par pourcentage';
      case SplitMode.exact:
        return 'Montants exacts';
      case SplitMode.shares:
        return 'Par parts';
    }
  }

  String get icon {
    switch (this) {
      case SplitMode.equal:
        return '⚖️';
      case SplitMode.percentage:
        return '📊';
      case SplitMode.exact:
        return '💵';
      case SplitMode.shares:
        return '🍕';
    }
  }
}

/// Dépense partagée
class ExpenseSplit extends Equatable {
  final String id;
  final String expenseId;
  final String userId;
  final String title;
  final String? description;
  final double totalAmount;
  final SplitMode mode;
  final List<SplitParticipant> participants;
  final bool includeMe;
  final double myShare;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.mode,
    required this.participants,
    this.includeMe = true,
    required this.myShare,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Montant total à recevoir des autres
  double get totalToReceive {
    return participants.fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Montant déjà reçu
  double get totalReceived {
    return participants.fold(0.0, (sum, p) => sum + p.paidAmount);
  }

  /// Montant restant à recevoir
  double get totalRemaining => totalToReceive - totalReceived;

  /// Pourcentage récupéré
  double get recoveryPercentage =>
      totalToReceive > 0 ? (totalReceived / totalToReceive).clamp(0, 1) : 0;

  /// Nombre de personnes qui ont payé
  int get paidCount => participants.where((p) => p.isFullyPaid).length;

  /// Nombre total de participants (autres que moi)
  int get participantCount => participants.length;

  /// Est-ce que tout le monde a payé ?
  bool get isFullySettled => participants.every((p) => p.isFullyPaid);

  /// Statut global
  SplitStatus get overallStatus {
    if (isFullySettled) return SplitStatus.paid;
    if (totalReceived > 0) return SplitStatus.partiallyPaid;
    return SplitStatus.pending;
  }

  ExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? userId,
    String? title,
    String? description,
    double? totalAmount,
    SplitMode? mode,
    List<SplitParticipant>? participants,
    bool? includeMe,
    double? myShare,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      mode: mode ?? this.mode,
      participants: participants ?? this.participants,
      includeMe: includeMe ?? this.includeMe,
      myShare: myShare ?? this.myShare,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'title': title,
      'description': description,
      'total_amount': totalAmount,
      'mode': mode.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'include_me': includeMe,
      'my_share': myShare,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      mode: SplitMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SplitMode.equal,
      ),
      participants: (json['participants'] as List<dynamic>)
          .map((p) => SplitParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      includeMe: json['include_me'] as bool? ?? true,
      myShare: (json['my_share'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, expenseId, participants, updatedAt];
}

/// Contact fréquent pour le partage
class SplitContact extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final int splitCount;
  final DateTime lastUsed;

  const SplitContact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.splitCount = 0,
    required this.lastUsed,
  });

  SplitContact copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? splitCount,
    DateTime? lastUsed,
  }) {
    return SplitContact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      splitCount: splitCount ?? this.splitCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'split_count': splitCount,
        'last_used': lastUsed.toIso8601String(),
      };

  factory SplitContact.fromJson(Map<String, dynamic> json) => SplitContact(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        splitCount: json['split_count'] as int? ?? 0,
        lastUsed: DateTime.parse(json['last_used'] as String),
      );

  @override
  List<Object?> get props => [id, name];
}
