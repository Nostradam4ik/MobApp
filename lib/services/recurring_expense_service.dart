import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import 'supabase_service.dart';

/// Fréquences de récurrence disponibles
enum RecurringFrequency {
  daily('daily', 'Quotidien'),
  weekly('weekly', 'Hebdomadaire'),
  biweekly('biweekly', 'Bi-mensuel'),
  monthly('monthly', 'Mensuel'),
  quarterly('quarterly', 'Trimestriel'),
  yearly('yearly', 'Annuel');

  final String value;
  final String label;
  const RecurringFrequency(this.value, this.label);

  static RecurringFrequency fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

/// Service pour gérer les dépenses récurrentes
class RecurringExpenseService {
  RecurringExpenseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Récupère toutes les dépenses récurrentes de l'utilisateur
  static Future<List<Expense>> getRecurringExpenses() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('expenses')
        .select('*, categories(*)')
        .eq('user_id', userId)
        .eq('is_recurring', true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  /// Crée une dépense récurrente
  static Future<Expense> createRecurringExpense({
    required String categoryId,
    required double amount,
    required RecurringFrequency frequency,
    String? note,
    required DateTime startDate,
  }) async {
    final userId = SupabaseService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'note': note,
      'expense_date': startDate.toIso8601String().split('T')[0],
      'is_recurring': true,
      'recurring_frequency': frequency.value,
    };

    final response = await _client
        .from('expenses')
        .insert(data)
        .select('*, categories(*)')
        .single();

    return Expense.fromJson(response);
  }

  /// Met à jour une dépense récurrente
  static Future<void> updateRecurringExpense(Expense expense) async {
    await _client.from('expenses').update({
      'category_id': expense.categoryId,
      'amount': expense.amount,
      'note': expense.note,
      'recurring_frequency': expense.recurringFrequency,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', expense.id);
  }

  /// Supprime une dépense récurrente
  static Future<void> deleteRecurringExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  /// Désactive une dépense récurrente (la rend non-récurrente)
  static Future<void> pauseRecurringExpense(String id) async {
    await _client.from('expenses').update({
      'is_recurring': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Génère les dépenses récurrentes pour le mois en cours
  /// Cette méthode vérifie quelles dépenses récurrentes doivent être créées
  static Future<List<Expense>> generateRecurringExpenses() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    final recurringExpenses = await getRecurringExpenses();
    final now = DateTime.now();
    final generatedExpenses = <Expense>[];

    for (final recurring in recurringExpenses) {
      final shouldGenerate = _shouldGenerateExpense(recurring, now);

      if (shouldGenerate) {
        // Vérifier si cette dépense n'a pas déjà été générée ce mois
        final exists = await _expenseExistsForPeriod(recurring, now);

        if (!exists) {
          // Créer la nouvelle dépense
          final newExpense = await _createGeneratedExpense(recurring, now);
          if (newExpense != null) {
            generatedExpenses.add(newExpense);
          }
        }
      }
    }

    return generatedExpenses;
  }

  /// Vérifie si une dépense récurrente doit être générée
  static bool _shouldGenerateExpense(Expense recurring, DateTime now) {
    final frequency = RecurringFrequency.fromString(
      recurring.recurringFrequency ?? 'monthly',
    );
    final lastDate = recurring.expenseDate;

    switch (frequency) {
      case RecurringFrequency.daily:
        return now.difference(lastDate).inDays >= 1;
      case RecurringFrequency.weekly:
        return now.difference(lastDate).inDays >= 7;
      case RecurringFrequency.biweekly:
        return now.difference(lastDate).inDays >= 14;
      case RecurringFrequency.monthly:
        return now.month != lastDate.month || now.year != lastDate.year;
      case RecurringFrequency.quarterly:
        final quartersDiff = ((now.year - lastDate.year) * 4) +
            ((now.month - 1) ~/ 3) -
            ((lastDate.month - 1) ~/ 3);
        return quartersDiff >= 1;
      case RecurringFrequency.yearly:
        return now.year != lastDate.year;
    }
  }

  /// Vérifie si une dépense existe déjà pour la période
  static Future<bool> _expenseExistsForPeriod(
    Expense recurring,
    DateTime period,
  ) async {
    final userId = SupabaseService.userId;
    if (userId == null) return true;

    final startOfMonth = DateTime(period.year, period.month, 1);
    final endOfMonth = DateTime(period.year, period.month + 1, 0);

    final response = await _client
        .from('expenses')
        .select('id')
        .eq('user_id', userId)
        .eq('category_id', recurring.categoryId ?? '')
        .eq('amount', recurring.amount)
        .eq('is_recurring', false) // Les dépenses générées ne sont pas marquées récurrentes
        .gte('expense_date', startOfMonth.toIso8601String().split('T')[0])
        .lte('expense_date', endOfMonth.toIso8601String().split('T')[0])
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Crée une dépense générée à partir d'une récurrente
  static Future<Expense?> _createGeneratedExpense(
    Expense recurring,
    DateTime date,
  ) async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      final data = {
        'user_id': userId,
        'category_id': recurring.categoryId,
        'amount': recurring.amount,
        'note': '${recurring.note ?? ''} (récurrent)'.trim(),
        'expense_date': date.toIso8601String().split('T')[0],
        'is_recurring': false, // La dépense générée n'est pas récurrente
      };

      final response = await _client
          .from('expenses')
          .insert(data)
          .select('*, categories(*)')
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      print('Erreur génération dépense récurrente: $e');
      return null;
    }
  }

  /// Calcule le prochain paiement prévu
  static DateTime getNextPaymentDate(Expense recurring) {
    final frequency = RecurringFrequency.fromString(
      recurring.recurringFrequency ?? 'monthly',
    );
    final lastDate = recurring.expenseDate;

    switch (frequency) {
      case RecurringFrequency.daily:
        return lastDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return lastDate.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return lastDate.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case RecurringFrequency.quarterly:
        return DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
      case RecurringFrequency.yearly:
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
    }
  }

  /// Calcule le total mensuel des dépenses récurrentes
  static double calculateMonthlyTotal(List<Expense> recurringExpenses) {
    double total = 0;

    for (final expense in recurringExpenses) {
      final frequency = RecurringFrequency.fromString(
        expense.recurringFrequency ?? 'monthly',
      );

      switch (frequency) {
        case RecurringFrequency.daily:
          total += expense.amount * 30;
          break;
        case RecurringFrequency.weekly:
          total += expense.amount * 4.33;
          break;
        case RecurringFrequency.biweekly:
          total += expense.amount * 2.17;
          break;
        case RecurringFrequency.monthly:
          total += expense.amount;
          break;
        case RecurringFrequency.quarterly:
          total += expense.amount / 3;
          break;
        case RecurringFrequency.yearly:
          total += expense.amount / 12;
          break;
      }
    }

    return total;
  }
}
