// ============================================================================
// SmartSpend - Service Supabase
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';

/// Service Supabase - Point d'accès central à la base de données
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  /// Utilisateur actuel
  static User? get currentUser => auth.currentUser;
  static String? get userId => currentUser?.id;
  static bool get isAuthenticated => currentUser != null;

  // ============ AUTH ============

  /// Inscription avec email/password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    return await auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  /// Connexion avec email/password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Réinitialisation du mot de passe
  static Future<void> resetPassword(String email) async {
    await auth.resetPasswordForEmail(email);
  }

  /// Supprime le compte utilisateur et toutes ses données
  static Future<void> deleteAccount() async {
    if (userId == null) return;

    // Supprimer toutes les données de l'utilisateur
    // L'ordre est important à cause des contraintes de clé étrangère
    await client.from('insights').delete().eq('user_id', userId!);
    await client.from('achievements').delete().eq('user_id', userId!);
    await client.from('streaks').delete().eq('user_id', userId!);
    await client.from('goal_contributions').delete().inFilter(
      'goal_id',
      (await client.from('goals').select('id').eq('user_id', userId!))
          .map((g) => g['id'] as String)
          .toList(),
    );
    await client.from('goals').delete().eq('user_id', userId!);
    await client.from('budgets').delete().eq('user_id', userId!);
    await client.from('expenses').delete().eq('user_id', userId!);
    await client.from('categories').delete().eq('user_id', userId!);
    await client.from('profiles').delete().eq('id', userId!);

    // Déconnecter l'utilisateur
    await signOut();
  }

  /// Met à jour le mot de passe
  static Future<UserResponse> updatePassword(String newPassword) async {
    return await auth.updateUser(UserAttributes(password: newPassword));
  }

  // ============ PROFILES ============

  /// Récupère le profil de l'utilisateur
  static Future<UserProfile?> getProfile() async {
    if (userId == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId!)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Met à jour le profil
  static Future<void> updateProfile(UserProfile profile) async {
    await client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  // ============ CATEGORIES ============

  /// Récupère toutes les catégories (défaut + utilisateur)
  static Future<List<Category>> getCategories() async {
    final response = await client
        .from('categories')
        .select()
        .or('user_id.eq.${userId ?? ''},user_id.is.null')
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }

  /// Crée une catégorie
  static Future<Category> createCategory(Category category) async {
    final response = await client
        .from('categories')
        .insert(category.toJson())
        .select()
        .single();

    return Category.fromJson(response);
  }

  /// Met à jour une catégorie
  static Future<void> updateCategory(Category category) async {
    await client
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  /// Supprime une catégorie (soft delete)
  static Future<void> deleteCategory(String id) async {
    await client
        .from('categories')
        .update({'is_active': false})
        .eq('id', id);
  }

  // ============ EXPENSES ============

  /// Récupère les dépenses
  static Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (userId == null) return [];

    var query = client
        .from('expenses')
        .select('*, categories(*)')
        .eq('user_id', userId!);

    if (startDate != null) {
      query = query.gte('expense_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('expense_date', endDate.toIso8601String().split('T')[0]);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Expense.fromJson(json))
        .toList();
  }

  /// Récupère les dépenses du mois
  static Future<List<Expense>> getMonthlyExpenses(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    return getExpenses(startDate: startDate, endDate: endDate, limit: 1000);
  }

  /// Crée une dépense
  static Future<Expense> createExpense(Expense expense) async {
    final response = await client
        .from('expenses')
        .insert(expense.toJson())
        .select('*, categories(*)')
        .single();

    return Expense.fromJson(response);
  }

  /// Met à jour une dépense
  static Future<void> updateExpense(Expense expense) async {
    await client
        .from('expenses')
        .update(expense.toJson())
        .eq('id', expense.id);
  }

  /// Supprime une dépense
  static Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('id', id);
  }

  // ============ BUDGETS ============

  /// Récupère les budgets du mois
  static Future<List<Budget>> getBudgets({DateTime? month}) async {
    if (userId == null) return [];

    final targetMonth = month ?? DateTime.now();
    final periodStart = DateTime(targetMonth.year, targetMonth.month, 1);

    final response = await client
        .from('budgets')
        .select('*, categories(*)')
        .eq('user_id', userId!)
        .eq('is_active', true)
        .eq('period_start', periodStart.toIso8601String().split('T')[0]);

    return (response as List)
        .map((json) => Budget.fromJson(json))
        .toList();
  }

  /// Crée un budget
  static Future<Budget> createBudget(Budget budget) async {
    final response = await client
        .from('budgets')
        .insert(budget.toJson())
        .select('*, categories(*)')
        .single();

    return Budget.fromJson(response);
  }

  /// Met à jour un budget
  static Future<void> updateBudget(Budget budget) async {
    await client
        .from('budgets')
        .update(budget.toJson())
        .eq('id', budget.id);
  }

  /// Supprime un budget
  static Future<void> deleteBudget(String id) async {
    await client.from('budgets').delete().eq('id', id);
  }

  // ============ GOALS ============

  /// Récupère les objectifs
  static Future<List<Goal>> getGoals({bool includeCompleted = false}) async {
    if (userId == null) return [];

    var query = client
        .from('goals')
        .select()
        .eq('user_id', userId!);

    if (!includeCompleted) {
      query = query.eq('is_completed', false);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => Goal.fromJson(json))
        .toList();
  }

  /// Récupère un objectif par ID
  static Future<Goal?> getGoal(String id) async {
    final response = await client
        .from('goals')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Goal.fromJson(response);
  }

  /// Crée un objectif
  static Future<Goal> createGoal(Goal goal) async {
    final response = await client
        .from('goals')
        .insert(goal.toJson())
        .select()
        .single();

    return Goal.fromJson(response);
  }

  /// Met à jour un objectif
  static Future<void> updateGoal(Goal goal) async {
    await client
        .from('goals')
        .update(goal.toJson())
        .eq('id', goal.id);
  }

  /// Supprime un objectif
  static Future<void> deleteGoal(String id) async {
    await client.from('goals').delete().eq('id', id);
  }

  /// Ajoute une contribution à un objectif
  static Future<void> addGoalContribution(GoalContribution contribution) async {
    await client.from('goal_contributions').insert(contribution.toJson());
  }

  /// Récupère les contributions d'un objectif
  static Future<List<GoalContribution>> getGoalContributions(String goalId) async {
    final response = await client
        .from('goal_contributions')
        .select()
        .eq('goal_id', goalId)
        .order('contribution_date', ascending: false);

    return (response as List)
        .map((json) => GoalContribution.fromJson(json))
        .toList();
  }

  // ============ ACHIEVEMENTS ============

  /// Récupère les achievements de l'utilisateur
  static Future<List<Achievement>> getAchievements() async {
    if (userId == null) return [];

    final response = await client
        .from('achievements')
        .select()
        .eq('user_id', userId!)
        .order('earned_at', ascending: false);

    return (response as List)
        .map((json) => Achievement.fromJson(json))
        .toList();
  }

  /// Récupère tous les types d'achievements
  static Future<List<AchievementType>> getAchievementTypes() async {
    final response = await client
        .from('achievement_types')
        .select()
        .order('points');

    return (response as List)
        .map((json) => AchievementType.fromJson(json))
        .toList();
  }

  /// Crée un achievement
  static Future<Achievement> createAchievement(Achievement achievement) async {
    final response = await client
        .from('achievements')
        .insert(achievement.toJson())
        .select()
        .single();

    return Achievement.fromJson(response);
  }

  // ============ STREAKS ============

  /// Récupère le streak de l'utilisateur
  static Future<Streak?> getStreak() async {
    if (userId == null) return null;

    final response = await client
        .from('streaks')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();

    if (response == null) return null;
    return Streak.fromJson(response);
  }

  /// Met à jour le streak
  static Future<void> updateStreak(Streak streak) async {
    await client
        .from('streaks')
        .update(streak.toJson())
        .eq('id', streak.id);
  }

  // ============ INSIGHTS ============

  /// Récupère les insights non lus
  static Future<List<Insight>> getInsights({bool unreadOnly = false}) async {
    if (userId == null) return [];

    var query = client
        .from('insights')
        .select()
        .eq('user_id', userId!)
        .eq('is_dismissed', false);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final response = await query
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Insight.fromJson(json))
        .toList();
  }

  /// Marque un insight comme lu
  static Future<void> markInsightAsRead(String id) async {
    await client
        .from('insights')
        .update({'is_read': true})
        .eq('id', id);
  }

  /// Masque un insight
  static Future<void> dismissInsight(String id) async {
    await client
        .from('insights')
        .update({'is_dismissed': true})
        .eq('id', id);
  }

  /// Crée un insight
  static Future<Insight> createInsight(Insight insight) async {
    final response = await client
        .from('insights')
        .insert(insight.toJson())
        .select()
        .single();

    return Insight.fromJson(response);
  }
}
