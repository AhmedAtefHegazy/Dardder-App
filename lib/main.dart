import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/user_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/user_address_provider.dart';
import 'services/order_service.dart';
import 'services/statistics_service.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/products_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/product_details_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'models/product.dart';
import 'providers/address_provider.dart';
import 'services/cart_service.dart';
import 'services/address_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create a single instance of FlutterSecureStorage
  const storage = FlutterSecureStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(CartService()),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(OrderService()),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(StatisticsService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AddressProvider(AddressService()),
        ),
      ],
      child: MyApp(storage: storage),
    ),
  );
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage storage;

  const MyApp({Key? key, required this.storage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(storage)..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(OrderService()),
          update: (_, auth, previous) => previous!..updateAuth(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, auth, previous) => previous!..updateAuth(auth.user),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(StatisticsService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(CartService()),
          update: (_, auth, previous) => previous!..updateAuth(auth.user?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserAddressProvider>(
          create: (_) => UserAddressProvider(),
          update: (_, auth, previous) => previous!..updateAuth(auth.user),
        ),
        ChangeNotifierProvider(
          create: (_) => AddressProvider(AddressService()),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pharmacy App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: auth.isInitialized
                ? auth.isAuthenticated
                    ? auth.isAdmin
                        ? const AdminDashboard()
                        : const HomeScreen()
                    : const LoginScreen()
                : const SplashScreen(),
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
