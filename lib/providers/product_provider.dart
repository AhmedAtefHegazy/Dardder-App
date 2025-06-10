import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service;
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _isInitialized = false;
  User? _currentUser;

  ProductProvider([ProductService? service])
      : _service = service ?? ProductService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Product> get products => _filteredProducts.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedCategory.isEmpty
      ? _products
      : _filteredProducts;

  void updateAuth(User? user) {
    _currentUser = user;
    if (user != null && !_isInitialized) {
      loadProducts();
    } else if (user == null) {
      _products = [];
      _error = null;
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    if (_isLoading || _isInitialized || _currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getProducts();
      _applyFilters();
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    _isLoading = true;
    _error = null;
    _products = [];
    _filteredProducts = [];
    _isInitialized = false;
    notifyListeners();

    try {
      _products = await _service.getProducts();
      _applyFilters();
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _products = [];
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createProduct(product);
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.updateProduct(id, product);
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteProduct(id);
      await refreshProducts(); // Refresh the entire list after successful deletion
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

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String categoryId) {
    _selectedCategory = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products;

    // Apply category filter
    if (_selectedCategory.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) => product.categoryId == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery) ||
              product.description.toLowerCase().contains(_searchQuery) ||
              product.categoryName.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }
}
