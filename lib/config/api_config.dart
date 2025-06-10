import 'dart:io';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConfig {
  // Your computer's actual IP address
  static const String baseUrl = 'http://192.168.1.14:5156';

  static const storage = FlutterSecureStorage();
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Future<Map<String, String>> getHeaders() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      // If no token is found, try to refresh it
      final refreshed = await _refreshToken();
      if (!refreshed) {
        throw Exception('User not authenticated');
      }
    }

    final currentToken = await storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (currentToken != null) 'Authorization': 'Bearer $currentToken',
    };
  }

  static Future<http.Response> handleRequest(
      Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeoutDuration);

      // Handle token expiration
      if (response.statusCode == 401) {
        // Try to refresh token
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request with new token
          return await request().timeout(timeoutDuration);
        } else {
          throw Exception('User not authenticated');
        }
      }

      return response;
    } on SocketException {
      throw Exception(
          'Unable to connect to server. Please check your internet connection and try again.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<bool> _refreshToken() async {
    try {
      final oldToken = await storage.read(key: 'token');
      if (oldToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oldToken',
        },
      );

      if (response.statusCode == 200) {
        // First try to get token from response body
        final responseData = await json.decode(response.body);
        String? newToken = responseData['token'];

        // If not in body, try headers
        if (newToken == null) {
          newToken =
              response.headers['authorization']?.replaceAll('Bearer ', '') ??
                  response.headers['Authorization']?.replaceAll('Bearer ', '');
        }

        if (newToken != null) {
          await storage.write(key: 'token', value: newToken);
          return true;
        }
      }

      // If refresh failed, clear stored data
      await clearStoredData();
      return false;
    } catch (e) {
      await clearStoredData();
      return false;
    }
  }

  static String getBaseUrl() {
    return baseUrl;
  }

  static Future<void> clearStoredData() async {
    await storage.deleteAll();
  }
}
