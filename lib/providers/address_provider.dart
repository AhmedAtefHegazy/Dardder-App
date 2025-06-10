import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService;
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _error;

  AddressProvider(this._addressService);

  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectAddress(Address? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> loadAddresses(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _addressService.getUserAddresses(userId);
      if (_addresses.isNotEmpty) {
        // If there's a default address, select it
        final defaultAddress = _addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => _addresses.first,
        );
        _selectedAddress = defaultAddress;
      } else {
        _selectedAddress = null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDefaultAddress(String userId) async {
    try {
      final defaultAddress = await _addressService.getDefaultAddress(userId);
      if (defaultAddress != null) {
        _selectedAddress = defaultAddress;
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading the default address, we'll just keep the current selection
      debugPrint('Error loading default address: ${e.toString()}');
    }
  }

  Future<void> createAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // If this is the first address, ensure it's set as default
      if (_addresses.isEmpty) {
        address = address.copyWith(isDefault: true);
      }

      final newAddress = await _addressService.createAddress(address);

      // If the new address is default, update other addresses
      if (newAddress.isDefault) {
        _addresses =
            _addresses.map((addr) => addr.copyWith(isDefault: false)).toList();
      }

      // Add the new address to the list
      _addresses.add(newAddress);

      // If this is the first address or it's default, select it
      if (_addresses.length == 1 || newAddress.isDefault) {
        _selectedAddress = newAddress;
      }

      _error = null;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('IX_UserAddresses_UserId_IsDefault')) {
        errorMessage =
            'Cannot set multiple default addresses. Please unset the current default address first.';
      }
      _error = errorMessage;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAddress = await _addressService.updateAddress(address);

      // Find the index of the address to update
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        // If this address is being set as default, update other addresses first
        if (updatedAddress.isDefault) {
          _addresses = _addresses
              .map((addr) => addr.id == updatedAddress.id
                  ? addr
                  : addr.copyWith(isDefault: false))
              .toList();
        }

        // Update the address in the list
        _addresses[index] = updatedAddress;

        // If this is the selected address or it's being set as default, update selection
        if (_selectedAddress?.id == updatedAddress.id ||
            updatedAddress.isDefault) {
          _selectedAddress = updatedAddress;
        }
      }

      _error = null;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('IX_UserAddresses_UserId_IsDefault')) {
        errorMessage =
            'Cannot set multiple default addresses. Please unset the current default address first.';
      }
      _error = errorMessage;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressService.deleteAddress(id);

      // Remove the address from the list
      final deletedAddress = _addresses.firstWhere((a) => a.id == id);
      _addresses.removeWhere((a) => a.id == id);

      // If we deleted the selected address or the default address, select another one if available
      if (_selectedAddress?.id == id || deletedAddress.isDefault) {
        if (_addresses.isNotEmpty) {
          // Try to find a new default address
          final newDefault = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
          _selectedAddress = newDefault;

          // If there was no default address, make the first one default
          if (!newDefault.isDefault) {
            final updatedAddress = newDefault.copyWith(isDefault: true);
            await updateAddress(updatedAddress);
          }
        } else {
          _selectedAddress = null;
        }
      }

      _error = null;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('IX_UserAddresses_UserId_IsDefault')) {
        errorMessage = 'Error setting default address. Please try again.';
      }
      _error = errorMessage;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
