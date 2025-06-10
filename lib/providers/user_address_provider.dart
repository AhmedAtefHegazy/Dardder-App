import 'package:flutter/material.dart';
import '../models/user_address.dart';
import '../models/user.dart';
import '../services/user_address_service.dart';

class UserAddressProvider with ChangeNotifier {
  final UserAddressService _addressService = UserAddressService();
  List<UserAddress> _addresses = [];
  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  List<UserAddress> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserAddress? get defaultAddress {
    try {
      return _addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () =>
            _addresses.isNotEmpty ? _addresses.first : throw Exception(),
      );
    } catch (_) {
      return null;
    }
  }

  void updateAuth(User? user) {
    _currentUser = user;
    if (user != null) {
      loadAddresses();
    } else {
      _addresses = [];
      _error = null;
      notifyListeners();
    }
  }

  Future<void> loadAddresses() async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _addresses = await _addressService.getUserAddresses(_currentUser!.id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserAddress> createAddress(Map<String, dynamic> addressData) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final address =
          await _addressService.createAddress(_currentUser!.id, addressData);
      _addresses.add(address);
      _error = null;
      return address;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserAddress> updateAddress(
      String addressId, Map<String, dynamic> addressData) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedAddress = await _addressService.updateAddress(
          _currentUser!.id, addressId, addressData);
      final index = _addresses.indexWhere((a) => a.id == addressId);
      if (index != -1) {
        _addresses[index] = updatedAddress;
      }
      _error = null;
      return updatedAddress;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _addressService.deleteAddress(_currentUser!.id, addressId);
      _addresses.removeWhere((a) => a.id == addressId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _addressService.setDefaultAddress(_currentUser!.id, addressId);

      // Update local state
      for (var i = 0; i < _addresses.length; i++) {
        final isCurrentAddress = _addresses[i].id == addressId;
        if (_addresses[i].isDefault != isCurrentAddress) {
          _addresses[i] = _addresses[i].copyWith(isDefault: isCurrentAddress);
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
