import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/customer/cart_item_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is fully built before loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    if (!mounted) return;

    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user != null) {
      await cartProvider.loadCart();
    }
  }

  Future<void> _retryLoadCart() async {
    if (!mounted) return;
    setState(() {
      _isRetrying = true;
    });

    await _loadCart();

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.itemCount > 0) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadCart,
                      tooltip: 'Refresh Cart',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Cart'),
                            content: const Text(
                              'Are you sure you want to remove all items from your cart?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await cartProvider.clearCart();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Cart cleared successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Failed to clear cart: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('CLEAR'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCart,
                tooltip: 'Refresh Cart',
              );
            },
          ),
        ],
      ),
      body: Consumer2<CartProvider, AuthProvider>(
        builder: (context, cartProvider, authProvider, child) {
          if (cartProvider.isLoading || _isRetrying) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (cartProvider.error != null) {
            // If it's an authentication error but we have a user, try to reload
            if (cartProvider.error!.contains('User not authenticated') &&
                authProvider.user != null &&
                !_isRetrying) {
              // Schedule the retry for the next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _retryLoadCart();
                }
              });
              // Show loading while retrying
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cartProvider.error!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retryLoadCart,
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }

          if (cartProvider.itemCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CONTINUE SHOPPING'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadCart,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items.values.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CartItemCard(
                          item: item,
                          onQuantityChanged: (quantity) async {
                            try {
                              await cartProvider.updateQuantity(
                                item.product.id,
                                quantity,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to update quantity: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onRemove: () async {
                            try {
                              await cartProvider
                                  .removeFromCart(item.product.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${item.product.name} removed from cart'),
                                    backgroundColor: Colors.green,
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        cartProvider.addToCart(
                                          item.product,
                                          quantity: item.quantity,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove item: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Cart Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '\$${cartProvider.total.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: cartProvider.isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  '/customer/checkout',
                                  arguments: cartProvider,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: cartProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'PROCEED TO CHECKOUT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
