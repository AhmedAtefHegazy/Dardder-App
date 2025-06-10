import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/admin/product_form_dialog.dart';
import '../../widgets/loading_overlay.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProductProvider>().loadProducts(),
    );
  }

  Future<void> _showAddEditProductDialog(BuildContext context,
      [Product? product]) async {
    await showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    // Store ScaffoldMessenger before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final productName = product.name; // Store product name for later use

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $productName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ProductProvider>().deleteProduct(product.id);

        // Check if widget is still mounted before showing SnackBar
        if (mounted) {
          // Use the stored scaffoldMessenger
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('$productName deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // Show error message if something goes wrong
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete $productName: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductProvider>().refreshProducts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditProductDialog(context),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
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
                      provider.clearError();
                      provider.refreshProducts();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No products found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshProducts,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(product.imageUrl!),
                            onBackgroundImageError: (e, _) {
                              // Handle image load error
                              debugPrint('Error loading image: $e');
                            },
                          )
                        : CircleAvatar(
                            child: Text(product.name[0].toUpperCase()),
                          ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.categoryName} - \$${product.price.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            color: product.stockQuantity > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await _showAddEditProductDialog(
                                    context, product);
                                break;
                              case 'delete':
                                await _confirmDelete(context, product);
                                break;
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
