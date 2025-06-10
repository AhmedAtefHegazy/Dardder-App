import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_overlay.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final List<String> _defaultRoles = ['customer', 'user', 'admin'];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<UserProvider>().loadUsers(),
    );
  }

  Future<void> _updateUserRole(String userId, String role) async {
    try {
      await context.read<UserProvider>().updateUserRole(userId, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'customer':
        return Colors.green;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRoleName(String role) {
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  List<String> _getAvailableRoles(String currentRole) {
    // Include the current role if it's not in default roles
    if (!_defaultRoles.contains(currentRole.toLowerCase())) {
      return [..._defaultRoles, currentRole];
    }
    return _defaultRoles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UserProvider>().loadUsers();
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingOverlay();
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.loadUsers();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadUsers(),
            child: ListView.builder(
              itemCount: provider.users.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final user = provider.users[index];
                final availableRoles = _getAvailableRoles(user.role);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _getInitials(user.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name.isEmpty ? 'No Name' : user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email.isEmpty ? 'No Email' : user.email),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${user.isActive ? 'Active' : 'Inactive'}',
                          style: TextStyle(
                            color: user.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: user.role.toLowerCase(),
                          items: ['customer', 'admin'].map((String role) {
                            return DropdownMenuItem<String>(
                              value: role.toLowerCase(),
                              child: Text(
                                _formatRoleName(role),
                                style: TextStyle(
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _updateUserRole(user.id, newValue);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                          onPressed: () {
                            if (user.isActive) {
                              provider.deactivateUser(user.id);
                            } else {
                              provider.activateUser(user.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
