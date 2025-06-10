import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class CartService {
  Future<List<CartItem>> getCartItems(String userId) async {
    final response = await ApiConfig.handleRequest(() async => await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/cart/$userId'),
          headers: await ApiConfig.getHeaders(),
        ));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        final product = Product(
          id: item['productId'],
          name: item['productName'],
          description: '',
          price: (item['price'] as num).toDouble(),
          imageUrl: item['productImage'],
          categoryId: '',
          categoryName: '',
          inStock: true,
          stockQuantity: 0,
        );
        return CartItem(
          product: product,
          quantity: item['quantity'],
        );
      }).toList();
    } else {
      throw Exception('Failed to load cart items');
    }
  }

  Future<CartItem> addToCart(
      String userId, String productId, int quantity) async {
    final response = await ApiConfig.handleRequest(() async => await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/cart/$userId/items'),
          headers: await ApiConfig.getHeaders(),
          body: json.encode({
            'productId': productId,
            'quantity': quantity,
          }),
        ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final product = Product(
        id: data['productId'],
        name: data['productName'],
        description: '',
        price: (data['price'] as num).toDouble(),
        imageUrl: data['productImage'],
        categoryId: '',
        categoryName: '',
        inStock: true,
        stockQuantity: 0,
      );
      return CartItem(
        product: product,
        quantity: data['quantity'],
      );
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  Future<CartItem> updateCartItem(
      String userId, String productId, int quantity) async {
    // First, get the cart items to find the correct cart item ID
    final cartItems = await getCartItems(userId);
    final cartItem = cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Item not found in cart'),
    );

    final response = await ApiConfig.handleRequest(() async => await http.put(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/cart/$userId/items/${cartItem.product.id}'),
          headers: await ApiConfig.getHeaders(),
          body: json.encode({
            'productId': productId,
            'quantity': quantity,
          }),
        ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final product = Product(
        id: data['productId'],
        name: data['productName'],
        description: '',
        price: (data['price'] as num).toDouble(),
        imageUrl: data['productImage'],
        categoryId: '',
        categoryName: '',
        inStock: true,
        stockQuantity: 0,
      );
      return CartItem(
        product: product,
        quantity: data['quantity'],
      );
    } else {
      throw Exception('Failed to update cart item');
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    try {
      // First, get the cart items to find the correct cart item ID
      final response = await ApiConfig.handleRequest(() async => await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/cart/$userId'),
            headers: await ApiConfig.getHeaders(),
          ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cartItem = data.firstWhere(
          (item) => item['productId'] == productId,
          orElse: () => throw Exception('Item not found in cart'),
        );

        final deleteResponse =
            await ApiConfig.handleRequest(() async => await http.delete(
                  Uri.parse(
                      '${ApiConfig.baseUrl}/api/cart/$userId/items/${cartItem['id']}'),
                  headers: await ApiConfig.getHeaders(),
                ));

        if (deleteResponse.statusCode != 200 &&
            deleteResponse.statusCode != 204) {
          final errorBody = json.decode(deleteResponse.body);
          throw Exception(
              errorBody['message'] ?? 'Failed to remove item from cart');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to get cart items');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<void> clearCart() async {
    final userId = (await ApiConfig.getHeaders())['UserId'];
    if (userId == null) throw Exception('User not authenticated');

    final response =
        await ApiConfig.handleRequest(() async => await http.delete(
              Uri.parse('${ApiConfig.baseUrl}/api/cart/$userId'),
              headers: await ApiConfig.getHeaders(),
            ));

    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }
}
