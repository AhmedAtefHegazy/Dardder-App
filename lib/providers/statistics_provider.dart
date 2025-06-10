import 'package:flutter/material.dart';
import '../services/statistics_service.dart';

class StatisticsProvider with ChangeNotifier {
  final StatisticsService _service;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistics = {};

  StatisticsProvider(this._service);

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;

  Future<void> loadStatistics() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _statistics = await _service.getStatistics();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper getters for specific statistics
  int get totalUsers => _statistics['totalUsers'] ?? 0;
  int get activeUsers => _statistics['activeUsers'] ?? 0;
  int get totalProducts => _statistics['totalProducts'] ?? 0;
  int get lowStockProducts => _statistics['lowStockProducts'] ?? 0;
  int get totalOrders => _statistics['totalOrders'] ?? 0;
  int get pendingOrders => _statistics['pendingOrders'] ?? 0;
  double get totalRevenue => _statistics['totalRevenue']?.toDouble() ?? 0.0;
  double get monthlyRevenue => _statistics['monthlyRevenue']?.toDouble() ?? 0.0;
  List<Map<String, dynamic>> get revenueChart =>
      List<Map<String, dynamic>>.from(_statistics['revenueChart'] ?? []);
  List<Map<String, dynamic>> get orderStatusChart =>
      List<Map<String, dynamic>>.from(_statistics['orderStatusChart'] ?? []);
}
