// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/product_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/address_provider.dart';
import 'providers/order_provider.dart';
import 'providers/category_provider.dart';
import 'providers/review_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/shop_review_provider.dart';

// Services
import 'service/api_client.dart';
import 'service/shop_service.dart';
import 'service/recommendation_service.dart';

// Theme
import 'theme/app_theme.dart';

// Models
import 'models/shop_model.dart';
import 'models/product_model.dart';

// Screens
import 'screens/admins/admin_shops_screen.dart';
import 'screens/admins/admin_users_screen.dart';
import 'screens/admins/admin_shop_approval_screen.dart';
import 'screens/admins/admin_home_screen.dart';
import 'screens/admins/admin_categories_screen.dart';
import 'screens/admins/admin_products_screen.dart';
import 'screens/auths/login_screen.dart';
import 'screens/auths/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auths/forgot_password_screen.dart';
import 'screens/auths/verify_account_screen.dart';
import 'screens/auths/reset_otp_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shops/shop_management_screen.dart';
import 'screens/shops/shop_register_screen.dart';
import 'screens/users/personal_info_screen.dart';
import 'screens/shops/shop_list_screen.dart';
import 'screens/shops/shop_detail_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/products/add_variant_screen.dart';
import 'screens/carts/cart_screen.dart';
import 'screens/orders_payments/checkout_screen.dart';
import 'screens/orders_payments/my_orders_screen.dart';
import 'screens/orders_payments/payment_qr_screen.dart';
import 'screens/orders_payments/payment_result_screen.dart';
import 'screens/auths/change_password_screen.dart';
import 'screens/recommendations/favorite_product_screen.dart';
import 'screens/recommendations/recommended_products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider(service: ShopService())),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider(RecommendationService(),),),
        ChangeNotifierProvider(create: (_) => ShopReviewProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // SAU KHI KHỞI TẠO ỨNG DỤNG → TỰ ĐỘNG TẢI DATA HOME
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await authProvider.init();

    final context = AuthProvider.navigatorKey.currentContext;
    if (context != null) {
      Provider.of<ProductProvider>(context, listen: false).fetchPublicProducts();
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthProvider.navigatorKey,
      title: 'Mini E-commerce App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            final currentFocus = FocusManager.instance.primaryFocus;

            if (currentFocus != null && !currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),

        '/home': (context) => const HomeScreen(),

        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/verify-account': (context) => const VerifyAccountScreen(),
        '/reset-otp': (context) => ResetOtpScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),

        '/profile': (context) => const ProfileScreen(),

        // === SHOP ===
        '/shop-management': (context) => const ShopManagementScreen(),
        '/shop-register': (context) => const ShopRegisterScreen(),
        '/personal-info': (context) => const PersonalInfoScreen(),
        '/shops': (context) => const ShopListScreen(),

        // === ADMIN ===
        '/admin-home': (context) => AdminHomeScreen(),
        '/admin/shops': (context) => AdminShopsScreen(),
        '/admin/users': (context) => AdminUsersScreen(),
        '/admin/categories': (context) => const AdminCategoriesScreen(),
        '/admin/products': (context) => const AdminProductsScreen(),
        '/admin-shop-approval': (context) => AdminShopApprovalScreen(),

        // === SHOP DETAIL ===
        '/shop-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          if (args is ShopModel) {
            return ShopDetailScreen(shop: args);
          }

          return const HomeScreen();
        },

        // === PRODUCT DETAIL ===
        '/product-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          if (args is ProductModel) {
            return ProductDetailScreen(product: args);
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body: const Center(
              child: Text(
                'Không tìm thấy sản phẩm.\nVui lòng thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        },

        '/add-product': (context) => const AddProductScreen(),

        '/add-variant': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          if (args is Map<String, dynamic> && args['productId'] is int) {
            return AddVariantScreen(productId: args['productId'] as int);
          }

          return const HomeScreen();
        },

        // === RECOMMENDATIONS / FAVORITES ===
        '/favorites': (context) => const FavoriteProductScreen(),
        '/recommendations': (context) => const RecommendedProductsScreen(),

        // === CART ===
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),

        '/payment-gateway': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          return PaymentQrScreen(
            qrData: args['qrData'],
            amount: args['amount'],
            sessionCode: args['sessionCode'],
            orderIdToCheck: args['orderIdToCheck'],
          );
        },

        '/payment-result': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          return PaymentResultScreen(
            success: args['success'],
            message: args['message'],
            orderId: args['orderId'],
          );
        },

        '/orders': (context) => const MyOrdersScreen(),
      },
    );
  }
}