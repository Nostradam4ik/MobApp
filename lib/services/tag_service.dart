import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/tag.dart';
import '../data/models/expense.dart';

/// Service de gestion des tags personnalisés
class TagService {
  static const String _tagsKey = 'custom_tags';
  static const String _expenseTagsKey = 'expense_tags';

  static SharedPreferences? _prefs;
  static List<Tag> _tags = [];
  static List<ExpenseTag> _expenseTags = [];

  /// Initialise le service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTags();
    await _loadExpenseTags();
  }

  /// Charge les tags depuis le stockage
  static Future<void> _loadTags() async {
    final data = _prefs?.getString(_tagsKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _tags = jsonList.map((json) => Tag.fromJson(json)).toList();
    }
  }

  /// Charge les associations dépense-tag
  static Future<void> _loadExpenseTags() async {
    final data = _prefs?.getString(_expenseTagsKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _expenseTags = jsonList.map((json) => ExpenseTag.fromJson(json)).toList();
    }
  }

  /// Sauvegarde les tags
  static Future<void> _saveTags() async {
    final data = jsonEncode(_tags.map((t) => t.toJson()).toList());
    await _prefs?.setString(_tagsKey, data);
  }

  /// Sauvegarde les associations
  static Future<void> _saveExpenseTags() async {
    final data = jsonEncode(_expenseTags.map((et) => et.toJson()).toList());
    await _prefs?.setString(_expenseTagsKey, data);
  }

  // ==================== CRUD Tags ====================

  /// Obtient tous les tags
  static List<Tag> getAllTags() {
    return List.unmodifiable(_tags);
  }

  /// Obtient les tags triés par utilisation
  static List<Tag> getTagsByUsage() {
    final sorted = List<Tag>.from(_tags);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted;
  }

  /// Obtient un tag par son ID
  static Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Recherche des tags par nom
  static List<Tag> searchTags(String query) {
    if (query.isEmpty) return getAllTags();
    final lowerQuery = query.toLowerCase();
    return _tags.where((t) => t.name.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Crée un nouveau tag
  static Future<Tag> createTag({
    required String name,
    required String color,
    String? icon,
  }) async {
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      usageCount: 0,
    );

    _tags.add(tag);
    await _saveTags();
    return tag;
  }

  /// Met à jour un tag
  static Future<Tag?> updateTag(
    String id, {
    String? name,
    String? color,
    String? icon,
  }) async {
    final index = _tags.indexWhere((t) => t.id == id);
    if (index == -1) return null;

    final updated = _tags[index].copyWith(
      name: name,
      color: color,
      icon: icon,
    );

    _tags[index] = updated;
    await _saveTags();
    return updated;
  }

  /// Supprime un tag et ses associations
  static Future<bool> deleteTag(String id) async {
    final removed = _tags.removeWhere((t) => t.id == id);
    _expenseTags.removeWhere((et) => et.tagId == id);

    await _saveTags();
    await _saveExpenseTags();
    return true;
  }

  /// Ajoute les tags suggérés
  static Future<void> addSuggestedTags() async {
    for (final suggested in Tag.suggestedTags) {
      // Vérifie si un tag avec ce nom existe déjà
      final exists = _tags.any(
        (t) => t.name.toLowerCase() == suggested.name.toLowerCase(),
      );
      if (!exists) {
        await createTag(
          name: suggested.name,
          color: suggested.color,
          icon: suggested.icon,
        );
      }
    }
  }

  // ==================== Association Dépense-Tag ====================

  /// Obtient les tags d'une dépense
  static List<Tag> getTagsForExpense(String expenseId) {
    final tagIds = _expenseTags
        .where((et) => et.expenseId == expenseId)
        .map((et) => et.tagId)
        .toList();

    return _tags.where((t) => tagIds.contains(t.id)).toList();
  }

  /// Obtient les IDs de tags d'une dépense
  static List<String> getTagIdsForExpense(String expenseId) {
    return _expenseTags
        .where((et) => et.expenseId == expenseId)
        .map((et) => et.tagId)
        .toList();
  }

  /// Obtient les dépenses ayant un tag spécifique
  static List<String> getExpenseIdsForTag(String tagId) {
    return _expenseTags
        .where((et) => et.tagId == tagId)
        .map((et) => et.expenseId)
        .toList();
  }

  /// Ajoute un tag à une dépense
  static Future<void> addTagToExpense(String expenseId, String tagId) async {
    // Vérifie si l'association existe déjà
    final exists = _expenseTags.any(
      (et) => et.expenseId == expenseId && et.tagId == tagId,
    );
    if (exists) return;

    _expenseTags.add(ExpenseTag(expenseId: expenseId, tagId: tagId));

    // Met à jour le compteur d'utilisation
    final tagIndex = _tags.indexWhere((t) => t.id == tagId);
    if (tagIndex != -1) {
      _tags[tagIndex] = _tags[tagIndex].incrementUsage();
      await _saveTags();
    }

    await _saveExpenseTags();
  }

  /// Retire un tag d'une dépense
  static Future<void> removeTagFromExpense(String expenseId, String tagId) async {
    _expenseTags.removeWhere(
      (et) => et.expenseId == expenseId && et.tagId == tagId,
    );

    // Met à jour le compteur d'utilisation
    final tagIndex = _tags.indexWhere((t) => t.id == tagId);
    if (tagIndex != -1) {
      _tags[tagIndex] = _tags[tagIndex].decrementUsage();
      await _saveTags();
    }

    await _saveExpenseTags();
  }

  /// Met à jour tous les tags d'une dépense
  static Future<void> setTagsForExpense(String expenseId, List<String> tagIds) async {
    // Retire les anciens tags
    final oldTagIds = getTagIdsForExpense(expenseId);
    for (final tagId in oldTagIds) {
      if (!tagIds.contains(tagId)) {
        await removeTagFromExpense(expenseId, tagId);
      }
    }

    // Ajoute les nouveaux tags
    for (final tagId in tagIds) {
      if (!oldTagIds.contains(tagId)) {
        await addTagToExpense(expenseId, tagId);
      }
    }
  }

  /// Supprime toutes les associations d'une dépense
  static Future<void> removeAllTagsFromExpense(String expenseId) async {
    final tagIds = getTagIdsForExpense(expenseId);
    for (final tagId in tagIds) {
      await removeTagFromExpense(expenseId, tagId);
    }
  }

  // ==================== Statistiques ====================

  /// Obtient les statistiques d'un tag
  static TagStats getTagStats(String tagId, List<Expense> expenses) {
    final tag = getTagById(tagId);
    if (tag == null) {
      return TagStats(
        tag: Tag(id: '', name: 'Unknown', color: '#CCCCCC', createdAt: DateTime.now()),
        expenseCount: 0,
        totalAmount: 0,
        averageAmount: 0,
      );
    }

    final expenseIds = getExpenseIdsForTag(tagId);
    final taggedExpenses = expenses.where((e) => expenseIds.contains(e.id)).toList();

    final totalAmount = taggedExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final averageAmount = taggedExpenses.isEmpty ? 0.0 : totalAmount / taggedExpenses.length;
    final lastUsed = taggedExpenses.isEmpty
        ? null
        : taggedExpenses.map((e) => e.expenseDate).reduce((a, b) => a.isAfter(b) ? a : b);

    return TagStats(
      tag: tag,
      expenseCount: taggedExpenses.length,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      lastUsed: lastUsed,
    );
  }

  /// Obtient les statistiques de tous les tags
  static List<TagStats> getAllTagStats(List<Expense> expenses) {
    return _tags.map((t) => getTagStats(t.id, expenses)).toList();
  }

  /// Filtre les dépenses par tags
  static List<Expense> filterExpensesByTags(
    List<Expense> expenses,
    List<String> tagIds, {
    bool matchAll = false,
  }) {
    if (tagIds.isEmpty) return expenses;

    return expenses.where((expense) {
      final expenseTagIds = getTagIdsForExpense(expense.id);
      if (matchAll) {
        // Doit avoir tous les tags
        return tagIds.every((tagId) => expenseTagIds.contains(tagId));
      } else {
        // Doit avoir au moins un tag
        return tagIds.any((tagId) => expenseTagIds.contains(tagId));
      }
    }).toList();
  }

  /// Obtient les tags les plus utilisés
  static List<Tag> getTopTags({int limit = 5}) {
    final sorted = List<Tag>.from(_tags);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted.take(limit).toList();
  }

  /// Suggère des tags basés sur une note de dépense
  static List<Tag> suggestTagsForNote(String note) {
    if (note.isEmpty) return [];

    final lowerNote = note.toLowerCase();
    final suggestions = <Tag>[];

    for (final tag in _tags) {
      // Vérifie si le nom du tag apparaît dans la note
      if (lowerNote.contains(tag.name.toLowerCase())) {
        suggestions.add(tag);
      }
    }

    // Trie par utilisation
    suggestions.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return suggestions.take(3).toList();
  }
}
