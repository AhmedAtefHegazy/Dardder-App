import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../config/api_config.dart';

class OrderService {
  Future<List<Order>> getOrders() async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await ApiConfig.handleRequest(() async => await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/orders'),
            headers: headers,
          ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get orders (${response.statusCode}): ${response.body}');
      }

      final data = json.decode(response.body);
      if (data is List) {
        return data.map((item) => Order.fromJson(item)).toList();
      } else if (data is Map<String, dynamic>) {
        final List<dynamic>? ordersList = data['orders'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data['items'] as List<dynamic>?;
        if (ordersList != null) {
          return ordersList.map((item) => Order.fromJson(item)).toList();
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  Future<Order> getOrderById(String id) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await ApiConfig.handleRequest(() async => await http.get(
            Uri.parse('${ApiConfig.getBaseUrl()}/api/orders/$id'),
            headers: headers,
          ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  Future<Order> createOrder(Order order) async {
    try {
      final headers = await ApiConfig.getHeaders();

      // Create a flattened order structure
      final orderData = {
        'userId': order.userId,
        'userName': order.userName,
        'userEmail': order.userEmail,
        'totalAmount': order.totalAmount,
        'status': order.status.index,
        'shippingAddress': order.shippingAddress,
        'paymentMethod': order.paymentMethod,
        'items': order.items
            .map((item) => {
                  'productId': item.productId,
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'price': item.price,
                })
            .toList(),
      };

      final response =
          await ApiConfig.handleRequest(() async => await http.post(
                Uri.parse('${ApiConfig.baseUrl}/api/orders'),
                headers: headers,
                body: json.encode(orderData),
              ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ??
            errorData['details'] ??
            'Failed to create order (${response.statusCode}): ${response.body}');
      }

      final data = json.decode(response.body);
      if (data == null) {
        throw Exception('Invalid response: no data received');
      }

      return Order.fromJson(data);
    } catch (e) {
      if (e.toString().contains('User not authenticated')) {
        throw Exception('Please log in to place an order');
      }
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> updateOrder(Order order) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response = await ApiConfig.handleRequest(() async => await http.put(
            Uri.parse('${ApiConfig.baseUrl}/api/orders/${order.id}'),
            headers: headers,
            body: json.encode({
              'userId': order.userId,
              'userName': order.userName,
              'userEmail': order.userEmail,
              'totalAmount': order.totalAmount,
              'status': order.status.index,
              'shippingAddress': order.shippingAddress,
              'paymentMethod': order.paymentMethod,
              'items': order.items
                  .map((item) => ({
                        'productId': item.productId,
                        'quantity': item.quantity,
                        'price': item.price,
                      }))
                  .toList(),
            }),
          ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update order (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response =
          await ApiConfig.handleRequest(() async => await http.patch(
                Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId/status'),
                headers: headers,
                body: json.encode({'status': newStatus.index}),
              ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update order status (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      final headers = await ApiConfig.getHeaders();
      final response =
          await ApiConfig.handleRequest(() async => await http.delete(
                Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId'),
                headers: headers,
              ));

      if (response.statusCode == 401) {
        throw Exception('User not authenticated');
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete order (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }
}
