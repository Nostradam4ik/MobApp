import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/income.dart';

/// Service de gestion des revenus
class IncomeService {
  final SupabaseClient _supabase;
  static const String _tableName = 'incomes';

  IncomeService(this._supabase);

  /// Obtient l'ID de l'utilisateur connecté
  String? get _userId => _supabase.auth.currentUser?.id;

  // ==================== CRUD ====================

  /// Récupère tous les revenus de l'utilisateur
  Future<List<Income>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    IncomeType? type,
    String? accountId,
    bool includeRecurring = true,
  }) async {
    if (_userId == null) return [];

    var query = _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }
    if (type != null) {
      query = query.eq('type', type.value);
    }
    if (accountId != null) {
      query = query.eq('account_id', accountId);
    }

    final response = await query.order('date', ascending: false);
    return (response as List).map((json) => Income.fromJson(json)).toList();
  }

  /// Récupère un revenu par son ID
  Future<Income?> getIncomeById(String id) async {
    if (_userId == null) return null;

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return Income.fromJson(response);
  }

  /// Crée un nouveau revenu
  Future<Income?> createIncome({
    required double amount,
    required IncomeType type,
    required DateTime date,
    String? source,
    String? note,
    String? accountId,
    bool isRecurring = false,
    IncomeFrequency frequency = IncomeFrequency.once,
    bool isConfirmed = true,
  }) async {
    if (_userId == null) return null;

    final id = const Uuid().v4();
    final now = DateTime.now();

    final income = Income(
      id: id,
      userId: _userId!,
      accountId: accountId,
      amount: amount,
      type: type,
      source: source,
      note: note,
      date: date,
      isRecurring: isRecurring,
      frequency: frequency,
      nextOccurrence: isRecurring ? _calculateNextOccurrence(date, frequency) : null,
      isConfirmed: isConfirmed,
      createdAt: now,
      updatedAt: now,
    );

    await _supabase.from(_tableName).insert(income.toJson());
    return income;
  }

  /// Met à jour un revenu
  Future<Income?> updateIncome(Income income) async {
    if (_userId == null) return null;

    final updated = income.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from(_tableName)
        .update(updated.toJson())
        .eq('id', income.id)
        .eq('user_id', _userId!);

    return updated;
  }

  /// Supprime un revenu
  Future<bool> deleteIncome(String id) async {
    if (_userId == null) return false;

    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);

    return true;
  }

  // ==================== STATISTIQUES ====================

  /// Calcule le total des revenus pour une période
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  }) async {
    final incomes = await getIncomes(
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
    );

    double total = 0.0;
    for (final income in incomes) {
      total += income.amount;
    }
    return total;
  }

  /// Calcule les revenus par type
  Future<Map<IncomeType, double>> getIncomeByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final incomes = await getIncomes(
      startDate: startDate,
      endDate: endDate,
    );

    final result = <IncomeType, double>{};
    for (final income in incomes) {
      result[income.type] = (result[income.type] ?? 0) + income.amount;
    }

    return result;
  }

  /// Calcule le revenu mensuel moyen
  Future<double> getAverageMonthlyIncome({int months = 6}) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - months, 1);

    final incomes = await getIncomes(
      startDate: startDate,
      endDate: endDate,
    );

    if (incomes.isEmpty) return 0;

    final total = incomes.fold(0.0, (sum, income) => sum + income.amount);
    return total / months;
  }

  /// Obtient les revenus récurrents
  Future<List<Income>> getRecurringIncomes() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', _userId!)
        .eq('is_recurring', true)
        .order('date', ascending: false);

    return (response as List).map((json) => Income.fromJson(json)).toList();
  }

  /// Calcule le revenu mensuel estimé (incluant récurrents)
  Future<double> getEstimatedMonthlyIncome() async {
    final recurring = await getRecurringIncomes();
    double total = 0.0;
    for (final income in recurring) {
      total += income.monthlyAmount;
    }
    return total;
  }

  /// Obtient les revenus du mois en cours
  Future<List<Income>> getCurrentMonthIncomes() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return getIncomes(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Obtient la balance (revenus - dépenses) pour une période
  Future<IncomeStats> getIncomeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final incomes = await getIncomes(
      startDate: startDate,
      endDate: endDate,
    );

    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final confirmedIncome = incomes
        .where((i) => i.isConfirmed)
        .fold(0.0, (sum, i) => sum + i.amount);
    final pendingIncome = incomes
        .where((i) => !i.isConfirmed)
        .fold(0.0, (sum, i) => sum + i.amount);

    final byType = <IncomeType, double>{};
    for (final income in incomes) {
      byType[income.type] = (byType[income.type] ?? 0) + income.amount;
    }

    return IncomeStats(
      totalIncome: totalIncome,
      confirmedIncome: confirmedIncome,
      pendingIncome: pendingIncome,
      incomeCount: incomes.length,
      byType: byType,
    );
  }

  // ==================== REVENUS RÉCURRENTS ====================

  /// Génère les revenus récurrents pour le mois en cours
  Future<List<Income>> generateRecurringIncomes() async {
    final recurring = await getRecurringIncomes();
    final now = DateTime.now();
    final generated = <Income>[];

    for (final income in recurring) {
      if (income.nextOccurrence != null &&
          income.nextOccurrence!.month == now.month &&
          income.nextOccurrence!.year == now.year) {
        // Créer le revenu pour ce mois
        final newIncome = await createIncome(
          amount: income.amount,
          type: income.type,
          date: income.nextOccurrence!,
          source: income.source,
          note: income.note,
          accountId: income.accountId,
          isConfirmed: false, // Pas encore confirmé
        );

        if (newIncome != null) {
          generated.add(newIncome);
        }

        // Mettre à jour la prochaine occurrence
        final nextDate = _calculateNextOccurrence(
          income.nextOccurrence!,
          income.frequency,
        );
        await updateIncome(income.copyWith(nextOccurrence: nextDate));
      }
    }

    return generated;
  }

  /// Calcule la prochaine occurrence
  DateTime _calculateNextOccurrence(DateTime date, IncomeFrequency frequency) {
    switch (frequency) {
      case IncomeFrequency.weekly:
        return date.add(const Duration(days: 7));
      case IncomeFrequency.biweekly:
        return date.add(const Duration(days: 14));
      case IncomeFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case IncomeFrequency.quarterly:
        return DateTime(date.year, date.month + 3, date.day);
      case IncomeFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
      case IncomeFrequency.once:
        return date;
    }
  }
}

/// Statistiques de revenus
class IncomeStats {
  final double totalIncome;
  final double confirmedIncome;
  final double pendingIncome;
  final int incomeCount;
  final Map<IncomeType, double> byType;

  const IncomeStats({
    required this.totalIncome,
    required this.confirmedIncome,
    required this.pendingIncome,
    required this.incomeCount,
    required this.byType,
  });

  /// Type de revenu principal
  IncomeType? get mainIncomeType {
    if (byType.isEmpty) return null;
    return byType.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
