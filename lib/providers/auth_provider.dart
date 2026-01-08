import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_profile.dart';
import '../services/supabase_service.dart';

/// Provider pour l'authentification
class AuthProvider extends ChangeNotifier {
  User? _user;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _init();
  }

  User? get user => _user;
  UserProfile? get profile => _profile;
  String? get userId => _user?.id;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    // Écouter les changements d'auth
    SupabaseService.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });

    // Charger l'utilisateur actuel
    _user = SupabaseService.currentUser;
    if (_user != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await SupabaseService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Inscription
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de l\'inscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Connexion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Identifiants incorrects';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.signOut();
      _user = null;
      _profile = null;
    } catch (e) {
      _error = 'Erreur lors de la déconnexion';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour le profil
  Future<bool> updateProfile(UserProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateProfile(profile);
      _profile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du profil';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Recharge le profil
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  /// Supprime le compte utilisateur
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteAccount();
      _user = null;
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression du compte';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Traduit les erreurs d'authentification
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email';
    }
    if (message.contains('User already registered')) {
      return 'Cet email est déjà utilisé';
    }
    if (message.contains('Password should be at least')) {
      return 'Le mot de passe doit faire au moins 6 caractères';
    }
    if (message.contains('Invalid email')) {
      return 'Email invalide';
    }
    return message;
  }
}
