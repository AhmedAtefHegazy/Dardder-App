import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/customer/product_grid_item.dart';
import '../../widgets/customer/category_chip.dart';
import '../../widgets/common/search_bar.dart';
import '../../widgets/customer/customer_drawer.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _selectedCategory = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      await Future.wait([
        context.read<ProductProvider>().loadProducts(),
        context.read<CategoryProvider>().loadCategories(),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      await Future.wait([
        context.read<ProductProvider>().refreshProducts(),
        context.read<CategoryProvider>().loadCategories(),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh data: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const CustomerDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Modern app bar with search
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              backgroundColor: theme.colorScheme.background,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                  tooltip: 'Refresh Products',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  alignment: Alignment.bottomCenter,
                  child: CustomSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<ProductProvider>().searchProducts(value);
                    },
                    hintText: 'Search medicines, health products...',
                  ),
                ),
              ),
            ),

            // Categories list
            SliverToBoxAdapter(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const SizedBox(
                      height: 50,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (categoryProvider.error != null) {
                    return SizedBox(
                      height: 50,
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => categoryProvider.loadCategories(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry loading categories'),
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = categoryProvider.categories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: CategoryChip(
                            category: category,
                            isSelected: _selectedCategory == category.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category.id : '';
                              });
                              context
                                  .read<ProductProvider>()
                                  .filterByCategory(_selectedCategory);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Featured section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Products',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.8),
                            theme.colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🎉 Special Offers Coming Soon!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products grid
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (productProvider.error != null) {
                  return SliverFillRemaining(
                    child: Center(
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
                            'Error: ${productProvider.error}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => productProvider.refreshProducts(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No products found'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.63,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = productProvider.products[index];
                        return ProductGridItem(product: product);
                      },
                      childCount: productProvider.products.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
