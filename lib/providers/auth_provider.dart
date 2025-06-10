import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  final FlutterSecureStorage _storage;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  AuthProvider(this._storage) {
    // Initialize by checking auth status
    checkAuthStatus();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isInitialized => _initialized;

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

  void _setUser(User? value) {
    if (_user?.id != value?.id) {
      _user = value;
      notifyListeners();
    }
  }

  Future<void> _saveUserData(
      Map<String, dynamic> userData, String token) async {
    try {
      // Save token
      await _storage.write(key: 'token', value: token);

      // Save user data
      await _storage.write(key: 'userData', value: json.encode(userData));

      final user = User(
        id: userData['id']?.toString() ?? '',
        name: userData['name']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        role: userData['role']?.toString() ?? 'user',
        createdAt: DateTime.tryParse(userData['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(userData['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        isActive: userData['isActive'] ?? true,
      );

      _setUser(user);
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      }

      if (response.statusCode != 200) {
        throw Exception('Unable to login. Please try again.');
      }

      final userData = json.decode(response.body);
      final token = userData['token'];

      if (token == null) {
        throw Exception('Unable to login. Please try again.');
      }

      await _saveUserData(userData, token);
      _setError(null);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 400) {
        throw Exception(data['message'] ?? 'Email is already registered');
      }

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Unable to create account. Please try again.');
      }

      final token = data['token'];
      final userData = data['user'] ?? data;
      await _saveUserData(userData, token);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await ApiConfig.clearStoredData();
      await _storage.deleteAll();
      _setUser(null);
    } catch (e) {
      // Even if there's an error, we should still clear the user
      _setUser(null);
      rethrow;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      _setError(null);

      final token = await _storage.read(key: 'token');
      final userDataStr = await _storage.read(key: 'userData');

      if (token == null || userDataStr == null) {
        await logout();
        return;
      }

      try {
        final userData = json.decode(userDataStr);
        final user = User(
          id: userData['id']?.toString() ?? '',
          name: userData['name']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          role: userData['role']?.toString() ?? 'user',
          createdAt:
              DateTime.tryParse(userData['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
          updatedAt:
              DateTime.tryParse(userData['updatedAt']?.toString() ?? '') ??
                  DateTime.now(),
          isActive: userData['isActive'] ?? true,
        );
        _setUser(user);
      } catch (e) {
        await logout();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data is Map<String, dynamic>) {
            await _saveUserData(data, token);
          } else {
            await logout();
          }
        } else {
          await logout();
        }
      } catch (e) {
        await logout();
      }
    } catch (e) {
      await logout();
    } finally {
      _initialized = true;
      _setLoading(false);
    }
  }

  Future<void> refreshToken() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final response = await ApiConfig.handleRequest(() => http.post(
            Uri.parse('${ApiConfig.getBaseUrl()}/api/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['token'];
        await _storage.write(key: 'token', value: newToken);
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }
}
