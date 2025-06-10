import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/products_screen.dart';
import '../screens/admin/orders_screen.dart' as admin;
import '../screens/admin/users_screen.dart';
import '../screens/admin/categories_screen.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/customer/product_details_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/address_form_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/customer/orders_screen.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../models/address.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/admin/products':
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case '/admin/categories':
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case '/admin/orders':
        return MaterialPageRoute(builder: (_) => const admin.OrdersScreen());
      case '/admin/users':
        return MaterialPageRoute(builder: (_) => const UsersScreen());
      case '/customer/home':
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
      case '/product-details':
        final product = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        );
      case '/customer/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/customer/orders':
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case '/customer/checkout':
        if (settings.arguments == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('Error: Cart data not provided'),
              ),
            ),
          );
        }
        final cartProvider = settings.arguments as CartProvider;
        return MaterialPageRoute(
          builder: (_) => CheckoutScreen(cartProvider: cartProvider),
        );
      case '/customer/address/add':
        return MaterialPageRoute(
          builder: (_) => const AddressFormScreen(isEditing: false),
        );
      case '/customer/address/edit':
        final address = settings.arguments as Address;
        return MaterialPageRoute(
          builder: (_) => AddressFormScreen(
            isEditing: true,
            address: address,
          ),
        );
      case '/customer/order-tracking':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
