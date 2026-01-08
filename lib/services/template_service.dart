import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/expense_template.dart';
import '../data/models/expense.dart';

/// Service de gestion des templates de dépenses
class TemplateService {
  final SupabaseClient _supabase;
  static const String _tableName = 'expense_templates';

  TemplateService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ==================== CRUD ====================

  /// Récupère tous les templates de l'utilisateur
  Future<List<ExpenseTemplate>> getTemplates({
    bool activeOnly = true,
    bool orderByUsage = true,
  }) async {
    if (_userId == null) return [];

    var query = _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final orderColumn = orderByUsage ? 'usage_count' : 'sort_order';
    final response = await query.order(orderColumn, ascending: false);

    return (response as List)
        .map((json) => ExpenseTemplate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère un template par son ID
  Future<ExpenseTemplate?> getTemplateById(String id) async {
    if (_userId == null) return null;

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return ExpenseTemplate.fromJson(response);
  }

  /// Crée un nouveau template
  Future<ExpenseTemplate?> createTemplate({
    required String name,
    double? amount,
    String? categoryId,
    String? accountId,
    String? note,
    List<String>? tagIds,
    String? icon,
    int? color,
  }) async {
    if (_userId == null) return null;

    final id = const Uuid().v4();
    final now = DateTime.now();

    // Obtenir le prochain ordre de tri
    final templates = await getTemplates(activeOnly: false, orderByUsage: false);
    final sortOrder = templates.length;

    final template = ExpenseTemplate(
      id: id,
      userId: _userId!,
      name: name,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
      tagIds: tagIds,
      icon: icon,
      color: color ?? 0xFF2196F3,
      usageCount: 0,
      sortOrder: sortOrder,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _supabase.from(_tableName).insert(template.toJson());
    return template;
  }

  /// Met à jour un template
  Future<ExpenseTemplate?> updateTemplate(ExpenseTemplate template) async {
    if (_userId == null) return null;

    final updated = template.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from(_tableName)
        .update(updated.toJson())
        .eq('id', template.id)
        .eq('user_id', _userId!);

    return updated;
  }

  /// Supprime un template
  Future<bool> deleteTemplate(String id) async {
    if (_userId == null) return false;

    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);

    return true;
  }

  /// Archive un template (soft delete)
  Future<bool> archiveTemplate(String id) async {
    if (_userId == null) return false;

    await _supabase
        .from(_tableName)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId!);

    return true;
  }

  // ==================== UTILISATION ====================

  /// Utilise un template pour créer une dépense
  Future<TemplateUsageResult> useTemplate(
    String templateId, {
    double? overrideAmount,
    DateTime? date,
    String? overrideNote,
  }) async {
    final template = await getTemplateById(templateId);
    if (template == null) {
      return TemplateUsageResult.error('Template non trouvé');
    }

    // Vérifier qu'on a un montant
    final amount = overrideAmount ?? template.amount;
    if (amount == null || amount <= 0) {
      return TemplateUsageResult.needsAmount(template);
    }

    // Créer les données de dépense
    final expenseData = ExpenseFromTemplate(
      amount: amount,
      categoryId: template.categoryId,
      accountId: template.accountId,
      note: overrideNote ?? template.note,
      tagIds: template.tagIds,
      date: date ?? DateTime.now(),
    );

    // Incrémenter le compteur d'utilisation
    await _incrementUsage(templateId);

    return TemplateUsageResult.success(template, expenseData);
  }

  /// Incrémente le compteur d'utilisation
  Future<void> _incrementUsage(String templateId) async {
    if (_userId == null) return;

    // Récupérer l'usage actuel
    final template = await getTemplateById(templateId);
    if (template == null) return;

    await _supabase
        .from(_tableName)
        .update({
          'usage_count': template.usageCount + 1,
          'last_used': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', templateId)
        .eq('user_id', _userId!);
  }

  // ==================== SUGGESTIONS ====================

  /// Récupère les templates les plus utilisés
  Future<List<ExpenseTemplate>> getMostUsedTemplates({int limit = 5}) async {
    if (_userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!)
        .eq('is_active', true)
        .order('usage_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ExpenseTemplate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les templates récemment utilisés
  Future<List<ExpenseTemplate>> getRecentlyUsedTemplates({int limit = 5}) async {
    if (_userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!)
        .eq('is_active', true)
        .not('last_used', 'is', null)
        .order('last_used', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ExpenseTemplate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Suggère des templates basés sur le contexte
  Future<List<ExpenseTemplate>> suggestTemplates({
    DateTime? forDate,
    String? categoryId,
  }) async {
    final allTemplates = await getTemplates();
    if (allTemplates.isEmpty) return [];

    var suggestions = allTemplates;

    // Filtrer par catégorie si spécifiée
    if (categoryId != null) {
      suggestions = suggestions
          .where((t) => t.categoryId == categoryId)
          .toList();
    }

    // Si c'est l'heure du déjeuner, prioriser les templates de repas
    if (forDate != null) {
      final hour = forDate.hour;
      if (hour >= 11 && hour <= 14) {
        // Prioriser les templates de nourriture
        suggestions.sort((a, b) {
          final aIsFood = a.name.toLowerCase().contains('déjeuner') ||
              a.name.toLowerCase().contains('repas');
          final bIsFood = b.name.toLowerCase().contains('déjeuner') ||
              b.name.toLowerCase().contains('repas');
          if (aIsFood && !bIsFood) return -1;
          if (!aIsFood && bIsFood) return 1;
          return b.usageCount.compareTo(a.usageCount);
        });
      }
    }

    return suggestions.take(5).toList();
  }

  // ==================== CRÉATION AUTO ====================

  /// Crée un template à partir d'une dépense existante
  Future<ExpenseTemplate?> createFromExpense(Expense expense, {String? name}) async {
    return createTemplate(
      name: name ?? expense.note ?? expense.category?.name ?? 'Dépense',
      amount: expense.amount,
      categoryId: expense.categoryId,
      // Note: accountId et tagIds ne sont pas encore supportés par Expense
      // accountId: expense.accountId,
      note: expense.note,
      // tagIds: expense.tagIds,
    );
  }

  /// Suggère la création de templates basés sur les dépenses récurrentes
  Future<List<TemplateSuggestion>> suggestNewTemplates(
    List<Expense> recentExpenses,
  ) async {
    final suggestions = <TemplateSuggestion>[];
    final existingTemplates = await getTemplates(activeOnly: false);
    final existingNames = existingTemplates.map((t) => t.name.toLowerCase()).toSet();

    // Grouper par note similaire
    final noteGroups = <String, List<Expense>>{};
    for (final expense in recentExpenses) {
      if (expense.note != null && expense.note!.isNotEmpty) {
        final key = expense.note!.toLowerCase().trim();
        noteGroups[key] = (noteGroups[key] ?? [])..add(expense);
      }
    }

    // Suggérer les notes qui apparaissent souvent
    for (final entry in noteGroups.entries) {
      if (entry.value.length >= 3) {
        final name = entry.key;
        if (!existingNames.contains(name)) {
          final avgAmount = entry.value.fold(0.0, (sum, e) => sum + e.amount) /
              entry.value.length;

          suggestions.add(TemplateSuggestion(
            name: _capitalize(name),
            averageAmount: avgAmount,
            frequency: entry.value.length,
            categoryId: entry.value.first.categoryId,
            reason: 'Dépense récurrente (${entry.value.length} fois)',
          ));
        }
      }
    }

    // Trier par fréquence
    suggestions.sort((a, b) => b.frequency.compareTo(a.frequency));

    return suggestions.take(5).toList();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ==================== RÉORGANISATION ====================

  /// Réordonne les templates
  Future<void> reorderTemplates(List<String> templateIds) async {
    if (_userId == null) return;

    for (int i = 0; i < templateIds.length; i++) {
      await _supabase
          .from(_tableName)
          .update({'sort_order': i})
          .eq('id', templateIds[i])
          .eq('user_id', _userId!);
    }
  }

  // ==================== TEMPLATES PAR DÉFAUT ====================

  /// Crée les templates par défaut pour un nouvel utilisateur
  Future<void> createDefaultTemplates() async {
    final existing = await getTemplates(activeOnly: false);
    if (existing.isNotEmpty) return;

    final defaults = SuggestedTemplates.getDefaults();

    for (final template in defaults) {
      await createTemplate(
        name: template['name'] as String,
        amount: template['amount'] as double?,
        icon: template['icon'] as String?,
        color: template['color'] as int?,
      );
    }
  }
}

/// Résultat d'utilisation d'un template
class TemplateUsageResult {
  final bool success;
  final bool needsAmount;
  final String? errorMessage;
  final ExpenseTemplate? template;
  final ExpenseFromTemplate? expenseData;

  const TemplateUsageResult._({
    required this.success,
    this.needsAmount = false,
    this.errorMessage,
    this.template,
    this.expenseData,
  });

  factory TemplateUsageResult.success(
    ExpenseTemplate template,
    ExpenseFromTemplate expenseData,
  ) {
    return TemplateUsageResult._(
      success: true,
      template: template,
      expenseData: expenseData,
    );
  }

  factory TemplateUsageResult.needsAmount(ExpenseTemplate template) {
    return TemplateUsageResult._(
      success: false,
      needsAmount: true,
      template: template,
    );
  }

  factory TemplateUsageResult.error(String message) {
    return TemplateUsageResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Données de dépense créées à partir d'un template
class ExpenseFromTemplate {
  final double amount;
  final String? categoryId;
  final String? accountId;
  final String? note;
  final List<String>? tagIds;
  final DateTime date;

  const ExpenseFromTemplate({
    required this.amount,
    this.categoryId,
    this.accountId,
    this.note,
    this.tagIds,
    required this.date,
  });
}

/// Suggestion de nouveau template
class TemplateSuggestion {
  final String name;
  final double averageAmount;
  final int frequency;
  final String? categoryId;
  final String reason;

  const TemplateSuggestion({
    required this.name,
    required this.averageAmount,
    required this.frequency,
    this.categoryId,
    required this.reason,
  });
}
