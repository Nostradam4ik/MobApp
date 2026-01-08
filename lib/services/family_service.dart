import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/family_member.dart';
import '../data/models/expense.dart';

/// Service de gestion du mode famille
class FamilyService {
  final SupabaseClient _supabase;
  static const String _groupsTable = 'family_groups';
  static const String _membersTable = 'family_members';
  static const String _sharedExpensesTable = 'shared_expenses';

  FamilyService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;
  String? get _userEmail => _supabase.auth.currentUser?.email;

  // ==================== GROUPES FAMILIAUX ====================

  /// Récupère tous les groupes de l'utilisateur
  Future<List<FamilyGroup>> getMyGroups() async {
    if (_userId == null) return [];

    // Groupes dont l'utilisateur est propriétaire
    final ownedGroups = await _supabase
        .from(_groupsTable)
        .select('*, members:$_membersTable(*)')
        .eq('owner_id', _userId!)
        .eq('is_active', true);

    // Groupes dont l'utilisateur est membre
    final memberOf = await _supabase
        .from(_membersTable)
        .select('family_id')
        .eq('user_id', _userId!)
        .eq('invitation_status', 'accepted');

    final memberGroupIds = (memberOf as List)
        .map((m) => m['family_id'] as String)
        .toList();

    List<dynamic> memberGroups = [];
    if (memberGroupIds.isNotEmpty) {
      memberGroups = await _supabase
          .from(_groupsTable)
          .select('*, members:$_membersTable(*)')
          .inFilter('id', memberGroupIds)
          .eq('is_active', true);
    }

    // Combiner et dédupliquer
    final allGroups = <String, FamilyGroup>{};
    for (final json in [...(ownedGroups as List), ...memberGroups]) {
      final group = FamilyGroup.fromJson(json as Map<String, dynamic>);
      allGroups[group.id] = group;
    }

    return allGroups.values.toList();
  }

  /// Récupère un groupe par son ID
  Future<FamilyGroup?> getGroupById(String id) async {
    final response = await _supabase
        .from(_groupsTable)
        .select('*, members:$_membersTable(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return FamilyGroup.fromJson(response);
  }

  /// Crée un nouveau groupe familial
  Future<FamilyGroup?> createGroup({
    required String name,
    String? description,
    String currency = 'EUR',
    double? sharedBudget,
  }) async {
    if (_userId == null) return null;

    final id = const Uuid().v4();
    final now = DateTime.now();

    final group = FamilyGroup(
      id: id,
      name: name,
      ownerId: _userId!,
      description: description,
      currency: currency,
      sharedBudget: sharedBudget,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _supabase.from(_groupsTable).insert(group.toJson());

    // Ajouter le créateur comme membre propriétaire
    await _addMember(
      familyId: id,
      userId: _userId!,
      email: _userEmail,
      role: FamilyRole.owner,
      status: InvitationStatus.accepted,
    );

    return group;
  }

  /// Met à jour un groupe
  Future<FamilyGroup?> updateGroup(FamilyGroup group) async {
    if (_userId == null) return null;

    // Vérifier les permissions
    final canEdit = await _canManageGroup(group.id);
    if (!canEdit) return null;

    final updated = group.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from(_groupsTable)
        .update(updated.toJson())
        .eq('id', group.id);

    return updated;
  }

  /// Supprime un groupe (le propriétaire uniquement)
  Future<bool> deleteGroup(String id) async {
    if (_userId == null) return false;

    final group = await getGroupById(id);
    if (group == null || group.ownerId != _userId) return false;

    // Supprimer les membres
    await _supabase
        .from(_membersTable)
        .delete()
        .eq('family_id', id);

    // Supprimer le groupe
    await _supabase
        .from(_groupsTable)
        .delete()
        .eq('id', id);

    return true;
  }

  // ==================== MEMBRES ====================

  /// Récupère les membres d'un groupe
  Future<List<FamilyMember>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from(_membersTable)
        .select()
        .eq('family_id', groupId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Invite un membre par email
  Future<FamilyMember?> inviteMember({
    required String familyId,
    required String email,
    FamilyRole role = FamilyRole.member,
    double? personalBudget,
  }) async {
    if (_userId == null) return null;

    // Vérifier les permissions
    final canManage = await _canManageGroup(familyId);
    if (!canManage) return null;

    // Vérifier si l'email n'est pas déjà membre
    final existing = await _supabase
        .from(_membersTable)
        .select()
        .eq('family_id', familyId)
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      throw FamilyException('Cet email est déjà membre du groupe');
    }

    // Créer l'invitation
    return _addMember(
      familyId: familyId,
      email: email,
      role: role,
      personalBudget: personalBudget,
    );
  }

  /// Ajoute un membre au groupe
  Future<FamilyMember?> _addMember({
    required String familyId,
    String? userId,
    String? email,
    FamilyRole role = FamilyRole.member,
    InvitationStatus status = InvitationStatus.pending,
    double? personalBudget,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final member = FamilyMember(
      id: id,
      familyId: familyId,
      userId: userId ?? '',
      email: email,
      role: role,
      invitationStatus: status,
      personalBudget: personalBudget,
      joinedAt: status == InvitationStatus.accepted ? now : null,
      createdAt: now,
      updatedAt: now,
    );

    await _supabase.from(_membersTable).insert(member.toJson());
    return member;
  }

  /// Accepte une invitation
  Future<bool> acceptInvitation(String memberId) async {
    if (_userId == null) return false;

    await _supabase
        .from(_membersTable)
        .update({
          'user_id': _userId,
          'invitation_status': 'accepted',
          'joined_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId);

    return true;
  }

  /// Refuse une invitation
  Future<bool> declineInvitation(String memberId) async {
    await _supabase
        .from(_membersTable)
        .update({
          'invitation_status': 'declined',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', memberId);

    return true;
  }

  /// Met à jour un membre
  Future<FamilyMember?> updateMember(FamilyMember member) async {
    if (_userId == null) return null;

    final canManage = await _canManageGroup(member.familyId);
    if (!canManage) return null;

    final updated = member.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from(_membersTable)
        .update(updated.toJson())
        .eq('id', member.id);

    return updated;
  }

  /// Retire un membre du groupe
  Future<bool> removeMember(String memberId) async {
    if (_userId == null) return false;

    final member = await _getMemberById(memberId);
    if (member == null) return false;

    // Vérifier les permissions
    final canManage = await _canManageGroup(member.familyId);
    if (!canManage && member.userId != _userId) return false;

    // Ne pas permettre de retirer le propriétaire
    if (member.role == FamilyRole.owner) return false;

    await _supabase
        .from(_membersTable)
        .delete()
        .eq('id', memberId);

    return true;
  }

  /// Quitter un groupe
  Future<bool> leaveGroup(String groupId) async {
    if (_userId == null) return false;

    final member = await _getMemberByUserId(groupId, _userId!);
    if (member == null) return false;

    // Le propriétaire ne peut pas quitter sans transférer
    if (member.role == FamilyRole.owner) {
      throw FamilyException('Le propriétaire doit transférer la propriété avant de quitter');
    }

    await _supabase
        .from(_membersTable)
        .delete()
        .eq('family_id', groupId)
        .eq('user_id', _userId!);

    return true;
  }

  /// Transfère la propriété du groupe
  Future<bool> transferOwnership(String groupId, String newOwnerId) async {
    if (_userId == null) return false;

    final group = await getGroupById(groupId);
    if (group == null || group.ownerId != _userId) return false;

    // Mettre à jour l'ancien propriétaire
    await _supabase
        .from(_membersTable)
        .update({'role': FamilyRole.admin.value})
        .eq('family_id', groupId)
        .eq('user_id', _userId!);

    // Mettre à jour le nouveau propriétaire
    await _supabase
        .from(_membersTable)
        .update({'role': FamilyRole.owner.value})
        .eq('family_id', groupId)
        .eq('user_id', newOwnerId);

    // Mettre à jour le groupe
    await _supabase
        .from(_groupsTable)
        .update({
          'owner_id': newOwnerId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', groupId);

    return true;
  }

  // ==================== INVITATIONS EN ATTENTE ====================

  /// Récupère les invitations en attente pour l'utilisateur
  Future<List<FamilyMember>> getPendingInvitations() async {
    if (_userEmail == null) return [];

    final response = await _supabase
        .from(_membersTable)
        .select('*, family:$_groupsTable(*)')
        .eq('email', _userEmail!)
        .eq('invitation_status', 'pending');

    return (response as List)
        .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== DÉPENSES PARTAGÉES ====================

  /// Partage une dépense avec le groupe
  Future<bool> shareExpense({
    required String expenseId,
    required String familyId,
    String? note,
  }) async {
    if (_userId == null) return false;

    await _supabase.from(_sharedExpensesTable).insert({
      'id': const Uuid().v4(),
      'expense_id': expenseId,
      'family_id': familyId,
      'shared_by': _userId,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  /// Récupère les dépenses partagées d'un groupe
  Future<List<SharedExpense>> getSharedExpenses(
    String familyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from(_sharedExpensesTable)
        .select('*, expense:expenses(*), shared_by_user:profiles!shared_by(*)')
        .eq('family_id', familyId);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => SharedExpense.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== STATISTIQUES FAMILIALES ====================

  /// Calcule les statistiques d'un groupe
  Future<FamilyStats> getGroupStats(
    String familyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sharedExpenses = await getSharedExpenses(
      familyId,
      startDate: startDate,
      endDate: endDate,
    );

    final group = await getGroupById(familyId);

    // Calculer les totaux
    double totalExpenses = 0;
    final expensesByMember = <String, double>{};
    final expensesByCategory = <String, double>{};

    for (final shared in sharedExpenses) {
      if (shared.expense != null) {
        final amount = shared.expense!.amount;
        totalExpenses += amount;

        final memberId = shared.sharedBy;
        expensesByMember[memberId] = (expensesByMember[memberId] ?? 0) + amount;

        final category = shared.expense!.category?.name ?? 'Autre';
        expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
      }
    }

    final budgetUsed = group?.sharedBudget != null
        ? (totalExpenses / group!.sharedBudget! * 100)
        : 0.0;

    return FamilyStats(
      familyId: familyId,
      totalExpenses: totalExpenses,
      totalIncome: 0, // À implémenter si nécessaire
      budgetUsed: budgetUsed,
      budgetRemaining: (group?.sharedBudget ?? 0) - totalExpenses,
      expensesByMember: expensesByMember,
      expensesByCategory: expensesByCategory,
    );
  }

  // ==================== UTILITAIRES PRIVÉS ====================

  Future<bool> _canManageGroup(String groupId) async {
    if (_userId == null) return false;

    final member = await _getMemberByUserId(groupId, _userId!);
    return member?.role.canManageMembers ?? false;
  }

  Future<FamilyMember?> _getMemberById(String id) async {
    final response = await _supabase
        .from(_membersTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return FamilyMember.fromJson(response);
  }

  Future<FamilyMember?> _getMemberByUserId(String groupId, String userId) async {
    final response = await _supabase
        .from(_membersTable)
        .select()
        .eq('family_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return FamilyMember.fromJson(response);
  }
}

/// Dépense partagée
class SharedExpense {
  final String id;
  final String expenseId;
  final String familyId;
  final String sharedBy;
  final String? note;
  final DateTime createdAt;
  final Expense? expense;
  final String? sharedByName;

  const SharedExpense({
    required this.id,
    required this.expenseId,
    required this.familyId,
    required this.sharedBy,
    this.note,
    required this.createdAt,
    this.expense,
    this.sharedByName,
  });

  factory SharedExpense.fromJson(Map<String, dynamic> json) {
    return SharedExpense(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      familyId: json['family_id'] as String,
      sharedBy: json['shared_by'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expense: json['expense'] != null
          ? Expense.fromJson(json['expense'] as Map<String, dynamic>)
          : null,
      sharedByName: json['shared_by_user']?['display_name'] as String?,
    );
  }
}

/// Exception pour les erreurs de famille
class FamilyException implements Exception {
  final String message;
  FamilyException(this.message);

  @override
  String toString() => 'FamilyException: $message';
}
