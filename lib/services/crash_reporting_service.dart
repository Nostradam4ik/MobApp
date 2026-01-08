import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configuration pour Sentry
///
/// INSTRUCTIONS DE CONFIGURATION:
/// 1. Créez un compte gratuit sur https://sentry.io
/// 2. Créez un nouveau projet Flutter
/// 3. Copiez le DSN fourni et remplacez la valeur ci-dessous
/// 4. Le plan gratuit inclut:
///    - 5000 erreurs/mois
///    - 10000 transactions/mois
///    - 1GB de stockage
///    - Rétention de 30 jours
class CrashReportingConfig {
  CrashReportingConfig._();

  /// DSN Sentry
  /// Trouvez-le dans: Sentry > Project Settings > Client Keys (DSN)
  static const String sentryDsn = 'https://c3ddd4bb9d2b3c472d499a3e886ec0d0@o4510562626830336.ingest.de.sentry.io/4510562631549008';

  /// Vérifie si Sentry est configuré
  static bool get isConfigured => sentryDsn != 'YOUR_SENTRY_DSN_HERE';

  /// Environnement (production, staging, development)
  static String get environment => kDebugMode ? 'development' : 'production';
}

/// Service de crash reporting utilisant Sentry (gratuit)
class CrashReportingService {
  CrashReportingService._();

  static bool _isInitialized = false;

  /// Initialise Sentry pour le crash reporting
  /// Doit être appelé AVANT runApp() dans main.dart
  static Future<void> init() async {
    if (_isInitialized) return;

    // Ne pas initialiser si le DSN n'est pas configuré
    if (!CrashReportingConfig.isConfigured) {
      debugPrint('Sentry: DSN not configured, skipping initialization');
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = CrashReportingConfig.sentryDsn;
        options.environment = CrashReportingConfig.environment;

        // Configuration pour le debug
        options.debug = kDebugMode;

        // Échantillonnage des traces de performance (10% en production)
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;

        // Capture automatique des erreurs non gérées
        options.attachStacktrace = true;

        // Breadcrumbs pour le contexte
        options.maxBreadcrumbs = 100;

        // Ne pas envoyer les rapports en mode debug (optionnel)
        // options.beforeSend = kDebugMode ? (event, hint) => null : null;
      },
    );

    _isInitialized = true;
    debugPrint('Sentry: Initialized successfully');
  }

  /// Capture une exception manuellement
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? message,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_isInitialized) {
      debugPrint('Sentry: Not initialized, logging locally: $exception');
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (message != null) {
          scope.setContexts('message', {'value': message});
        }
        if (extra != null) {
          scope.setContexts('extra', extra);
        }
        scope.level = level;
      },
    );
  }

  /// Capture un message (pour les erreurs non-exception)
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) {
      debugPrint('Sentry: Not initialized, logging locally: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) {
          scope.setContexts('extra', extra);
        }
      },
    );
  }

  /// Ajoute un breadcrumb pour le contexte
  static Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_isInitialized) return;

    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Définit l'utilisateur courant pour le contexte
  static Future<void> setUser({
    String? id,
    String? email,
    String? username,
    Map<String, String>? extra,
  }) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      if (id != null || email != null || username != null) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
          data: extra,
        ));
      } else {
        scope.setUser(null);
      }
    });
  }

  /// Efface l'utilisateur (à appeler lors de la déconnexion)
  static Future<void> clearUser() async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Ajoute des tags pour filtrer les erreurs
  static Future<void> setTag(String key, String value) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Ajoute des données de contexte
  static Future<void> setContext(String key, Map<String, dynamic> data) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setContexts(key, data);
    });
  }

  /// Démarre une transaction de performance
  static ISentrySpan? startTransaction(String name, String operation) {
    if (!_isInitialized) return null;

    return Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
  }

  /// Wrapper pour exécuter du code avec capture d'erreur automatique
  static Future<T?> runWithErrorCapture<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      await captureException(
        e,
        stackTrace: stackTrace,
        message: operationName,
      );
      return null;
    }
  }
}

/// Extension pour capturer les erreurs facilement
extension CrashReportingExtension on Object {
  /// Capture cette erreur dans Sentry
  Future<void> reportToSentry({
    StackTrace? stackTrace,
    String? message,
  }) async {
    await CrashReportingService.captureException(
      this,
      stackTrace: stackTrace,
      message: message,
    );
  }
}
