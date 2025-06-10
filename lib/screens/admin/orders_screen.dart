import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrderProvider>().loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<OrderProvider>(context, listen: false).loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: ${e.toString()}'),
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return Colors.orange;
      case OrderStatus.Processing:
        return Colors.blue;
      case OrderStatus.Shipped:
        return Colors.purple;
      case OrderStatus.Delivered:
        return Colors.green;
      case OrderStatus.Cancelled:
        return Colors.red;
    }
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Customer Information', [
                'Name: ${order.userName}',
                'Email: ${order.userEmail}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Shipping Address', [
                order.shippingAddress,
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Order Items', [
                ...order.items.map((item) =>
                    '${item.quantity}x ${item.productName} - \$${(item.price * item.quantity).toStringAsFixed(2)}'),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Payment Details', [
                'Method: ${order.paymentMethod}',
                'Total Amount: \$${order.totalAmount.toStringAsFixed(2)}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Order Status', [
                'Current Status: ${order.status.name}',
                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
                'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(order.updatedAt)}',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
          if (order.status.name.toLowerCase() != 'cancelled')
            TextButton(
              onPressed: () => _showUpdateStatusDialog(context, order),
              child: const Text('UPDATE STATUS'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(detail),
            )),
      ],
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Order order) {
    OrderStatus selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the new status for this order:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  ...OrderStatus.values
                      .map((status) => RadioListTile<OrderStatus>(
                            title: Text(status.name),
                            value: status,
                            groupValue: selectedStatus,
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            },
                          )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await Provider.of<OrderProvider>(context, listen: false)
                    .updateOrderStatus(order.id, selectedStatus);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order status updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update order status: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                final orders = orderProvider.orders;

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No orders found'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<OrderStatus>(
                        value: _selectedStatus.isEmpty
                            ? null
                            : OrderStatus.fromString(_selectedStatus),
                        hint: const Text('Filter by Status'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ...OrderStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value?.name ?? '';
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          if (_selectedStatus.isNotEmpty &&
                              order.status.name.toLowerCase() !=
                                  _selectedStatus.toLowerCase()) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              title: Text(
                                'Order #${order.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${order.userName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                  ),
                                  Text(
                                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.status.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showOrderDetails(context, order),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
