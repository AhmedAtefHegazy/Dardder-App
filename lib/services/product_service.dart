import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/product.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final AuthService _authService = AuthService();

  Future<List<Product>> getProducts() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.productsEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Products response status: ${response.statusCode}');
      debugPrint('Products response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> productsJson;

        if (responseData is Map<String, dynamic>) {
          // Handle wrapped response
          productsJson = responseData['Products'] as List<dynamic>? ??
              responseData['products'] as List<dynamic>? ??
              responseData['data'] as List<dynamic>? ??
              responseData['items'] as List<dynamic>? ??
              [];
        } else if (responseData is List<dynamic>) {
          // Handle direct array response
          productsJson = responseData;
        } else {
          throw Exception('Invalid response format from server');
        }

        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> getProduct(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/$id');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.productsEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/$id');
    try {
      debugPrint('Updating product with ID: $id');
      debugPrint('Request body: ${json.encode(product.toJson())}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(product.toJson()),
      );

      debugPrint('Update response status: ${response.statusCode}');
      debugPrint('Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.body.isEmpty) {
          // If no content returned, return the original product
          return product;
        }
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update product: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/$id');
    try {
      debugPrint('Deleting product with ID: $id');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete response status: ${response.statusCode}');
      debugPrint('Delete response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }
}
