import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';

class OrderSummary extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double total;

  const OrderSummary({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Order Items
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            final item = cartItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          item.product.categoryName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Text(
                    '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 32),

        // Summary
        _SummaryRow(
          label: 'Subtotal',
          value: subtotal,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Delivery Fee',
          value: deliveryFee,
          theme: theme,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        _SummaryRow(
          label: 'Total',
          value: total,
          isTotal: true,
          theme: theme,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final ThemeData theme;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    this.isTotal = false,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleLarge
              : theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
