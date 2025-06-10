import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../config/api_config.dart';

class CategoryService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client;

  CategoryService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Category>> getCategories() async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.get(
                Uri.parse('$baseUrl/api/categories'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<Category> createCategory({
    required String name,
    required String description,
  }) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.post(
                Uri.parse('$baseUrl/api/categories'),
                headers: await ApiConfig.getHeaders(),
                body: json.encode({
                  'name': name,
                  'description': description,
                }),
              ));

      if (response.statusCode == 201) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<Category> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.put(
                Uri.parse('$baseUrl/api/categories/$id'),
                headers: await ApiConfig.getHeaders(),
                body: json.encode({
                  'id': id,
                  'name': name,
                  'description': description,
                }),
              ));

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else if (response.statusCode == 204) {
        return Category(
          id: id,
          name: name,
          description: description,
        );
      } else {
        throw Exception(
            'Failed to update category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.delete(
                Uri.parse('$baseUrl/api/categories/$id'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
