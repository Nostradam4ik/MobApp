// ============================================================================
// SmartSpend - Routeur de l'application
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../animations/page_transitions.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/expenses/expense_detail_screen.dart';
import '../../screens/expenses/expenses_list_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/categories/category_form_screen.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/budgets/budget_form_screen.dart';
import '../../screens/goals/goals_screen.dart';
import '../../screens/goals/goal_form_screen.dart';
import '../../screens/goals/goal_detail_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/achievements/achievements_screen.dart';
import '../../screens/export/export_screen.dart';
import '../../screens/recurring/recurring_expenses_screen.dart';
import '../../screens/notifications/notification_settings_screen.dart';
import '../../screens/sync/sync_settings_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/stats/advanced_stats_screen.dart';
import '../../screens/import/import_screen.dart';
import '../../screens/settings/theme_settings_screen.dart';
import '../../screens/settings/currency_settings_screen.dart';
import '../../screens/settings/language_settings_screen.dart';
import '../../screens/premium/premium_screen.dart';
import '../../screens/scan/receipt_scan_screen.dart';
import '../../screens/bills/bills_screen.dart';
import '../../screens/health/financial_health_screen.dart';
import '../../screens/challenges/challenges_screen.dart';
import '../../screens/challenges/challenge_detail_screen.dart';
import '../../screens/challenges/create_challenge_screen.dart';
import '../../screens/split/splits_list_screen.dart';
import '../../screens/split/split_expense_screen.dart';
import '../../screens/split/split_detail_screen.dart';
import '../../screens/predictions/predictions_screen.dart';
import '../../screens/tags/tags_screen.dart';
import '../../screens/tags/tag_detail_screen.dart';
import '../../screens/assistant/ai_assistant_screen.dart';
import '../../screens/settings/accessibility_screen.dart';
import '../../screens/accounts/accounts_screen.dart';
import '../../screens/accounts/account_form_screen.dart';
import '../../data/models/expense_split.dart';
import '../../data/models/savings_challenge.dart';
import '../../data/models/tag.dart';
import '../../data/models/account.dart';

/// Routes de l'application
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String addExpense = '/add-expense';
  static const String expenseDetail = '/expense/:id';
  static const String expensesList = '/expenses';
  static const String categories = '/categories';
  static const String categoryForm = '/category-form';
  static const String budgets = '/budgets';
  static const String budgetForm = '/budget-form';
  static const String goals = '/goals';
  static const String goalForm = '/goal-form';
  static const String goalDetail = '/goal/:id';
  static const String stats = '/stats';
  static const String advancedStats = '/advanced-stats';
  static const String insights = '/insights';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String export = '/export';
  static const String recurring = '/recurring';
  static const String notifications = '/notifications';
  static const String sync = '/sync';
  static const String search = '/search';
  static const String import = '/import';
  static const String themeSettings = '/theme-settings';
  static const String currencySettings = '/currency-settings';
  static const String languageSettings = '/language-settings';
  static const String premium = '/premium';
  static const String scanReceipt = '/scan-receipt';
  static const String bills = '/bills';

  // Innovations
  static const String financialHealth = '/financial-health';
  static const String challenges = '/challenges';
  static const String challengeDetail = '/challenge/:id';
  static const String createChallenge = '/create-challenge';
  static const String splits = '/splits';
  static const String splitExpense = '/split-expense';
  static const String splitDetail = '/split/:id';
  static const String predictions = '/predictions';
  static const String tags = '/tags';
  static const String tagDetail = '/tag/:id';
  static const String aiAssistant = '/ai-assistant';
  static const String accessibility = '/accessibility';
  static const String accounts = '/accounts';
  static const String accountForm = '/account-form';
}

/// Configuration du routeur
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Helper pour créer une page avec transition personnalisée
  static CustomTransitionPage<T> _buildPage<T>({
    required Widget child,
    required GoRouterState state,
    TransitionType type = TransitionType.slideRight,
  }) {
    return buildTransitionPage<T>(
      key: state.pageKey,
      child: child,
      type: type,
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // Ne pas rediriger depuis splash ou onboarding
      if (isSplash || isOnboarding) return null;

      // Si non connecté et pas sur une route auth, rediriger vers login
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Si connecté et sur une route auth, rediriger vers home
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // ============ SPLASH & ONBOARDING ============
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildPage(
          child: const SplashScreen(),
          state: state,
          type: TransitionType.fade,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildPage(
          child: const OnboardingScreen(),
          state: state,
          type: TransitionType.fade,
        ),
      ),

      // ============ AUTH ============
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPage(
          child: const LoginScreen(),
          state: state,
          type: TransitionType.fade,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildPage(
          child: const RegisterScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _buildPage(
          child: const ForgotPasswordScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),

      // ============ MAIN ============
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildPage(
          child: const HomeScreen(),
          state: state,
          type: TransitionType.fade,
        ),
      ),

      // ============ EXPENSES ============
      GoRoute(
        path: AppRoutes.addExpense,
        pageBuilder: (context, state) {
          final expense = state.extra as Map<String, dynamic>?;
          return _buildPage(
            child: AddExpenseScreen(existingExpense: expense),
            state: state,
            type: TransitionType.slideUp,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.expenseDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            child: ExpenseDetailScreen(expenseId: id),
            state: state,
            type: TransitionType.scaleWithFade,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.expensesList,
        pageBuilder: (context, state) => _buildPage(
          child: const ExpensesListScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ CATEGORIES ============
      GoRoute(
        path: AppRoutes.categories,
        pageBuilder: (context, state) => _buildPage(
          child: const CategoriesScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.categoryForm,
        pageBuilder: (context, state) {
          final category = state.extra as Map<String, dynamic>?;
          return _buildPage(
            child: CategoryFormScreen(existingCategory: category),
            state: state,
            type: TransitionType.slideUp,
          );
        },
      ),

      // ============ BUDGETS ============
      GoRoute(
        path: AppRoutes.budgets,
        pageBuilder: (context, state) => _buildPage(
          child: const BudgetsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.budgetForm,
        pageBuilder: (context, state) {
          final budget = state.extra as Map<String, dynamic>?;
          return _buildPage(
            child: BudgetFormScreen(existingBudget: budget),
            state: state,
            type: TransitionType.slideUp,
          );
        },
      ),

      // ============ GOALS ============
      GoRoute(
        path: AppRoutes.goals,
        pageBuilder: (context, state) => _buildPage(
          child: const GoalsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.goalForm,
        pageBuilder: (context, state) {
          final goal = state.extra as Map<String, dynamic>?;
          return _buildPage(
            child: GoalFormScreen(existingGoal: goal),
            state: state,
            type: TransitionType.slideUp,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.goalDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            child: GoalDetailScreen(goalId: id),
            state: state,
            type: TransitionType.scaleWithFade,
          );
        },
      ),

      // ============ STATS & INSIGHTS ============
      GoRoute(
        path: AppRoutes.stats,
        pageBuilder: (context, state) => _buildPage(
          child: const StatsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.advancedStats,
        pageBuilder: (context, state) => _buildPage(
          child: const AdvancedStatsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.insights,
        pageBuilder: (context, state) => _buildPage(
          child: const InsightsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ PROFILE & SETTINGS ============
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _buildPage(
          child: const ProfileScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildPage(
          child: const SettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        pageBuilder: (context, state) => _buildPage(
          child: const ThemeSettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.currencySettings,
        pageBuilder: (context, state) => _buildPage(
          child: const CurrencySettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        pageBuilder: (context, state) => _buildPage(
          child: const LanguageSettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildPage(
          child: const NotificationSettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ ACHIEVEMENTS ============
      GoRoute(
        path: AppRoutes.achievements,
        pageBuilder: (context, state) => _buildPage(
          child: const AchievementsScreen(),
          state: state,
          type: TransitionType.scaleWithFade,
        ),
      ),

      // ============ EXPORT/IMPORT ============
      GoRoute(
        path: AppRoutes.export,
        pageBuilder: (context, state) => _buildPage(
          child: const ExportScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.import,
        pageBuilder: (context, state) => _buildPage(
          child: const ImportScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ RECURRING ============
      GoRoute(
        path: AppRoutes.recurring,
        pageBuilder: (context, state) => _buildPage(
          child: const RecurringExpensesScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ SYNC ============
      GoRoute(
        path: AppRoutes.sync,
        pageBuilder: (context, state) => _buildPage(
          child: const SyncSettingsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ SEARCH ============
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _buildPage(
          child: const SearchScreen(),
          state: state,
          type: TransitionType.fade,
        ),
      ),

      // ============ PREMIUM ============
      GoRoute(
        path: AppRoutes.premium,
        pageBuilder: (context, state) => _buildPage(
          child: const PremiumScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),

      // ============ SCAN ============
      GoRoute(
        path: AppRoutes.scanReceipt,
        pageBuilder: (context, state) => _buildPage(
          child: const ReceiptScanScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),

      // ============ BILLS ============
      GoRoute(
        path: AppRoutes.bills,
        pageBuilder: (context, state) => _buildPage(
          child: const BillsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ FINANCIAL HEALTH ============
      GoRoute(
        path: AppRoutes.financialHealth,
        pageBuilder: (context, state) => _buildPage(
          child: const FinancialHealthScreen(),
          state: state,
          type: TransitionType.scaleWithFade,
        ),
      ),

      // ============ CHALLENGES ============
      GoRoute(
        path: AppRoutes.challenges,
        pageBuilder: (context, state) => _buildPage(
          child: const ChallengesScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.challengeDetail,
        pageBuilder: (context, state) {
          final challenge = state.extra as SavingsChallenge;
          return _buildPage(
            child: ChallengeDetailScreen(challenge: challenge),
            state: state,
            type: TransitionType.scaleWithFade,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createChallenge,
        pageBuilder: (context, state) => _buildPage(
          child: const CreateChallengeScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),

      // ============ SPLITS ============
      GoRoute(
        path: AppRoutes.splits,
        pageBuilder: (context, state) => _buildPage(
          child: const SplitsListScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.splitExpense,
        pageBuilder: (context, state) => _buildPage(
          child: const SplitExpenseScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.splitDetail,
        pageBuilder: (context, state) {
          final split = state.extra as ExpenseSplit;
          return _buildPage(
            child: SplitDetailScreen(split: split),
            state: state,
            type: TransitionType.scaleWithFade,
          );
        },
      ),

      // ============ PREDICTIONS ============
      GoRoute(
        path: AppRoutes.predictions,
        pageBuilder: (context, state) => _buildPage(
          child: const PredictionsScreen(),
          state: state,
          type: TransitionType.scaleWithFade,
        ),
      ),

      // ============ TAGS ============
      GoRoute(
        path: AppRoutes.tags,
        pageBuilder: (context, state) => _buildPage(
          child: const TagsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.tagDetail,
        pageBuilder: (context, state) {
          final tag = state.extra as Tag;
          return _buildPage(
            child: TagDetailScreen(tag: tag),
            state: state,
            type: TransitionType.scaleWithFade,
          );
        },
      ),

      // ============ AI ASSISTANT ============
      GoRoute(
        path: AppRoutes.aiAssistant,
        pageBuilder: (context, state) => _buildPage(
          child: const AIAssistantScreen(),
          state: state,
          type: TransitionType.slideUp,
        ),
      ),

      // ============ ACCESSIBILITY ============
      GoRoute(
        path: AppRoutes.accessibility,
        pageBuilder: (context, state) => _buildPage(
          child: const AccessibilityScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),

      // ============ ACCOUNTS ============
      GoRoute(
        path: AppRoutes.accounts,
        pageBuilder: (context, state) => _buildPage(
          child: const AccountsScreen(),
          state: state,
          type: TransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountForm,
        pageBuilder: (context, state) {
          final account = state.extra as Account?;
          return _buildPage(
            child: AccountFormScreen(existingAccount: account),
            state: state,
            type: TransitionType.slideUp,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}
