// ============================================================================
// SmartSpend - Écran d'accueil
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/insight_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/currency_service.dart';
import '../../widgets/expense/expense_card.dart';
import '../../widgets/expense/quick_add_button.dart';
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../widgets/tutorial/tutorial_steps.dart';

/// Écran d'accueil - Design Premium
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _fabController.forward();
      _checkTutorial();
    });
  }

  void _checkTutorial() {
    // Afficher le tutoriel après un court délai pour laisser l'UI se charger
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && TutorialService.shouldShowTutorial()) {
        setState(() {
          _showTutorial = true;
        });
      }
    });
  }

  void _completeTutorial() {
    TutorialService.completeTutorial();
    setState(() {
      _showTutorial = false;
    });
  }

  void _skipTutorial() {
    TutorialService.skipTutorial();
    setState(() {
      _showTutorial = false;
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final insightProvider = context.read<InsightProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final accountProvider = context.read<AccountProvider>();

    await Future.wait([
      expenseProvider.loadExpenses(),
      budgetProvider.loadBudgets(),
      categoryProvider.loadCategories(),
      insightProvider.loadInsights(),
      achievementProvider.loadData(),
      accountProvider.loadAccounts(),
    ]);

    if (mounted) {
      final expenses = expenseProvider.getExpensesByCategory();
      final total = expenseProvider.monthTotal;
      budgetProvider.updateSpentAmounts(expenses, total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(),
              _buildStatsPlaceholder(),
              _buildGoalsPlaceholder(),
              _buildProfilePlaceholder(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _buildFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
        // Tutorial Overlay
        if (_showTutorial)
          TutorialOverlay(
            steps: SmartSpendTutorial.shortSteps,
            onComplete: _completeTutorial,
            onSkip: _skipTutorial,
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 70,
            selectedIndex: _currentIndex,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart_rounded, 'Stats', 1),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(Icons.flag_outlined, Icons.flag_rounded, 'Objectifs', 2),
              _buildNavItem(Icons.person_outlined, Icons.person_rounded, 'Profil', 3),
            ].where((e) => e is NavigationDestination || e is SizedBox).toList().asMap().entries.map((e) {
              if (e.value is SizedBox) return e.value as Widget;
              return e.value;
            }).whereType<NavigationDestination>().toList(),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textSecondaryDark),
      selectedIcon: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: AppColors.primaryGradient,
        ).createShader(bounds),
        child: Icon(selectedIcon, color: Colors.white),
      ),
      label: label,
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabController,
      child: Container(
        key: TutorialService.fabKey,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.addExpense),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Consumer4<AuthProvider, ExpenseProvider, BudgetProvider, CategoryProvider>(
      builder: (context, auth, expenses, budgets, categories, _) {
        final profile = auth.profile;
        final globalBudget = budgets.globalBudget;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar avec effet glass
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundDark.withOpacity(0.8),
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bonjour',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      if (profile?.name != null) ...[
                        const SizedBox(width: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: Text(
                            profile!.name!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        ' !',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
              actions: [
                // Bouton recherche
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => context.push(AppRoutes.search),
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                // Bouton Assistant IA
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.auto_awesome, size: 22),
                    onPressed: () => context.push(AppRoutes.aiAssistant),
                    tooltip: 'Assistant IA',
                    color: AppColors.secondary,
                  ),
                ),
                Consumer<InsightProvider>(
                  builder: (context, insights, _) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.glassDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.lightbulb_outline_rounded),
                              onPressed: () => context.push(AppRoutes.insights),
                              color: AppColors.accentGold,
                            ),
                          ),
                          if (insights.unreadCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppColors.accentGradient,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${insights.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            // Contenu
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Carte résumé premium
                  _buildPremiumSummaryCard(currencyFormat, expenses, globalBudget),
                  const SizedBox(height: 20),

                  // Streak avec animation
                  Consumer<AchievementProvider>(
                    builder: (context, achievements, _) {
                      if (achievements.currentStreak > 0) {
                        return _buildStreakCard(achievements.currentStreak);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Bannière Premium pour les utilisateurs gratuits
                  Consumer<SubscriptionProvider>(
                    builder: (context, subscription, _) {
                      if (!subscription.isPremium) {
                        return _buildPremiumBanner(subscription);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Section Comptes
                  Consumer<AccountProvider>(
                    builder: (context, accountProvider, _) {
                      if (accountProvider.hasAccounts && accountProvider.accounts.length > 1) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Mes comptes', () => context.push(AppRoutes.accounts)),
                            const SizedBox(height: 12),
                            _buildAccountsRow(accountProvider),
                            const SizedBox(height: 24),
                          ],
                        );
                      } else if (accountProvider.hasAccounts) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSingleAccountCard(accountProvider),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Section Ajout rapide
                  _buildSectionHeader('Ajout rapide', null),
                  const SizedBox(height: 12),
                  QuickAddGrid(
                    categories: categories.activeCategories,
                    onCategoryTap: (category) {
                      context.push(AppRoutes.addExpense, extra: {'category': category});
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section Dernières dépenses
                  _buildSectionHeader(
                    'Dernières dépenses',
                    () => context.push(AppRoutes.expensesList),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),

            // Liste des dépenses
            if (expenses.expenses.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildEmptyState(),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= expenses.expenses.take(5).length) return null;
                    final expense = expenses.expenses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ExpenseCard(
                        expense: expense,
                        onTap: () => context.push('/expense/${expense.id}'),
                      ),
                    );
                  },
                  childCount: expenses.expenses.take(5).length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Voir tout'),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumSummaryCard(
    NumberFormat currencyFormat,
    ExpenseProvider expenses,
    dynamic globalBudget,
  ) {
    return Container(
      key: TutorialService.summaryCardKey,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            Color(0xFF3B0764),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dépenses ce mois',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMMM', 'fr_FR').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(expenses.monthTotal).replaceAll('€', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '€',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          if (globalBudget != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (globalBudget.percentUsed / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            globalBudget.isOverBudget
                                ? AppColors.accent
                                : AppColors.secondary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget: ${currencyFormat.format(globalBudget.monthlyLimit)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: globalBudget.isOverBudget
                                  ? AppColors.accent.withOpacity(0.3)
                                  : AppColors.secondary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${globalBudget.percentUsed.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: globalBudget.isOverBudget
                                    ? AppColors.accent
                                    : AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStatPremium(
                    'Aujourd\'hui',
                    expenses.todayTotal,
                    currencyFormat,
                    Icons.today_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildMiniStatPremium(
                    'Semaine',
                    expenses.weekTotal,
                    currencyFormat,
                    Icons.date_range_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatPremium(String label, double amount, NumberFormat format, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          format.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner(SubscriptionProvider subscription) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.premium),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.premiumGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.canStartTrial
                        ? 'Essai gratuit 7 jours'
                        : 'Passez à Premium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subscription.canStartTrial
                        ? 'Débloquez tout gratuitement'
                        : 'Catégories, budgets illimités...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subscription.canStartTrial ? 'Essayer' : 'Voir',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGold.withOpacity(0.15),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGold, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.accentGold, AppColors.accent],
                      ).createShader(bounds),
                      child: Text(
                        '$streak jours',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      ' de suite !',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Continuez à suivre vos dépenses',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textTertiaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune dépense ce mois',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour ajouter votre première dépense',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPlaceholder() {
    return _buildPlaceholderScreen(
      icon: Icons.pie_chart_rounded,
      title: 'Statistiques',
      subtitle: 'Analysez vos habitudes de dépenses',
      buttonText: 'Voir les stats',
      onPressed: () => context.push(AppRoutes.stats),
      gradient: AppColors.primaryGradient,
    );
  }

  Widget _buildGoalsPlaceholder() {
    return _buildPlaceholderScreen(
      icon: Icons.flag_rounded,
      title: 'Objectifs',
      subtitle: 'Définissez et suivez vos objectifs d\'épargne',
      buttonText: 'Voir les objectifs',
      onPressed: () => context.push(AppRoutes.goals),
      gradient: AppColors.secondaryGradient,
    );
  }

  Widget _buildProfilePlaceholder() {
    return _buildPlaceholderScreen(
      icon: Icons.person_rounded,
      title: 'Profil',
      subtitle: 'Gérez votre compte et vos préférences',
      buttonText: 'Voir le profil',
      onPressed: () => context.push(AppRoutes.profile),
      gradient: AppColors.primaryGradient,
    );
  }

  Widget _buildPlaceholderScreen({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required List<Color> gradient,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsRow(AccountProvider accountProvider) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accountProvider.accounts.length,
        itemBuilder: (context, index) {
          final account = accountProvider.accounts[index];
          return GestureDetector(
            onTap: () => context.push(AppRoutes.accounts),
            child: Container(
              width: 140,
              margin: EdgeInsets.only(right: index < accountProvider.accounts.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(account.color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        account.type.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyService.format(account.currentBalance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: account.currentBalance >= 0
                          ? AppColors.secondary
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleAccountCard(AccountProvider accountProvider) {
    final account = accountProvider.defaultAccount;
    if (account == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.accounts),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(account.color).withOpacity(0.15),
              Color(account.color).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(account.color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(account.color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                account.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyService.format(account.currentBalance),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: account.currentBalance >= 0
                          ? AppColors.secondary
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryDark,
            ),
          ],
        ),
      ),
    );
  }
}
