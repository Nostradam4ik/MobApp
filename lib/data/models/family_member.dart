import 'package:equatable/equatable.dart';

/// Rôles dans la famille
enum FamilyRole {
  owner('owner', 'Propriétaire'),
  admin('admin', 'Administrateur'),
  member('member', 'Membre'),
  viewer('viewer', 'Lecteur');

  const FamilyRole(this.value, this.label);
  final String value;
  final String label;

  static FamilyRole fromString(String value) {
    return FamilyRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FamilyRole.viewer,
    );
  }

  bool get canEdit => this == owner || this == admin || this == member;
  bool get canManageMembers => this == owner || this == admin;
  bool get canDelete => this == owner;
}

/// Statut d'invitation
enum InvitationStatus {
  pending('pending', 'En attente'),
  accepted('accepted', 'Acceptée'),
  declined('declined', 'Refusée'),
  expired('expired', 'Expirée');

  const InvitationStatus(this.value, this.label);
  final String value;
  final String label;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

/// Modèle de groupe familial
class FamilyGroup extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String? description;
  final String currency;
  final double? sharedBudget;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final List<FamilyMember>? members;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    this.description,
    this.currency = 'EUR',
    this.sharedBudget,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.members,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      sharedBudget: (json['shared_budget'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'description': description,
      'currency': currency,
      'shared_budget': sharedBudget,
      'is_active': isActive,
    };
  }

  FamilyGroup copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? description,
    String? currency,
    double? sharedBudget,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FamilyMember>? members,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      sharedBudget: sharedBudget ?? this.sharedBudget,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
    );
  }

  int get memberCount => members?.length ?? 0;

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        description,
        currency,
        sharedBudget,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Modèle de membre de famille
class FamilyMember extends Equatable {
  final String id;
  final String familyId;
  final String userId;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final FamilyRole role;
  final InvitationStatus invitationStatus;
  final double? personalBudget;
  final bool canViewAllExpenses;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.role = FamilyRole.member,
    this.invitationStatus = InvitationStatus.pending,
    this.personalBudget,
    this.canViewAllExpenses = false,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: FamilyRole.fromString(json['role'] as String? ?? 'member'),
      invitationStatus: InvitationStatus.fromString(
        json['invitation_status'] as String? ?? 'pending',
      ),
      personalBudget: (json['personal_budget'] as num?)?.toDouble(),
      canViewAllExpenses: json['can_view_all_expenses'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role.value,
      'invitation_status': invitationStatus.value,
      'personal_budget': personalBudget,
      'can_view_all_expenses': canViewAllExpenses,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    FamilyRole? role,
    InvitationStatus? invitationStatus,
    double? personalBudget,
    bool? canViewAllExpenses,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      personalBudget: personalBudget ?? this.personalBudget,
      canViewAllExpenses: canViewAllExpenses ?? this.canViewAllExpenses,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get name => displayName ?? email ?? 'Membre';
  bool get isAccepted => invitationStatus == InvitationStatus.accepted;
  bool get isPending => invitationStatus == InvitationStatus.pending;

  @override
  List<Object?> get props => [
        id,
        familyId,
        userId,
        email,
        displayName,
        avatarUrl,
        role,
        invitationStatus,
        personalBudget,
        canViewAllExpenses,
        joinedAt,
        createdAt,
        updatedAt,
      ];
}

/// Statistiques familiales
class FamilyStats {
  final String familyId;
  final double totalExpenses;
  final double totalIncome;
  final double budgetUsed;
  final double budgetRemaining;
  final Map<String, double> expensesByMember;
  final Map<String, double> expensesByCategory;

  const FamilyStats({
    required this.familyId,
    required this.totalExpenses,
    required this.totalIncome,
    required this.budgetUsed,
    required this.budgetRemaining,
    required this.expensesByMember,
    required this.expensesByCategory,
  });
}
