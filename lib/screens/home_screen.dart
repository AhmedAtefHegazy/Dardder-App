import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_pharmacy,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.name ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (user?.isAdmin ?? false)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/admin');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Go to Admin Dashboard'),
              ),
          ],
        ),
      ),
    );
  }
}
