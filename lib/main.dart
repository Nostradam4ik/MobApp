// ============================================================================
// SmartSpend - Application de suivi des dépenses personnelles
// ============================================================================
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// Copyright (c) 2024 Andrii Zhmuryk. Tous droits réservés.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/insight_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/account_provider.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/local_storage_service.dart';
import 'services/currency_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/accessibility_service.dart';

Future<void> main() async {
  // Wrapper pour capturer les erreurs au démarrage
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize date formatting for French locale
    await initializeDateFormatting('fr_FR', null);

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // Initialize local storage
    await LocalStorageService.init();

    // Initialize notifications
    await NotificationService.init();

    // Initialize currency service
    await CurrencyService.init();

    // Initialize crash reporting (Sentry)
    await CrashReportingService.init();

    // Initialize accessibility service
    await AccessibilityService.init();

    // Capture les erreurs Flutter non gérées
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      CrashReportingService.captureException(
        details.exception,
        stackTrace: details.stack,
        message: details.context?.toString(),
      );
    };

    // Capture les erreurs de la plateforme
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashReportingService.captureException(error, stackTrace: stack);
      return true;
    };

    runApp(const SmartSpendApp());
  }, (error, stackTrace) {
    // Capture les erreurs de la zone
    debugPrint('Zone error: $error');
    CrashReportingService.captureException(error, stackTrace: stackTrace);
  });
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, subscription) {
            subscription?.updateUserId(auth.userId);
            return subscription ?? SubscriptionProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, auth, categories) {
            categories?.updateUserId(auth.userId);
            return categories ?? CategoryProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AccountProvider>(
          create: (_) => AccountProvider(),
          update: (_, auth, accounts) {
            accounts?.updateUserId(auth.userId);
            return accounts ?? AccountProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, expenses) {
            expenses?.updateUserId(auth.userId);
            return expenses ?? ExpenseProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (_) => BudgetProvider(),
          update: (_, auth, budgets) {
            budgets?.updateUserId(auth.userId);
            return budgets ?? BudgetProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (_) => GoalProvider(),
          update: (_, auth, goals) {
            goals?.updateUserId(auth.userId);
            return goals ?? GoalProvider();
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ExpenseProvider, StatsProvider>(
          create: (_) => StatsProvider(),
          update: (_, auth, expenses, stats) {
            stats?.updateData(auth.userId, expenses.expenses);
            return stats ?? StatsProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, InsightProvider>(
          create: (_) => InsightProvider(),
          update: (_, auth, insights) {
            insights?.updateUserId(auth.userId);
            return insights ?? InsightProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AchievementProvider>(
          create: (_) => AchievementProvider(),
          update: (_, auth, achievements) {
            achievements?.updateUserId(auth.userId);
            return achievements ?? AchievementProvider();
          },
        ),
      ],
      child: Consumer3<ThemeProvider, AccessibilityProvider, LanguageProvider>(
        builder: (context, themeProvider, accessibilityProvider, languageProvider, _) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(accessibilityProvider.fontScale),
              // Respecter le paramètre système pour réduire les animations
              disableAnimations: accessibilityProvider.reduceAnimations,
            ),
            child: MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: AppRouter.router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: languageProvider.locale,
            ),
          );
        },
      ),
    );
  }
}
