import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_address.dart';
import '../config/api_config.dart';

class UserAddressService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client;

  UserAddressService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<UserAddress>> getUserAddresses(String userId) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.get(
                Uri.parse('$baseUrl/api/users/$userId/addresses'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserAddress.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load addresses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  Future<UserAddress> createAddress(
      String userId, Map<String, dynamic> addressData) async {
    try {
      addressData['userId'] = userId;
      final response =
          await ApiConfig.handleRequest(() async => await _client.post(
                Uri.parse('$baseUrl/api/users/$userId/addresses'),
                headers: await ApiConfig.getHeaders(),
                body: json.encode(addressData),
              ));

      if (response.statusCode == 201) {
        return UserAddress.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  Future<UserAddress> updateAddress(
      String userId, String addressId, Map<String, dynamic> addressData) async {
    try {
      addressData['userId'] = userId;
      final response =
          await ApiConfig.handleRequest(() async => await _client.put(
                Uri.parse('$baseUrl/api/users/$userId/addresses/$addressId'),
                headers: await ApiConfig.getHeaders(),
                body: json.encode(addressData),
              ));

      if (response.statusCode == 200) {
        return UserAddress.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.delete(
                Uri.parse('$baseUrl/api/users/$userId/addresses/$addressId'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      final response =
          await ApiConfig.handleRequest(() async => await _client.put(
                Uri.parse(
                    '$baseUrl/api/users/$userId/addresses/$addressId/default'),
                headers: await ApiConfig.getHeaders(),
              ));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set default address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }
}
