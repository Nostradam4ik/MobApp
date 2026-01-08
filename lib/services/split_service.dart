import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../data/models/expense_split.dart';
import 'local_storage_service.dart';

/// Service pour gérer le partage de dépenses
class SplitService {
  SplitService._();

  static const String _splitsKey = 'expense_splits';
  static const String _contactsKey = 'split_contacts';

  // ============================================================
  // SPLITS CRUD
  // ============================================================

  /// Récupère tous les partages
  static List<ExpenseSplit> getAllSplits() {
    final jsonString = LocalStorageService.getString(_splitsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => ExpenseSplit.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde tous les partages
  static Future<void> _saveSplits(List<ExpenseSplit> splits) async {
    final jsonString = json.encode(splits.map((s) => s.toJson()).toList());
    await LocalStorageService.setString(_splitsKey, jsonString);
  }

  /// Crée un nouveau partage
  static Future<ExpenseSplit> createSplit({
    required String expenseId,
    required String userId,
    required String title,
    String? description,
    required double totalAmount,
    required SplitMode mode,
    required List<SplitParticipant> participants,
    bool includeMe = true,
    required double myShare,
  }) async {
    final split = ExpenseSplit(
      id: const Uuid().v4(),
      expenseId: expenseId,
      userId: userId,
      title: title,
      description: description,
      totalAmount: totalAmount,
      mode: mode,
      participants: participants,
      includeMe: includeMe,
      myShare: myShare,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final splits = getAllSplits();
    splits.add(split);
    await _saveSplits(splits);

    // Update contacts
    for (final participant in participants) {
      await _updateContact(participant);
    }

    return split;
  }

  /// Crée un partage égal
  static Future<ExpenseSplit> createEqualSplit({
    required String expenseId,
    required String userId,
    required String title,
    String? description,
    required double totalAmount,
    required List<String> participantNames,
    bool includeMe = true,
  }) async {
    final totalParticipants = participantNames.length + (includeMe ? 1 : 0);
    final sharePerPerson = totalAmount / totalParticipants;

    final participants = participantNames.map((name) => SplitParticipant(
          id: const Uuid().v4(),
          name: name,
          amount: sharePerPerson,
        )).toList();

    return createSplit(
      expenseId: expenseId,
      userId: userId,
      title: title,
      description: description,
      totalAmount: totalAmount,
      mode: SplitMode.equal,
      participants: participants,
      includeMe: includeMe,
      myShare: includeMe ? sharePerPerson : 0,
    );
  }

  /// Met à jour un partage
  static Future<void> updateSplit(ExpenseSplit split) async {
    final splits = getAllSplits();
    final index = splits.indexWhere((s) => s.id == split.id);

    if (index != -1) {
      splits[index] = split.copyWith(updatedAt: DateTime.now());
      await _saveSplits(splits);
    }
  }

  /// Supprime un partage
  static Future<void> deleteSplit(String id) async {
    final splits = getAllSplits();
    splits.removeWhere((s) => s.id == id);
    await _saveSplits(splits);
  }

  /// Récupère un partage par ID
  static ExpenseSplit? getSplitById(String id) {
    try {
      return getAllSplits().firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les partages pour une dépense
  static ExpenseSplit? getSplitByExpenseId(String expenseId) {
    try {
      return getAllSplits().firstWhere((s) => s.expenseId == expenseId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PAYMENTS
  // ============================================================

  /// Marque un participant comme ayant payé
  static Future<void> markParticipantPaid(
    String splitId,
    String participantId, {
    double? amount,
  }) async {
    final split = getSplitById(splitId);
    if (split == null) return;

    final updatedParticipants = split.participants.map((p) {
      if (p.id == participantId) {
        final paidAmount = amount ?? p.amount;
        final newPaidAmount = p.paidAmount + paidAmount;
        final newStatus = newPaidAmount >= p.amount
            ? SplitStatus.paid
            : SplitStatus.partiallyPaid;

        return p.copyWith(
          paidAmount: newPaidAmount,
          status: newStatus,
          paidAt: DateTime.now(),
        );
      }
      return p;
    }).toList();

    await updateSplit(split.copyWith(participants: updatedParticipants));
  }

  /// Marque tous les participants comme ayant payé
  static Future<void> markAllPaid(String splitId) async {
    final split = getSplitById(splitId);
    if (split == null) return;

    final updatedParticipants = split.participants.map((p) {
      return p.copyWith(
        paidAmount: p.amount,
        status: SplitStatus.paid,
        paidAt: DateTime.now(),
      );
    }).toList();

    await updateSplit(split.copyWith(participants: updatedParticipants));
  }

  /// Annule le paiement d'un participant
  static Future<void> cancelPayment(String splitId, String participantId) async {
    final split = getSplitById(splitId);
    if (split == null) return;

    final updatedParticipants = split.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(
          paidAmount: 0,
          status: SplitStatus.pending,
          paidAt: null,
        );
      }
      return p;
    }).toList();

    await updateSplit(split.copyWith(participants: updatedParticipants));
  }

  // ============================================================
  // CONTACTS
  // ============================================================

  /// Récupère tous les contacts
  static List<SplitContact> getAllContacts() {
    final jsonString = LocalStorageService.getString(_contactsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => SplitContact.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde les contacts
  static Future<void> _saveContacts(List<SplitContact> contacts) async {
    final jsonString = json.encode(contacts.map((c) => c.toJson()).toList());
    await LocalStorageService.setString(_contactsKey, jsonString);
  }

  /// Met à jour ou crée un contact
  static Future<void> _updateContact(SplitParticipant participant) async {
    final contacts = getAllContacts();
    final existingIndex = contacts.indexWhere(
      (c) => c.name.toLowerCase() == participant.name.toLowerCase(),
    );

    if (existingIndex != -1) {
      contacts[existingIndex] = contacts[existingIndex].copyWith(
        splitCount: contacts[existingIndex].splitCount + 1,
        lastUsed: DateTime.now(),
        email: participant.email ?? contacts[existingIndex].email,
        phone: participant.phone ?? contacts[existingIndex].phone,
      );
    } else {
      contacts.add(SplitContact(
        id: const Uuid().v4(),
        name: participant.name,
        email: participant.email,
        phone: participant.phone,
        splitCount: 1,
        lastUsed: DateTime.now(),
      ));
    }

    await _saveContacts(contacts);
  }

  /// Récupère les contacts fréquents
  static List<SplitContact> getFrequentContacts({int limit = 5}) {
    final contacts = getAllContacts();
    contacts.sort((a, b) => b.splitCount.compareTo(a.splitCount));
    return contacts.take(limit).toList();
  }

  /// Supprime un contact
  static Future<void> deleteContact(String id) async {
    final contacts = getAllContacts();
    contacts.removeWhere((c) => c.id == id);
    await _saveContacts(contacts);
  }

  // ============================================================
  // QUERIES
  // ============================================================

  /// Récupère les partages en attente
  static List<ExpenseSplit> getPendingSplits() {
    return getAllSplits()
        .where((s) => !s.isFullySettled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Récupère les partages réglés
  static List<ExpenseSplit> getSettledSplits() {
    return getAllSplits()
        .where((s) => s.isFullySettled)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Calcule le total à recevoir
  static double getTotalToReceive() {
    return getPendingSplits().fold(0.0, (sum, s) => sum + s.totalRemaining);
  }

  /// Récupère les statistiques
  static Map<String, dynamic> getStats() {
    final all = getAllSplits();
    final pending = all.where((s) => !s.isFullySettled).toList();
    final settled = all.where((s) => s.isFullySettled).toList();

    return {
      'total': all.length,
      'pending': pending.length,
      'settled': settled.length,
      'totalToReceive': pending.fold(0.0, (sum, s) => sum + s.totalRemaining),
      'totalReceived': all.fold(0.0, (sum, s) => sum + s.totalReceived),
    };
  }
}
