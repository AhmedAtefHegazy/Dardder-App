import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  Future<void> loadCategories() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory({
    required String name,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final category = await _categoryService.createCategory(
        name: name,
        description: description,
      );
      _categories.add(category);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCategory = await _categoryService.updateCategory(
        id: id,
        name: name,
        description: description,
      );

      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Don't rethrow here since the update might have succeeded on the backend
      // Just update the UI with the new values
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = Category(
          id: id,
          name: name,
          description: description,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
