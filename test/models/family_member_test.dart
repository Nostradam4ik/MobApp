import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/family_member.dart';

void main() {
  group('FamilyRole', () {
    test('should have correct values', () {
      expect(FamilyRole.owner.value, 'owner');
      expect(FamilyRole.admin.value, 'admin');
      expect(FamilyRole.member.value, 'member');
      expect(FamilyRole.viewer.value, 'viewer');
    });

    test('should have correct labels', () {
      expect(FamilyRole.owner.label, 'Propriétaire');
      expect(FamilyRole.admin.label, 'Administrateur');
      expect(FamilyRole.member.label, 'Membre');
      expect(FamilyRole.viewer.label, 'Lecteur');
    });

    test('fromString should return correct role', () {
      expect(FamilyRole.fromString('owner'), FamilyRole.owner);
      expect(FamilyRole.fromString('admin'), FamilyRole.admin);
      expect(FamilyRole.fromString('member'), FamilyRole.member);
      expect(FamilyRole.fromString('viewer'), FamilyRole.viewer);
    });

    test('fromString should return viewer for unknown', () {
      expect(FamilyRole.fromString('unknown'), FamilyRole.viewer);
      expect(FamilyRole.fromString(''), FamilyRole.viewer);
    });

    group('permissions', () {
      test('canEdit should be true for owner, admin, member', () {
        expect(FamilyRole.owner.canEdit, true);
        expect(FamilyRole.admin.canEdit, true);
        expect(FamilyRole.member.canEdit, true);
        expect(FamilyRole.viewer.canEdit, false);
      });

      test('canManageMembers should be true for owner and admin only', () {
        expect(FamilyRole.owner.canManageMembers, true);
        expect(FamilyRole.admin.canManageMembers, true);
        expect(FamilyRole.member.canManageMembers, false);
        expect(FamilyRole.viewer.canManageMembers, false);
      });

      test('canDelete should be true for owner only', () {
        expect(FamilyRole.owner.canDelete, true);
        expect(FamilyRole.admin.canDelete, false);
        expect(FamilyRole.member.canDelete, false);
        expect(FamilyRole.viewer.canDelete, false);
      });
    });
  });

  group('InvitationStatus', () {
    test('should have correct values', () {
      expect(InvitationStatus.pending.value, 'pending');
      expect(InvitationStatus.accepted.value, 'accepted');
      expect(InvitationStatus.declined.value, 'declined');
      expect(InvitationStatus.expired.value, 'expired');
    });

    test('should have correct labels', () {
      expect(InvitationStatus.pending.label, 'En attente');
      expect(InvitationStatus.accepted.label, 'Acceptée');
      expect(InvitationStatus.declined.label, 'Refusée');
      expect(InvitationStatus.expired.label, 'Expirée');
    });

    test('fromString should return correct status', () {
      expect(InvitationStatus.fromString('pending'), InvitationStatus.pending);
      expect(InvitationStatus.fromString('accepted'), InvitationStatus.accepted);
      expect(InvitationStatus.fromString('declined'), InvitationStatus.declined);
      expect(InvitationStatus.fromString('expired'), InvitationStatus.expired);
    });

    test('fromString should return pending for unknown', () {
      expect(InvitationStatus.fromString('unknown'), InvitationStatus.pending);
    });
  });

  group('FamilyGroup', () {
    final now = DateTime.now();
    final testGroup = FamilyGroup(
      id: 'family-123',
      name: 'Famille Dupont',
      ownerId: 'user-456',
      description: 'Notre groupe familial',
      currency: 'EUR',
      sharedBudget: 2000.0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create FamilyGroup from valid JSON', () {
        final json = {
          'id': 'family-123',
          'name': 'Famille Dupont',
          'owner_id': 'user-456',
          'description': 'Notre groupe familial',
          'currency': 'EUR',
          'shared_budget': 2000.0,
          'is_active': true,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final group = FamilyGroup.fromJson(json);

        expect(group.id, 'family-123');
        expect(group.name, 'Famille Dupont');
        expect(group.ownerId, 'user-456');
        expect(group.description, 'Notre groupe familial');
        expect(group.currency, 'EUR');
        expect(group.sharedBudget, 2000.0);
        expect(group.isActive, true);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'family-123',
          'name': 'Test',
          'owner_id': 'user-1',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final group = FamilyGroup.fromJson(json);

        expect(group.description, isNull);
        expect(group.currency, 'EUR');
        expect(group.sharedBudget, isNull);
        expect(group.isActive, true);
        expect(group.members, isNull);
      });

      test('should parse members if provided', () {
        final json = {
          'id': 'family-123',
          'name': 'Test',
          'owner_id': 'user-1',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
          'members': [
            {
              'id': 'member-1',
              'family_id': 'family-123',
              'user_id': 'user-1',
              'created_at': '2024-01-15T10:00:00.000Z',
              'updated_at': '2024-01-15T10:00:00.000Z',
            },
          ],
        };

        final group = FamilyGroup.fromJson(json);

        expect(group.members, isNotNull);
        expect(group.members!.length, 1);
      });
    });

    group('toJson', () {
      test('should convert FamilyGroup to JSON', () {
        final json = testGroup.toJson();

        expect(json['id'], 'family-123');
        expect(json['name'], 'Famille Dupont');
        expect(json['owner_id'], 'user-456');
        expect(json['description'], 'Notre groupe familial');
        expect(json['currency'], 'EUR');
        expect(json['shared_budget'], 2000.0);
        expect(json['is_active'], true);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testGroup.copyWith(name: 'Nouveau nom');

        expect(copy.name, 'Nouveau nom');
        expect(copy.id, testGroup.id);
      });

      test('should create copy with updated budget', () {
        final copy = testGroup.copyWith(sharedBudget: 3000.0);

        expect(copy.sharedBudget, 3000.0);
        expect(copy.name, testGroup.name);
      });
    });

    group('memberCount', () {
      test('should return 0 when no members', () {
        expect(testGroup.memberCount, 0);
      });

      test('should return correct count when members present', () {
        final groupWithMembers = testGroup.copyWith(
          members: [
            FamilyMember(
              id: 'member-1',
              familyId: 'family-123',
              userId: 'user-1',
              createdAt: now,
              updatedAt: now,
            ),
            FamilyMember(
              id: 'member-2',
              familyId: 'family-123',
              userId: 'user-2',
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        expect(groupWithMembers.memberCount, 2);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final group1 = FamilyGroup(
          id: 'family-1',
          name: 'Test',
          ownerId: 'user-1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final group2 = FamilyGroup(
          id: 'family-1',
          name: 'Test',
          ownerId: 'user-1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(group1, equals(group2));
      });
    });
  });

  group('FamilyMember', () {
    final now = DateTime.now();
    final testMember = FamilyMember(
      id: 'member-123',
      familyId: 'family-456',
      userId: 'user-789',
      email: 'jean@example.com',
      displayName: 'Jean Dupont',
      avatarUrl: 'https://example.com/avatar.jpg',
      role: FamilyRole.member,
      invitationStatus: InvitationStatus.accepted,
      personalBudget: 500.0,
      canViewAllExpenses: true,
      joinedAt: DateTime(2024, 1, 15),
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create FamilyMember from valid JSON', () {
        final json = {
          'id': 'member-123',
          'family_id': 'family-456',
          'user_id': 'user-789',
          'email': 'jean@example.com',
          'display_name': 'Jean Dupont',
          'avatar_url': 'https://example.com/avatar.jpg',
          'role': 'admin',
          'invitation_status': 'accepted',
          'personal_budget': 500.0,
          'can_view_all_expenses': true,
          'joined_at': '2024-01-15T10:00:00.000Z',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final member = FamilyMember.fromJson(json);

        expect(member.id, 'member-123');
        expect(member.familyId, 'family-456');
        expect(member.userId, 'user-789');
        expect(member.email, 'jean@example.com');
        expect(member.displayName, 'Jean Dupont');
        expect(member.avatarUrl, 'https://example.com/avatar.jpg');
        expect(member.role, FamilyRole.admin);
        expect(member.invitationStatus, InvitationStatus.accepted);
        expect(member.personalBudget, 500.0);
        expect(member.canViewAllExpenses, true);
        expect(member.joinedAt, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'member-123',
          'family_id': 'family-456',
          'user_id': 'user-789',
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final member = FamilyMember.fromJson(json);

        expect(member.email, isNull);
        expect(member.displayName, isNull);
        expect(member.avatarUrl, isNull);
        expect(member.role, FamilyRole.member);
        expect(member.invitationStatus, InvitationStatus.pending);
        expect(member.personalBudget, isNull);
        expect(member.canViewAllExpenses, false);
        expect(member.joinedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert FamilyMember to JSON', () {
        final json = testMember.toJson();

        expect(json['id'], 'member-123');
        expect(json['family_id'], 'family-456');
        expect(json['user_id'], 'user-789');
        expect(json['email'], 'jean@example.com');
        expect(json['display_name'], 'Jean Dupont');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
        expect(json['role'], 'member');
        expect(json['invitation_status'], 'accepted');
        expect(json['personal_budget'], 500.0);
        expect(json['can_view_all_expenses'], true);
        expect(json['joined_at'], isA<String>());
      });

      test('should handle null joinedAt', () {
        final noJoin = FamilyMember(
          id: 'member-1',
          familyId: 'family-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final json = noJoin.toJson();
        expect(json['joined_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated role', () {
        final copy = testMember.copyWith(role: FamilyRole.admin);

        expect(copy.role, FamilyRole.admin);
        expect(copy.id, testMember.id);
      });

      test('should create copy with updated status', () {
        final copy = testMember.copyWith(invitationStatus: InvitationStatus.pending);

        expect(copy.invitationStatus, InvitationStatus.pending);
      });
    });

    group('name getter', () {
      test('should return displayName when available', () {
        expect(testMember.name, 'Jean Dupont');
      });

      test('should return email when no displayName', () {
        final noDisplay = FamilyMember(
          id: 'member-1',
          familyId: 'family-1',
          userId: 'user-1',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        );

        expect(noDisplay.name, 'test@example.com');
      });

      test('should return Membre when no displayName or email', () {
        final noInfo = FamilyMember(
          id: 'member-1',
          familyId: 'family-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(noInfo.name, 'Membre');
      });
    });

    group('status getters', () {
      test('isAccepted should return true when accepted', () {
        expect(testMember.isAccepted, true);
      });

      test('isAccepted should return false when pending', () {
        final pending = testMember.copyWith(invitationStatus: InvitationStatus.pending);
        expect(pending.isAccepted, false);
      });

      test('isPending should return true when pending', () {
        final pending = testMember.copyWith(invitationStatus: InvitationStatus.pending);
        expect(pending.isPending, true);
      });

      test('isPending should return false when accepted', () {
        expect(testMember.isPending, false);
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final member1 = FamilyMember(
          id: 'member-1',
          familyId: 'family-1',
          userId: 'user-1',
          role: FamilyRole.member,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final member2 = FamilyMember(
          id: 'member-1',
          familyId: 'family-1',
          userId: 'user-1',
          role: FamilyRole.member,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(member1, equals(member2));
      });
    });
  });

  group('FamilyStats', () {
    test('should create with all fields', () {
      const stats = FamilyStats(
        familyId: 'family-123',
        totalExpenses: 1500.0,
        totalIncome: 5000.0,
        budgetUsed: 1500.0,
        budgetRemaining: 500.0,
        expensesByMember: {'user-1': 1000.0, 'user-2': 500.0},
        expensesByCategory: {'food': 800.0, 'transport': 700.0},
      );

      expect(stats.familyId, 'family-123');
      expect(stats.totalExpenses, 1500.0);
      expect(stats.totalIncome, 5000.0);
      expect(stats.budgetUsed, 1500.0);
      expect(stats.budgetRemaining, 500.0);
      expect(stats.expensesByMember.length, 2);
      expect(stats.expensesByCategory.length, 2);
    });
  });
}
