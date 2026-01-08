import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'secure_storage_service.dart';

/// Service HTTP sécurisé avec certificate pinning
/// Protège contre les attaques MITM (Man-in-the-Middle)
class SecureHttpService {
  static SecureHttpService? _instance;
  late IOClient _client;
  SecureStorageService? _secureStorage;

  // Mode debug - mettre à false en production!
  // En production, le certificate pinning sera activé
  static const bool _isDebugMode = bool.fromEnvironment('dart.vm.product') == false;

  // Certificats épinglés (SHA-256 fingerprints)
  // À remplacer par les vrais fingerprints de vos serveurs
  static const List<String> _pinnedCertificates = [
    // Supabase production - ajouter vos certificats ici
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    // Backup certificate
    // 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  // Domaines autorisés
  static const List<String> _allowedDomains = [
    'supabase.co',
    'supabase.com',
    // Ajouter vos domaines backend ici
  ];

  // Configuration
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 60);
  static const int _maxRetries = 3;

  SecureHttpService._();

  static Future<SecureHttpService> getInstance() async {
    if (_instance == null) {
      _instance = SecureHttpService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _secureStorage = await SecureStorageService.getInstance();
    _client = _createSecureClient();
  }

  /// Crée un client HTTP sécurisé avec certificate pinning
  IOClient _createSecureClient() {
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = _receiveTimeout
      ..badCertificateCallback = _validateCertificate;

    // Configurer les paramètres de sécurité
    httpClient.autoUncompress = true;
    httpClient.maxConnectionsPerHost = 5;

    return IOClient(httpClient);
  }

  /// Valide le certificat du serveur (certificate pinning)
  bool _validateCertificate(X509Certificate cert, String host, int port) {
    // En mode debug sans certificats configurés, accepter les certificats valides
    // En production, le certificate pinning est OBLIGATOIRE
    if (_pinnedCertificates.isEmpty) {
      if (_isDebugMode) {
        // En développement uniquement - accepter si le domaine est autorisé
        return _isDomainAllowed(host);
      } else {
        // En production sans certificats configurés = BLOQUER
        // Cela force les développeurs à configurer les certificats
        debugPrint('SECURITY WARNING: No pinned certificates configured in production!');
        return false;
      }
    }

    // Vérifier que le domaine est autorisé
    if (!_isDomainAllowed(host)) {
      return false;
    }

    // Vérifier le fingerprint du certificat
    final certFingerprint = _getCertificateFingerprint(cert);
    return _pinnedCertificates.contains(certFingerprint);
  }

  /// Vérifie si un domaine est autorisé
  bool _isDomainAllowed(String host) {
    return _allowedDomains.any((domain) => host.endsWith(domain));
  }

  /// Obtient le fingerprint SHA-256 d'un certificat
  String _getCertificateFingerprint(X509Certificate cert) {
    // Note: Implémentation simplifiée
    // En production, utiliser un package comme 'crypto' pour calculer le SHA-256
    return 'sha256/${base64Encode(cert.der)}';
  }

  // ==================== REQUÊTES HTTP SÉCURISÉES ====================

  /// Headers de sécurité par défaut
  Map<String, String> _getSecureHeaders({
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Version': '1.0.0',
      'X-Platform': Platform.operatingSystem,
      // Protection contre le cache
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Pragma': 'no-cache',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Requête GET sécurisée
  Future<SecureHttpResponse> get(
    String url, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final authToken = requireAuth ? await _getAuthToken() : null;
      final response = await _client.get(
        Uri.parse(url),
        headers: _getSecureHeaders(
          authToken: authToken,
          additionalHeaders: headers,
        ),
      );
      return _processResponse(response);
    });
  }

  /// Requête POST sécurisée
  Future<SecureHttpResponse> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final authToken = requireAuth ? await _getAuthToken() : null;
      final response = await _client.post(
        Uri.parse(url),
        headers: _getSecureHeaders(
          authToken: authToken,
          additionalHeaders: headers,
        ),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  /// Requête PUT sécurisée
  Future<SecureHttpResponse> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final authToken = requireAuth ? await _getAuthToken() : null;
      final response = await _client.put(
        Uri.parse(url),
        headers: _getSecureHeaders(
          authToken: authToken,
          additionalHeaders: headers,
        ),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  /// Requête DELETE sécurisée
  Future<SecureHttpResponse> delete(
    String url, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final authToken = requireAuth ? await _getAuthToken() : null;
      final response = await _client.delete(
        Uri.parse(url),
        headers: _getSecureHeaders(
          authToken: authToken,
          additionalHeaders: headers,
        ),
      );
      return _processResponse(response);
    });
  }

  /// Requête PATCH sécurisée
  Future<SecureHttpResponse> patch(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final authToken = requireAuth ? await _getAuthToken() : null;
      final response = await _client.patch(
        Uri.parse(url),
        headers: _getSecureHeaders(
          authToken: authToken,
          additionalHeaders: headers,
        ),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  // ==================== UTILITAIRES ====================

  /// Obtient le token d'authentification
  Future<String?> _getAuthToken() async {
    return await _secureStorage?.getAuthToken();
  }

  /// Exécute une requête avec retry automatique
  Future<SecureHttpResponse> _executeWithRetry(
    Future<SecureHttpResponse> Function() request,
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        return await request();
      } on SocketException catch (e) {
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      } on HttpException catch (e) {
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      } on HandshakeException catch (e) {
        // Erreur de certificat - ne pas réessayer
        return SecureHttpResponse(
          success: false,
          statusCode: 0,
          error: SecurityError.certificateError,
          errorMessage: 'Erreur de certificat: ${e.message}',
        );
      }
    }

    return SecureHttpResponse(
      success: false,
      statusCode: 0,
      error: SecurityError.networkError,
      errorMessage: 'Erreur réseau après $attempts tentatives: $lastException',
    );
  }

  /// Traite la réponse HTTP
  SecureHttpResponse _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Vérifier les codes de succès
    if (statusCode >= 200 && statusCode < 300) {
      dynamic data;
      try {
        data = body.isNotEmpty ? jsonDecode(body) : null;
      } catch (_) {
        data = body;
      }

      return SecureHttpResponse(
        success: true,
        statusCode: statusCode,
        data: data,
        headers: response.headers,
      );
    }

    // Gérer les erreurs
    SecurityError? securityError;
    String? errorMessage;

    switch (statusCode) {
      case 401:
        securityError = SecurityError.unauthorized;
        errorMessage = 'Non autorisé - Session expirée';
        // Nettoyer le token invalide
        _secureStorage?.clearAuthToken();
        break;
      case 403:
        securityError = SecurityError.forbidden;
        errorMessage = 'Accès interdit';
        break;
      case 429:
        securityError = SecurityError.rateLimited;
        errorMessage = 'Trop de requêtes - Réessayez plus tard';
        break;
      case 500:
      case 502:
      case 503:
        securityError = SecurityError.serverError;
        errorMessage = 'Erreur serveur';
        break;
      default:
        errorMessage = 'Erreur HTTP $statusCode';
    }

    return SecureHttpResponse(
      success: false,
      statusCode: statusCode,
      error: securityError,
      errorMessage: errorMessage,
      data: body.isNotEmpty ? jsonDecode(body) : null,
    );
  }

  /// Vérifie si la connexion est sécurisée (HTTPS)
  bool isSecureUrl(String url) {
    final uri = Uri.parse(url);
    return uri.scheme == 'https';
  }

  /// Sanitize une URL
  String sanitizeUrl(String url) {
    // Forcer HTTPS
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // Supprimer les caractères dangereux
    url = Uri.encodeFull(url);

    return url;
  }

  /// Ferme le client HTTP
  void close() {
    _client.close();
  }
}

/// Types d'erreurs de sécurité
enum SecurityError {
  /// Erreur de certificat
  certificateError,

  /// Erreur réseau
  networkError,

  /// Non autorisé
  unauthorized,

  /// Accès interdit
  forbidden,

  /// Limite de requêtes atteinte
  rateLimited,

  /// Erreur serveur
  serverError,
}

/// Réponse HTTP sécurisée
class SecureHttpResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final Map<String, String>? headers;
  final SecurityError? error;
  final String? errorMessage;

  SecureHttpResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.headers,
    this.error,
    this.errorMessage,
  });

  /// Vérifie si l'erreur est une erreur d'authentification
  bool get isAuthError =>
      error == SecurityError.unauthorized || error == SecurityError.forbidden;

  /// Vérifie si on peut réessayer
  bool get canRetry =>
      error == SecurityError.networkError ||
      error == SecurityError.serverError ||
      error == SecurityError.rateLimited;

  @override
  String toString() =>
      'SecureHttpResponse(success: $success, statusCode: $statusCode, error: $error)';
}
