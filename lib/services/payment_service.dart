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
  String? _currentOrderId;
  Function(String)? _onSuccess;
  Function(String)? _onError;

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
    _currentOrderId = null;
    _onSuccess = null;
    _onError = null;
  }

  void startPayment({
    required String orderId,
    required double amount,
    required String productName,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    // Keep context for callbacks
    _currentOrderId = orderId;
    _onSuccess = onSuccess;
    _onError = onError;

    final user = _authController.currentUser.value;
    
    if (user == null) {
      onError('User not logged in');
      return;
    }

    // Convert amount to paise (Razorpay requires amount in smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // TODO: Set your actual Razorpay key
      'amount': amountInPaise,
      'name': 'ReCycleHub',
      'description': 'Payment for $productName',
      // Do NOT pass a mock order_id; integrate server-side order creation before enabling this.
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
    if (_currentOrderId != null && _currentOrderId!.isNotEmpty) {
      _orderController.updateOrderStatus(
        _currentOrderId!,
        OrderStatus.PAID,
      );
    }
    
    Get.snackbar(
      'Payment Successful',
      'Payment ID: ${response.paymentId}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Notify caller
    if (_onSuccess != null) {
      _onSuccess!(response.paymentId ?? '');
    }

    // Clear transient state
    _currentOrderId = null;
    _onSuccess = null;
    _onError = null;

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

    // Notify caller
    if (_onError != null) {
      _onError!(response.message ?? 'Payment failed');
    }
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