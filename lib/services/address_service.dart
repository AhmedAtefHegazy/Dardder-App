import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/address.dart';

class AddressService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await ApiConfig.handleRequest(() async {
        final headers = await ApiConfig.getHeaders();
        return await http.get(
          Uri.parse('$baseUrl/api/UserAddress/user/$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Address.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load addresses');
      }
    } catch (e) {
      throw Exception('Failed to load addresses: ${e.toString()}');
    }
  }

  Future<Address> createAddress(Address address) async {
    try {
      final Map<String, dynamic> addressData = {
        'userId': address.userId,
        'fullName': address.fullName,
        'streetAddress': address.streetAddress,
        'city': address.city,
        'phone': address.phone,
        'deliveryInstructions': address.deliveryInstructions,
        'isDefault': address.isDefault,
      };

      final response = await ApiConfig.handleRequest(() async {
        final headers = await ApiConfig.getHeaders();
        return await http.post(
          Uri.parse('$baseUrl/api/UserAddress'),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
          body: json.encode(addressData),
        );
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else {
        final error = json.decode(response.body);
        if (error['message']
                ?.toString()
                .contains('IX_UserAddresses_UserId_IsDefault') ??
            false) {
          throw Exception(
              'Cannot set multiple default addresses. Please unset the current default address first.');
        }
        throw Exception(error['message'] ?? 'Failed to create address');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Server error: Please try again');
      }
      rethrow;
    }
  }

  Future<Address> updateAddress(Address address) async {
    try {
      final Map<String, dynamic> addressData = {
        'id': address.id,
        'userId': address.userId,
        'fullName': address.fullName,
        'streetAddress': address.streetAddress,
        'city': address.city,
        'phone': address.phone,
        'deliveryInstructions': address.deliveryInstructions,
        'isDefault': address.isDefault,
      };

      final response = await ApiConfig.handleRequest(() async {
        final headers = await ApiConfig.getHeaders();
        return await http.put(
          Uri.parse('$baseUrl/api/UserAddress/${address.id}'),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
          body: json.encode(addressData),
        );
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.body.isEmpty) {
          return address;
        }
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else {
        final error = json.decode(response.body);
        if (error['message']
                ?.toString()
                .contains('IX_UserAddresses_UserId_IsDefault') ??
            false) {
          throw Exception(
              'Cannot set multiple default addresses. Please unset the current default address first.');
        }
        throw Exception(error['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Server error: Please try again');
      }
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      final response = await ApiConfig.handleRequest(() async {
        final headers = await ApiConfig.getHeaders();
        return await http.delete(
          Uri.parse('$baseUrl/api/UserAddress/$id'),
          headers: headers,
        );
      });

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      throw Exception('Failed to delete address: ${e.toString()}');
    }
  }

  Future<Address?> getDefaultAddress(String userId) async {
    try {
      final response = await ApiConfig.handleRequest(() async {
        final headers = await ApiConfig.getHeaders();
        return await http.get(
          Uri.parse('$baseUrl/api/UserAddress/default/$userId'),
          headers: headers,
        );
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get default address');
      }
    } catch (e) {
      throw Exception('Failed to get default address: ${e.toString()}');
    }
  }
}
