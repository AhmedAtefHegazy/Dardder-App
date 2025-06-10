import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';

class AddressFormScreen extends StatefulWidget {
  final bool isEditing;
  final Address? address;

  const AddressFormScreen({
    Key? key,
    this.isEditing = false,
    this.address,
  }) : super(key: key);

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  bool _isDefault = false;

  late final TextEditingController _fullNameController;
  late final TextEditingController _streetAddressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _deliveryInstructionsController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.address?.fullName);
    _streetAddressController =
        TextEditingController(text: widget.address?.streetAddress);
    _cityController = TextEditingController(text: widget.address?.city);
    _phoneController = TextEditingController(text: widget.address?.phone);
    _deliveryInstructionsController =
        TextEditingController(text: widget.address?.deliveryInstructions);
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Street Address
            TextFormField(
              controller: _streetAddressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'Enter your street address',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter your city',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixText: '+',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Delivery Instructions
            TextFormField(
              controller: _deliveryInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Delivery Instructions (Optional)',
                hintText: 'Add any special delivery instructions',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Set as Default
            SwitchListTile(
              title: const Text('Set as Default Address'),
              value: _isDefault,
              onChanged: (bool value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('SAVE ADDRESS'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final addressProvider = context.read<AddressProvider>();
      Address address = Address(
        id: widget.address?.id ?? '',
        userId: userId,
        fullName: _fullNameController.text.trim(),
        streetAddress: _streetAddressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryInstructions:
            _deliveryInstructionsController.text.trim().isEmpty
                ? null
                : _deliveryInstructionsController.text.trim(),
        isDefault: _isDefault,
      );

      // If this is the first address, force it to be default
      if (addressProvider.addresses.isEmpty) {
        address = address.copyWith(isDefault: true);
      }

      if (widget.isEditing) {
        await addressProvider.updateAddress(address);
      } else {
        await addressProvider.createAddress(address);
      }

      // Refresh the addresses list
      if (mounted) {
        await addressProvider.loadAddresses(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Address updated successfully'
                : 'Address added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Handle specific error cases
        if (errorMessage.contains('IX_UserAddresses_UserId_IsDefault')) {
          errorMessage =
              'Cannot set multiple default addresses. Please unset the current default address first.';
        } else if (errorMessage.contains('FormatException')) {
          errorMessage = 'Server error: Please try again';
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });

        // Show error in snackbar for better visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'DISMISS',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
}
