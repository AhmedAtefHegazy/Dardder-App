import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get total => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final CartService _cartService;
  Map<String, CartItem> _items = {};
  String? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  CartProvider(this._cartService);

  Map<String, CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRefreshing => _isRefreshing;

  double get total => _items.values.fold(
        0,
        (sum, item) => sum + item.total,
      );

  int get itemCount => _items.values.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  bool isInCart(String productId) => _items.containsKey(productId);

  double get totalAmount {
    return _items.values
        .fold(0.0, (sum, item) => sum + (item.quantity * item.product.price));
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? value) {
    if (_error != value) {
      _error = value;
      notifyListeners();
    }
  }

  void _setRefreshing(bool value) {
    if (_isRefreshing != value) {
      _isRefreshing = value;
      notifyListeners();
    }
  }

  void updateAuth(String? userId) {
    _currentUser = userId;
    if (userId != null) {
      refresh();
    } else {
      _items.clear();
      _setError(null);
    }
  }

  Future<void> refresh() async {
    if (_currentUser == null) return;

    try {
      _setRefreshing(true);
      _setError(null);

      final items = await _cartService.getCartItems(_currentUser!);
      _items.clear();
      for (var item in items) {
        _items[item.product.id] = item;
      }
      _setError(null);
    } catch (e) {
      _setError('Failed to load cart items: ${e.toString()}');
    } finally {
      _setRefreshing(false);
    }
  }

  Future<void> loadCart() => refresh();

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_currentUser == null) {
      _setError('Please log in to add items to cart');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      final cartItem = await _cartService.addToCart(
        _currentUser!,
        product.id,
        quantity,
      );

      _items[product.id] = cartItem;
      _setError(null);
      notifyListeners(); // Notify for items change
    } catch (e) {
      _setError('Failed to add item to cart: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final cartItem = await _cartService.updateCartItem(
        _currentUser!,
        productId,
        quantity,
      );

      _items[productId] = cartItem;
      _setError(null);
      notifyListeners(); // Notify for items change
    } catch (e) {
      _setError('Failed to update quantity: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      await _cartService.removeFromCart(_currentUser!, productId);
      _items.remove(productId);
      _setError(null);
      notifyListeners(); // Notify for items change
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearCart() async {
    try {
      _setLoading(true);

      await _cartService.clearCart();
      _items = {};
      _setError(null);
      notifyListeners(); // Notify for items change
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
