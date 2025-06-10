import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_address.dart';

class AddressForm extends StatefulWidget {
  final Map<String, String> formData;
  final bool showSaveOption;

  const AddressForm({
    Key? key,
    required this.formData,
    this.showSaveOption = true,
  }) : super(key: key);

  @override
  AddressFormState createState() => AddressFormState();
}

class AddressFormState extends State<AddressForm> {
  bool _saveAddress = false;
  bool _makeDefault = false;
  UserAddress? _selectedAddress;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer loading addresses to after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAddresses();
    });
  }

  Future<void> _loadSavedAddresses() async {
    if (_isInitialized) return;

    final addressProvider = context.read<UserAddressProvider>();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      await addressProvider.loadAddresses();
      if (mounted) {
        setState(() {
          _selectedAddress = addressProvider.defaultAddress;
          if (_selectedAddress != null) {
            _updateFormWithAddress(_selectedAddress!);
          }
          _isInitialized = true;
        });
      }
    }
  }

  void _updateFormWithAddress(UserAddress address) {
    widget.formData['fullName'] = address.fullName;
    widget.formData['streetAddress'] = address.streetAddress;
    widget.formData['city'] = address.city;
    widget.formData['phone'] = address.phone;
    widget.formData['deliveryInstructions'] =
        address.deliveryInstructions ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserAddressProvider, AuthProvider>(
      builder: (context, addressProvider, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildForm(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (addressProvider.addresses.isNotEmpty) ...[
              DropdownButtonFormField<UserAddress>(
                value: _selectedAddress,
                decoration: const InputDecoration(
                  labelText: 'Saved Addresses',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<UserAddress>(
                    value: null,
                    child: Text('New Address'),
                  ),
                  ...addressProvider.addresses.map((address) {
                    return DropdownMenuItem<UserAddress>(
                      value: address,
                      child: Text(
                          '${address.fullName} - ${address.streetAddress}'),
                    );
                  }).toList(),
                ],
                onChanged: (UserAddress? value) {
                  setState(() {
                    _selectedAddress = value;
                    if (value != null) {
                      _updateFormWithAddress(value);
                    } else {
                      widget.formData.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            _buildForm(context),
            if (widget.showSaveOption && _selectedAddress == null) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Save this address'),
                value: _saveAddress,
                onChanged: (bool? value) {
                  setState(() {
                    _saveAddress = value ?? false;
                    if (!_saveAddress) {
                      _makeDefault = false;
                    }
                  });
                },
              ),
              if (_saveAddress)
                CheckboxListTile(
                  title: const Text('Make this my default address'),
                  value: _makeDefault,
                  onChanged: (bool? value) {
                    setState(() {
                      _makeDefault = value ?? false;
                    });
                  },
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: widget.formData['fullName'],
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
          onSaved: (value) {
            widget.formData['fullName'] = value ?? '';
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.formData['streetAddress'],
          decoration: const InputDecoration(
            labelText: 'Street Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your street address';
            }
            return null;
          },
          onSaved: (value) {
            widget.formData['streetAddress'] = value ?? '';
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.formData['city'],
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your city';
            }
            return null;
          },
          onSaved: (value) {
            widget.formData['city'] = value ?? '';
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.formData['phone'],
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
          onSaved: (value) {
            widget.formData['phone'] = value ?? '';
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: widget.formData['deliveryInstructions'],
          decoration: const InputDecoration(
            labelText: 'Delivery Instructions (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSaved: (value) {
            widget.formData['deliveryInstructions'] = value ?? '';
          },
        ),
      ],
    );
  }

  Future<void> saveAddress() async {
    if (!_saveAddress || _selectedAddress != null) return;

    final addressProvider = context.read<UserAddressProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) return;

    try {
      await addressProvider.createAddress({
        'fullName': widget.formData['fullName']!,
        'streetAddress': widget.formData['streetAddress']!,
        'city': widget.formData['city']!,
        'phone': widget.formData['phone']!,
        'deliveryInstructions': widget.formData['deliveryInstructions'],
        'isDefault': _makeDefault,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
