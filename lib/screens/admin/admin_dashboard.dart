import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/admin/admin_drawer.dart';
import '../../widgets/admin/statistics_section.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    if (mounted) {
      Future.microtask(() {
        if (!context.mounted) return;
        final orderProvider = context.read<OrderProvider>();
        final statisticsProvider = context.read<StatisticsProvider>();
        orderProvider.loadOrders();
        statisticsProvider.loadStatistics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final pendingOrdersCount = orderProvider.pendingOrders.length;
              if (pendingOrdersCount > 0) {
                return Badge(
                  label: Text(pendingOrdersCount.toString()),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.onError,
                  largeSize: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showOrderNotifications(context),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          final statisticsProvider = context.read<StatisticsProvider>();
          await Future.wait([
            context.read<OrderProvider>().loadOrders(),
            statisticsProvider.loadStatistics(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.name ?? 'Admin'}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              const _DashboardGrid(),
              const SizedBox(height: 24),
              const StatisticsSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Orders'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<OrderProvider>(
            builder: (context, provider, child) {
              if (provider.pendingOrders.isEmpty) {
                return const Text('No pending orders');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.pendingOrders.length,
                itemBuilder: (context, index) {
                  final order = provider.pendingOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 150),
                                  child: Text(
                                    'Order #${order.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            'Customer: ${order.userName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text('Email: ${order.userEmail}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Products:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.only(left: 8, top: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.productName}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/admin/orders');
                                },
                                child: const Text('View Details'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/orders');
            },
            child: const Text('View All Orders'),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _DashboardCard(
          title: 'Orders',
          icon: Icons.shopping_cart,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/admin/orders'),
        ),
        _DashboardCard(
          title: 'Products',
          icon: Icons.inventory,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/admin/products'),
        ),
        _DashboardCard(
          title: 'Categories',
          icon: Icons.category,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/admin/categories'),
        ),
        _DashboardCard(
          title: 'Users',
          icon: Icons.people,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(178),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
