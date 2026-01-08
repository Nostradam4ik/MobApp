import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/category.dart';
import '../services/supabase_service.dart';

/// Provider pour la gestion des catégories
class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Category> get categories => _categories;
  List<Category> get activeCategories =>
      _categories.where((c) => c.isActive).toList();
  List<Category> get defaultCategories =>
      _categories.where((c) => c.isDefault).toList();
  List<Category> get userCategories =>
      _categories.where((c) => !c.isDefault && c.userId == _userId).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Met à jour l'ID utilisateur et recharge les catégories
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (userId != null) {
        loadCategories();
      } else {
        _categories = [];
        notifyListeners();
      }
    }
  }

  /// Charge les catégories
  Future<void> loadCategories() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await SupabaseService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des catégories';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère une catégorie par ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Crée une nouvelle catégorie
  Future<bool> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    if (_userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final category = Category(
        id: const Uuid().v4(),
        userId: _userId,
        name: name,
        icon: icon,
        color: color,
        isDefault: false,
        isActive: true,
        sortOrder: _categories.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await SupabaseService.createCategory(category);
      _categories.add(created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création de la catégorie';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour une catégorie
  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la catégorie';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime une catégorie (soft delete)
  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression de la catégorie';
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
}
