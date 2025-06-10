import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getOrderStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return 0;
      case OrderStatus.Processing:
        return 1;
      case OrderStatus.Shipped:
        return 2;
      case OrderStatus.Delivered:
        return 3;
      case OrderStatus.Cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        elevation: 0,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final order = orderProvider.orders.firstWhere(
            (o) => o.id == widget.orderId,
            orElse: () => Order(
              id: '',
              userId: '',
              userName: '',
              userEmail: '',
              totalAmount: 0,
              status: OrderStatus.Pending,
              shippingAddress: '',
              paymentMethod: '',
              items: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (order.id.isEmpty) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          final currentStep = _getOrderStep(order.status);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Status Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${order.status}',
                          style: TextStyle(
                            color: _getStatusColor(order.status, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Timeline
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTimelineTile(
                        'Order Placed',
                        'Your order has been received',
                        Icons.shopping_cart_checkout,
                        isFirst: true,
                        isActive: currentStep >= 0,
                        isDone: currentStep > 0,
                        theme: theme,
                      ),
                      _buildTimelineTile(
                        'Processing',
                        'Your order is being prepared',
                        Icons.inventory,
                        isActive: currentStep >= 1,
                        isDone: currentStep > 1,
                        theme: theme,
                      ),
                      _buildTimelineTile(
                        'Shipped',
                        'Your order is on the way',
                        Icons.local_shipping,
                        isActive: currentStep >= 2,
                        isDone: currentStep > 2,
                        theme: theme,
                      ),
                      _buildTimelineTile(
                        'Delivered',
                        'Your order has been delivered',
                        Icons.check_circle,
                        isLast: true,
                        isActive: currentStep >= 3,
                        isDone: currentStep > 3,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                // Shipping Details
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipping Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.shippingAddress,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Order Items
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Text(
                                        '${item.quantity}x \$${item.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Cancel Order Button
                if (order.status != OrderStatus.Delivered &&
                    order.status != OrderStatus.Cancelled)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Order'),
                            content: const Text(
                                'Are you sure you want to cancel this order?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final success = await context
                              .read<OrderProvider>()
                              .updateOrderStatus(
                                  order.id, OrderStatus.Cancelled);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Order cancelled.'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      label: const Text('Cancel Order'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineTile(
    String title,
    String subtitle,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
    bool isActive = false,
    bool isDone = false,
    required ThemeData theme,
  }) {
    final color = isDone || isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.3);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(color: color),
      afterLineStyle: LineStyle(color: color),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? theme.colorScheme.primary
                        .withOpacity(_progressAnimation.value)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                color: isDone || isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.outline,
                size: 20,
              ),
            );
          },
        ),
      ),
      endChild: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight:
                    isDone || isActive ? FontWeight.bold : FontWeight.normal,
                color: isDone || isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status, ThemeData theme) {
    switch (status) {
      case OrderStatus.Pending:
        return Colors.orange;
      case OrderStatus.Processing:
        return Colors.blue;
      case OrderStatus.Shipped:
        return Colors.indigo;
      case OrderStatus.Delivered:
        return Colors.green;
      case OrderStatus.Cancelled:
        return Colors.red;
    }
  }
}
