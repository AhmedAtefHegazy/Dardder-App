import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  User? _currentUser;

  OrderProvider(this._orderService);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Order> get pendingOrders =>
      orders.where((order) => order.status == OrderStatus.Pending).toList();

  void updateAuth(User? user) {
    _currentUser = user;
    if (user != null) {
      loadOrders(); // Always try to load orders when auth changes
    } else {
      _orders = [];
      _error = null;
      _isInitialized = false;
      notifyListeners();
    }
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

  void _setOrders(List<Order> value) {
    _orders = value;
    notifyListeners();
  }

  Future<void> loadOrders() async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _setError(null);

      final orders = await _orderService.getOrders();
      _setOrders(orders);
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to load orders: $e');
      _orders = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Order?> getOrderById(String id) async {
    try {
      return await _orderService.getOrderById(id);
    } catch (e) {
      _setError('Failed to get order: $e');
      return null;
    }
  }

  Future<Order?> createOrder(Order order) async {
    try {
      _setLoading(true);
      _setError(null);

      final createdOrder = await _orderService.createOrder(order);

      // Refresh the orders list to ensure we have the latest data
      await loadOrders();

      return createdOrder;
    } catch (e) {
      _setError(
          'Failed to create order: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      _setLoading(true);
      _setError(null);

      await _orderService.updateOrderStatus(orderId, newStatus);

      // Update the local order status
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: newStatus);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _orderService.deleteOrder(orderId);
      _orders.removeWhere((order) => order.id == orderId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
