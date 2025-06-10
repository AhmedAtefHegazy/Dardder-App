import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client;

  UserService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<User>> getUsers() async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.get(
                Uri.parse('$baseUrl/api/auth/users'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the data is in a nested field
        final List<dynamic> usersData = responseData['data'] ??
            responseData['users'] ??
            responseData['items'] ??
            responseData['results'] ??
            [];

        return usersData.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<User> getUserById(String id) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.get(
                Uri.parse('$baseUrl/api/auth/users/$id'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to load user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<User> updateUserRole(String userId, String role) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.patch(
                Uri.parse('$baseUrl/api/auth/users/$userId/role'),
                headers: await ApiConfig.getHeaders(),
                body: json.encode({'role': role}),
              ));

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to update user role: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.patch(
                Uri.parse('$baseUrl/api/auth/users/$userId/deactivate'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to deactivate user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.patch(
                Uri.parse('$baseUrl/api/auth/users/$userId/activate'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to activate user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }
}
