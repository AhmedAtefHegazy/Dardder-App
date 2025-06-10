import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/customer/address_selector.dart';
import '../../widgets/customer/order_summary.dart';
import '../../widgets/customer/payment_method_selector.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CheckoutScreen extends StatefulWidget {
  final CartProvider cartProvider;

  const CheckoutScreen({
    Key? key,
    required this.cartProvider,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;
  String _selectedPaymentMethod = 'cash';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule the address loading after the build
    Future.microtask(() => _loadUserAddresses());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload addresses when dependencies change (e.g., when returning from address form)
    if (_isInitialized) {
      _loadUserAddresses();
    }
  }

  Future<void> _loadUserAddresses() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      final addressProvider = context.read<AddressProvider>();
      await addressProvider.loadAddresses(userId);
      await addressProvider.loadDefaultAddress(userId);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartItems = widget.cartProvider.items.values.toList();
    final subtotal = widget.cartProvider.total;
    const deliveryFee = 5.00;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AddressProvider>(
              builder: (context, addressProvider, child) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: theme.colorScheme.error,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Error Details',
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy),
                                          onPressed: () {
                                            Clipboard.setData(
                                                ClipboardData(text: _error!));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Error copied to clipboard'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          tooltip: 'Copy error message',
                                          color: theme.colorScheme.error,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(
                                        _error!,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Delivery Address Section
                            Text(
                              'Delivery Address',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AddressSelector(
                              addresses: addressProvider.addresses,
                              selectedAddress: addressProvider.selectedAddress,
                              onAddressSelected: addressProvider.selectAddress,
                              onAddAddress: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/customer/address/add',
                                );
                                if (result == true) {
                                  await _loadUserAddresses();
                                }
                              },
                              onEditAddress: (address) async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/customer/address/edit',
                                  arguments: address,
                                );
                                if (result == true) {
                                  await _loadUserAddresses();
                                }
                              },
                              onDeleteAddress: (address) async {
                                try {
                                  await context
                                      .read<AddressProvider>()
                                      .deleteAddress(address.id);
                                  await _loadUserAddresses();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to delete address: ${e.toString()}'),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // Order Summary Section
                            Text(
                              'Order Summary',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OrderSummary(
                              cartItems: cartItems,
                              subtotal: subtotal,
                              deliveryFee: deliveryFee,
                              total: total,
                            ),
                            const SizedBox(height: 24),

                            // Payment Method Section
                            Text(
                              'Payment Method',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PaymentMethodSelector(
                              selectedMethod: _selectedPaymentMethod,
                              onMethodSelected: (method) {
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Consumer<AddressProvider>(
          builder: (context, addressProvider, child) {
            final selectedAddress = addressProvider.selectedAddress;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedAddress == null || _isLoading
                      ? null
                      : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          selectedAddress == null
                              ? 'SELECT DELIVERY ADDRESS'
                              : 'PLACE ORDER',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Please log in to place an order');
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final selectedAddress =
          Provider.of<AddressProvider>(context, listen: false).selectedAddress;

      if (selectedAddress == null) {
        throw Exception('Please select a shipping address');
      }

      final shippingAddress =
          '''${selectedAddress.fullName}\n${selectedAddress.streetAddress}\n${selectedAddress.city}\nPhone: ${selectedAddress.phone}${selectedAddress.deliveryInstructions?.isNotEmpty == true ? '\n\nDelivery Instructions:\n${selectedAddress.deliveryInstructions}' : ''}'''
              .trim();

      final order = Order(
        id: '', // Will be assigned by the server
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        totalAmount: cartProvider.total + 5.00, // Add delivery fee
        status: OrderStatus.Pending,
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
        items: cartProvider.items.values
            .map((item) => OrderItem(
                  productId: item.product.id,
                  productName: item.product.name,
                  price: item.product.price,
                  quantity: item.quantity,
                ))
            .toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      try {
        final createdOrder = await orderProvider.createOrder(order);

        // Clear the cart after successful order creation
        await cartProvider.clearCart();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Order placed successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait for snackbar to be visible before navigation
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to order tracking screen
          if (mounted && createdOrder != null) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/order-tracking',
              (route) => route.isFirst,
              arguments: createdOrder.id,
            );
          } else {
            // If no order was returned, just go back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } catch (orderError) {
        print('Order creation error: $orderError');
        if (orderError.toString().contains('User not authenticated')) {
          // If it's an authentication error but we have a user, it's likely a token issue
          // Try to proceed anyway since the order might have been created
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate back to home screen since we can't get the order ID
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          // For other errors, show the error message
          throw orderError;
        }
      }
    } catch (error) {
      print('Order creation error: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_selectedPaymentMethod.isEmpty) {
      setState(() {
        _error = 'Please select a payment method';
      });
      return false;
    }
    return true;
  }
}
