import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/expense_split.dart';

void main() {
  group('SplitStatus', () {
    test('should have correct labels', () {
      expect(SplitStatus.pending.label, 'En attente');
      expect(SplitStatus.partiallyPaid.label, 'Partiellement payé');
      expect(SplitStatus.paid.label, 'Payé');
      expect(SplitStatus.cancelled.label, 'Annulé');
    });

    test('should have emojis', () {
      expect(SplitStatus.pending.emoji, '⏳');
      expect(SplitStatus.partiallyPaid.emoji, '💰');
      expect(SplitStatus.paid.emoji, '✅');
      expect(SplitStatus.cancelled.emoji, '❌');
    });
  });

  group('SplitMode', () {
    test('should have correct labels', () {
      expect(SplitMode.equal.label, 'Parts égales');
      expect(SplitMode.percentage.label, 'Par pourcentage');
      expect(SplitMode.exact.label, 'Montants exacts');
      expect(SplitMode.shares.label, 'Par parts');
    });

    test('should have icons', () {
      expect(SplitMode.equal.icon, '⚖️');
      expect(SplitMode.percentage.icon, '📊');
      expect(SplitMode.exact.icon, '💵');
      expect(SplitMode.shares.icon, '🍕');
    });
  });

  group('SplitParticipant', () {
    final testParticipant = SplitParticipant(
      id: 'part-123',
      name: 'Alice',
      email: 'alice@example.com',
      phone: '0612345678',
      amount: 50.0,
      paidAmount: 20.0,
      status: SplitStatus.partiallyPaid,
    );

    group('fromJson', () {
      test('should create SplitParticipant from valid JSON', () {
        final json = {
          'id': 'part-123',
          'name': 'Alice',
          'email': 'alice@example.com',
          'phone': '0612345678',
          'amount': 50.0,
          'paid_amount': 20.0,
          'status': 'partiallyPaid',
          'paid_at': '2024-01-15T10:00:00.000Z',
        };

        final participant = SplitParticipant.fromJson(json);

        expect(participant.id, 'part-123');
        expect(participant.name, 'Alice');
        expect(participant.email, 'alice@example.com');
        expect(participant.amount, 50.0);
        expect(participant.paidAmount, 20.0);
        expect(participant.status, SplitStatus.partiallyPaid);
        expect(participant.paidAt, isNotNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'part-123',
          'name': 'Bob',
          'amount': 30.0,
        };

        final participant = SplitParticipant.fromJson(json);

        expect(participant.email, isNull);
        expect(participant.phone, isNull);
        expect(participant.paidAmount, 0.0);
        expect(participant.status, SplitStatus.pending);
        expect(participant.paidAt, isNull);
      });

      test('should default to pending for unknown status', () {
        final json = {
          'id': 'part-123',
          'name': 'Test',
          'amount': 10.0,
          'status': 'unknown_status',
        };

        final participant = SplitParticipant.fromJson(json);
        expect(participant.status, SplitStatus.pending);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final json = testParticipant.toJson();

        expect(json['id'], 'part-123');
        expect(json['name'], 'Alice');
        expect(json['email'], 'alice@example.com');
        expect(json['amount'], 50.0);
        expect(json['paid_amount'], 20.0);
        expect(json['status'], 'partiallyPaid');
      });
    });

    group('remainingAmount', () {
      test('should calculate remaining correctly', () {
        expect(testParticipant.remainingAmount, 30.0); // 50 - 20
      });

      test('should clamp to zero when overpaid', () {
        final overpaid = testParticipant.copyWith(paidAmount: 60.0);
        expect(overpaid.remainingAmount, 0.0);
      });
    });

    group('isFullyPaid', () {
      test('should return false when not fully paid', () {
        expect(testParticipant.isFullyPaid, false);
      });

      test('should return true when fully paid', () {
        final paid = testParticipant.copyWith(paidAmount: 50.0);
        expect(paid.isFullyPaid, true);
      });

      test('should return true when overpaid', () {
        final overpaid = testParticipant.copyWith(paidAmount: 60.0);
        expect(overpaid.isFullyPaid, true);
      });
    });

    group('paidPercentage', () {
      test('should calculate percentage correctly', () {
        expect(testParticipant.paidPercentage, 0.4); // 20/50
      });

      test('should clamp to 1 when overpaid', () {
        final overpaid = testParticipant.copyWith(paidAmount: 100.0);
        expect(overpaid.paidPercentage, 1.0);
      });

      test('should return 0 when amount is 0', () {
        final zeroAmount = testParticipant.copyWith(amount: 0.0);
        expect(zeroAmount.paidPercentage, 0.0);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final copy = testParticipant.copyWith(
          name: 'Updated Name',
          paidAmount: 50.0,
          status: SplitStatus.paid,
        );

        expect(copy.name, 'Updated Name');
        expect(copy.paidAmount, 50.0);
        expect(copy.status, SplitStatus.paid);
        expect(copy.id, testParticipant.id);
      });
    });
  });

  group('ExpenseSplit', () {
    final now = DateTime.now();
    final participants = [
      SplitParticipant(
        id: 'p1',
        name: 'Alice',
        amount: 25.0,
        paidAmount: 25.0,
        status: SplitStatus.paid,
      ),
      SplitParticipant(
        id: 'p2',
        name: 'Bob',
        amount: 25.0,
        paidAmount: 10.0,
        status: SplitStatus.partiallyPaid,
      ),
    ];

    final testSplit = ExpenseSplit(
      id: 'split-123',
      expenseId: 'exp-456',
      userId: 'user-789',
      title: 'Dîner restaurant',
      description: 'Soirée anniversaire',
      totalAmount: 100.0,
      mode: SplitMode.equal,
      participants: participants,
      includeMe: true,
      myShare: 50.0,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('should create ExpenseSplit from valid JSON', () {
        final json = {
          'id': 'split-123',
          'expense_id': 'exp-456',
          'user_id': 'user-789',
          'title': 'Dîner restaurant',
          'description': 'Test',
          'total_amount': 100.0,
          'mode': 'equal',
          'participants': [
            {'id': 'p1', 'name': 'Alice', 'amount': 25.0},
          ],
          'include_me': true,
          'my_share': 50.0,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final split = ExpenseSplit.fromJson(json);

        expect(split.id, 'split-123');
        expect(split.title, 'Dîner restaurant');
        expect(split.totalAmount, 100.0);
        expect(split.mode, SplitMode.equal);
        expect(split.participants.length, 1);
        expect(split.myShare, 50.0);
      });

      test('should default to equal mode for unknown', () {
        final json = {
          'id': 'split-1',
          'expense_id': 'exp-1',
          'user_id': 'user-1',
          'title': 'Test',
          'total_amount': 50.0,
          'mode': 'unknown_mode',
          'participants': [],
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final split = ExpenseSplit.fromJson(json);
        expect(split.mode, SplitMode.equal);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final json = testSplit.toJson();

        expect(json['id'], 'split-123');
        expect(json['expense_id'], 'exp-456');
        expect(json['title'], 'Dîner restaurant');
        expect(json['total_amount'], 100.0);
        expect(json['mode'], 'equal');
        expect(json['participants'], isA<List>());
        expect((json['participants'] as List).length, 2);
        expect(json['include_me'], true);
        expect(json['my_share'], 50.0);
      });
    });

    group('calculated properties', () {
      test('totalToReceive should sum participant amounts', () {
        expect(testSplit.totalToReceive, 50.0); // 25 + 25
      });

      test('totalReceived should sum paid amounts', () {
        expect(testSplit.totalReceived, 35.0); // 25 + 10
      });

      test('totalRemaining should calculate difference', () {
        expect(testSplit.totalRemaining, 15.0); // 50 - 35
      });

      test('recoveryPercentage should calculate correctly', () {
        expect(testSplit.recoveryPercentage, 0.7); // 35/50
      });

      test('paidCount should count fully paid participants', () {
        expect(testSplit.paidCount, 1); // Only Alice
      });

      test('participantCount should return total participants', () {
        expect(testSplit.participantCount, 2);
      });

      test('isFullySettled should return false when not all paid', () {
        expect(testSplit.isFullySettled, false);
      });

      test('isFullySettled should return true when all paid', () {
        final allPaid = ExpenseSplit(
          id: 'split-1',
          expenseId: 'exp-1',
          userId: 'user-1',
          title: 'Test',
          totalAmount: 100.0,
          mode: SplitMode.equal,
          participants: [
            SplitParticipant(
              id: 'p1',
              name: 'Alice',
              amount: 50.0,
              paidAmount: 50.0,
            ),
          ],
          myShare: 50.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(allPaid.isFullySettled, true);
      });
    });

    group('overallStatus', () {
      test('should return paid when fully settled', () {
        final allPaid = testSplit.copyWith(
          participants: [
            SplitParticipant(id: 'p1', name: 'A', amount: 25.0, paidAmount: 25.0),
            SplitParticipant(id: 'p2', name: 'B', amount: 25.0, paidAmount: 25.0),
          ],
        );

        expect(allPaid.overallStatus, SplitStatus.paid);
      });

      test('should return partiallyPaid when some received', () {
        expect(testSplit.overallStatus, SplitStatus.partiallyPaid);
      });

      test('should return pending when nothing received', () {
        final nothingPaid = testSplit.copyWith(
          participants: [
            SplitParticipant(id: 'p1', name: 'A', amount: 25.0, paidAmount: 0.0),
            SplitParticipant(id: 'p2', name: 'B', amount: 25.0, paidAmount: 0.0),
          ],
        );

        expect(nothingPaid.overallStatus, SplitStatus.pending);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final copy = testSplit.copyWith(
          title: 'Updated Title',
          totalAmount: 200.0,
        );

        expect(copy.title, 'Updated Title');
        expect(copy.totalAmount, 200.0);
        expect(copy.id, testSplit.id);
        expect(copy.participants.length, testSplit.participants.length);
      });
    });
  });

  group('SplitContact', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('should create SplitContact from JSON', () {
        final json = {
          'id': 'contact-123',
          'name': 'Jean Dupont',
          'email': 'jean@example.com',
          'phone': '0612345678',
          'split_count': 5,
          'last_used': '2024-01-15T10:00:00.000Z',
        };

        final contact = SplitContact.fromJson(json);

        expect(contact.id, 'contact-123');
        expect(contact.name, 'Jean Dupont');
        expect(contact.email, 'jean@example.com');
        expect(contact.phone, '0612345678');
        expect(contact.splitCount, 5);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'contact-123',
          'name': 'Simple',
          'last_used': '2024-01-15T10:00:00.000Z',
        };

        final contact = SplitContact.fromJson(json);

        expect(contact.email, isNull);
        expect(contact.phone, isNull);
        expect(contact.splitCount, 0);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final contact = SplitContact(
          id: 'contact-1',
          name: 'Test',
          email: 'test@example.com',
          splitCount: 10,
          lastUsed: now,
        );

        final json = contact.toJson();

        expect(json['id'], 'contact-1');
        expect(json['name'], 'Test');
        expect(json['email'], 'test@example.com');
        expect(json['split_count'], 10);
        expect(json['last_used'], isA<String>());
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final contact = SplitContact(
          id: 'contact-1',
          name: 'Original',
          splitCount: 5,
          lastUsed: now,
        );

        final copy = contact.copyWith(
          name: 'Updated',
          splitCount: 10,
        );

        expect(copy.name, 'Updated');
        expect(copy.splitCount, 10);
        expect(copy.id, contact.id);
      });
    });

    group('equality', () {
      test('should be equal for same id and name', () {
        final c1 = SplitContact(id: 'c1', name: 'Test', lastUsed: now);
        final c2 = SplitContact(
          id: 'c1',
          name: 'Test',
          email: 'diff@example.com',
          lastUsed: now.add(const Duration(days: 1)),
        );

        expect(c1, equals(c2));
      });
    });
  });
}
