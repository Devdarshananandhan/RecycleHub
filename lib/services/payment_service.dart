import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/models/order_model.dart';

class PaymentService extends GetxService {
  late Razorpay _razorpay;
  late AuthController _authController;
  late OrderController _orderController;

  Future<PaymentService> init() async {
    try {
      _authController = Get.find<AuthController>();
      _orderController = Get.find<OrderController>();
    } catch (e) {
      print("Controllers not initialized yet, will be accessed later: $e");
    }
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    return this;
  }

  void dispose() {
    _razorpay.clear();
  }

  void startPayment({
    required String orderId,
    required double amount,
    required String productName,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    final user = _authController.currentUser.value;
    
    if (user == null) {
      onError('User not logged in');
      return;
    }

    // Convert amount to paise (Razorpay requires amount in smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Replace with your actual Razorpay key
      'amount': amountInPaise,
      'name': 'ReCycleHub',
      'description': 'Payment for $productName',
      'order_id': orderId,
      'prefill': {
        'contact': '9876543210', // Replace with user's phone if available
        'email': user.email,
        'name': user.name,
      },
      'theme': {
        'color': '#4CAF50',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError('Error: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Update order status to PAID
    _orderController.updateOrderStatus(
      response.orderId ?? '',
      OrderStatus.PAID,
    );
    
    Get.snackbar(
      'Payment Successful',
      'Payment ID: ${response.paymentId}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Navigate to order management screen
    Get.toNamed('/orders');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message ?? 'Something went wrong'}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Wallet: ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Generate a mock order ID for testing
  String generateMockOrderId() {
    return 'order_${DateTime.now().millisecondsSinceEpoch}';
  }
}