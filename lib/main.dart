import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/controllers/product_controller.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/services/storage_service.dart';
import 'package:recyclehub/services/chat_service.dart';
import 'package:recyclehub/services/payment_service.dart';
import 'package:recyclehub/services/delivery_tracking_service.dart';

import 'package:recyclehub/views/splash_screen.dart';
import 'package:recyclehub/views/auth/login_screen.dart';
import 'package:recyclehub/views/auth/register_screen.dart';
import 'package:recyclehub/views/home_screen.dart';
import 'package:recyclehub/views/add_product_screen.dart';
import 'package:recyclehub/views/product_details_screen.dart';
import 'package:recyclehub/views/profile_screen.dart';
import 'package:recyclehub/views/order_management_screen.dart';
import 'package:recyclehub/views/checkout_screen.dart';
import 'package:recyclehub/views/delivery_tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  // Initialize storage service first (no dependencies)
  await Get.putAsync(() => StorageService().init());
  
  // Initialize controllers
  Get.lazyPut(() => AuthController(), fenix: true);
  Get.lazyPut(() => ProductController(), fenix: true);
  Get.lazyPut(() => OrderController(), fenix: true);
  
  // Initialize remaining services
  Get.lazyPut(() => ChatService(), fenix: true);
  Get.lazyPut(() => PaymentService(), fenix: true);
  Get.lazyPut(() => DeliveryTrackingService(), fenix: true);
  
  runApp(const ReCycleHub());
}

class ReCycleHub extends StatelessWidget {
  const ReCycleHub({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ReCycleHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          background: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/add_product', page: () => const AddProductScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/orders', page: () => const OrderManagementScreen()),
        GetPage(
          name: '/product/:id',
          page: () {
            final productId = Get.parameters['id']!;
            final product = Get.find<ProductController>().getProductById(productId);
            if (product != null) {
              return ProductDetailsScreen(product: product);
            } else {
              return const HomeScreen();
            }
          },
        ),
        GetPage(
          name: '/checkout/:productId',
          page: () {
            final productId = Get.parameters['productId']!;
            final product = Get.find<ProductController>().getProductById(productId);
            if (product != null) {
              return CheckoutScreen(product: product);
            } else {
              return const HomeScreen();
            }
          },
        ),
        GetPage(
          name: '/tracking/:orderId',
          page: () {
            final orderId = Get.parameters['orderId']!;
            final order = Get.find<OrderController>().getOrderById(orderId);
            if (order != null) {
              return DeliveryTrackingScreen(order: order);
            } else {
              return const OrderManagementScreen();
            }
          },
        ),
      ],
    );
  }
}
