import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class RecentOrdersList extends StatefulWidget {
  const RecentOrdersList({Key? key}) : super(key: key);

  @override
  State<RecentOrdersList> createState() => _RecentOrdersListState();
}

class _RecentOrdersListState extends State<RecentOrdersList> {
  @override
  void initState() {
    super.initState();
    if (mounted) {
      Future.microtask(() {
        context.read<OrderProvider>().loadOrders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.error != null) {
          return Center(
            child: Text(
              'Error: ${orderProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final recentOrders = orderProvider.orders.take(5).toList();

        if (recentOrders.isEmpty) {
          return const Center(
            child: Text('No orders'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentOrders.length,
          itemBuilder: (context, index) {
            final order = recentOrders[index];
            return OrderListItem(order: order);
          },
        );
      },
    );
  }
}

class OrderListItem extends StatelessWidget {
  final Order order;

  const OrderListItem({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          'Order #${order.id} - User #${order.userId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${order.status}'),
            Text(
              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/admin/orders/${order.id}',
            );
          },
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/orders/${order.id}',
          );
        },
      ),
    );
  }
}
