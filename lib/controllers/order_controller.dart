import 'package:get/get.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/models/order_model.dart';
import 'package:recyclehub/services/storage_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class OrderController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  
  String getCurrentUserId() {
    final authController = Get.find<AuthController>();
    return authController.currentUser.value?.id ?? '';
  }
  
  @override
  void onInit() {
    super.onInit();
    _loadOrders();
  }
  
  void _loadOrders() async {
    final ordersData = await _storageService.getData('orders');
    if (ordersData != null) {
      try {
        final List<dynamic> ordersJson = jsonDecode(ordersData);
        final loadedOrders = ordersJson
            .map((json) => OrderModel.fromJson(json))
            .toList();
        orders.assignAll(loadedOrders);
      } catch (e) {
        print('Error loading orders: $e');
      }
    }
  }
  
  Future<void> _saveOrders() async {
    final ordersJson = orders.map((order) => order.toJson()).toList();
    await _storageService.saveData('orders', jsonEncode(ordersJson));
  }
  
  Future<void> createOrder(OrderModel order) async {
    orders.add(order);
    await _saveOrders();
    Get.snackbar(
      'Success',
      'Order created successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  Future<void> _createOrderOld({
    required String productId,
    required String productTitle,
    required String productImage,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    required double amount,
    String? paymentId,
  }) async {
    final newOrder = OrderModel(
      id: const Uuid().v4(),
      productId: productId,
      productTitle: productTitle,
      productImage: productImage,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      amount: amount,
      orderDate: DateTime.now(),
      status: OrderStatus.PENDING,
      deliveryStatus: DeliveryStatus.PENDING,
      paymentId: paymentId,
    );
    
    orders.add(newOrder);
    await _saveOrders();
  }
  
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = orders[index].copyWith(status: status);
      orders[index] = updatedOrder;
      await _saveOrders();
    }
  }
  
  Future<void> updateDeliveryStatus(String orderId, DeliveryStatus status) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = orders[index].copyWith(deliveryStatus: status);
      orders[index] = updatedOrder;
      
      // If delivery status is delivered, update order status
      if (status == DeliveryStatus.DELIVERED) {
        orders[index] = updatedOrder.copyWith(status: OrderStatus.DELIVERED);
      }
      
      await _saveOrders();
    }
  }
  
  Future<void> confirmDelivery(String orderId) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = orders[index].copyWith(status: OrderStatus.COMPLETED);
      orders[index] = updatedOrder;
      await _saveOrders();
    }
  }
  
  Future<void> cancelOrder(String orderId) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = orders[index].copyWith(status: OrderStatus.CANCELLED);
      orders[index] = updatedOrder;
      await _saveOrders();
    }
  }
  
  Future<void> addTrackingNumber(String orderId, String trackingNumber) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final updatedOrder = orders[index].copyWith(
        trackingNumber: trackingNumber,
        status: OrderStatus.SHIPPED,
        deliveryStatus: DeliveryStatus.SHIPPED,
      );
      orders[index] = updatedOrder;
      await _saveOrders();
    }
  }
  
  OrderModel? getOrderById(String orderId) {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      return orders[index];
    }
    return null;
  }
  
  List<OrderModel> getOrdersByBuyer(String buyerId) {
    return orders.where((order) => order.buyerId == buyerId).toList();
  }
  
  List<OrderModel> getOrdersBySeller(String sellerId) {
    return orders.where((order) => order.sellerId == sellerId).toList();
  }
}