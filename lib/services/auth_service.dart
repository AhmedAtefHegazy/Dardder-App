import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint);
    debugPrint('Attempting to login at: ${url.toString()}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login response status code: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        if (token != null) {
          await storage.write(key: 'token', value: token);
          return responseData;
        } else {
          throw Exception('Token not found in response');
        }
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> register(String email, String password) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.registerEndpoint);
    debugPrint('Attempting to register at: ${url.toString()}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Register response status code: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final url =
        Uri.parse(ApiConstants.baseUrl + ApiConstants.userProfileEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get user profile error: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
}
