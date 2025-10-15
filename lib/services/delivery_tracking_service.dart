import 'package:get/get.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/models/order_model.dart';
import 'package:recyclehub/services/storage_service.dart';

class DeliveryTrackingService extends GetxService {
  Future<DeliveryTrackingService> init() async {
    return this;
  }
  final StorageService _storageService = Get.find<StorageService>();
  final OrderController _orderController = Get.find<OrderController>();
  
  // Mock delivery updates for simulation
  Future<void> simulateDeliveryUpdates() async {
    // Get all orders that are in transit (not delivered or cancelled)
    final List<OrderModel> activeOrders = _orderController.orders
        .where((order) => 
            order.orderStatus != OrderStatus.CANCELLED && 
            order.orderStatus != OrderStatus.COMPLETED &&
            order.deliveryStatus != DeliveryStatus.DELIVERED)
        .toList();
    
    // Process each active order
    for (final order in activeOrders) {
      // Only update orders that have been paid or placed
      if (order.orderStatus == OrderStatus.PAID || 
          order.orderStatus == OrderStatus.PLACED) {
        
        // Simulate natural progression of delivery status
        DeliveryStatus nextStatus;
        
        switch (order.deliveryStatus) {
          case DeliveryStatus.PENDING:
            nextStatus = DeliveryStatus.PROCESSING;
            break;
          case DeliveryStatus.PROCESSING:
            nextStatus = DeliveryStatus.SHIPPED;
            break;
          case DeliveryStatus.SHIPPED:
            nextStatus = DeliveryStatus.OUT_FOR_DELIVERY;
            break;
          case DeliveryStatus.OUT_FOR_DELIVERY:
            nextStatus = DeliveryStatus.DELIVERED;
            break;
          case DeliveryStatus.DELIVERED:
            // Already delivered, no change needed
            continue;
          case DeliveryStatus.PENDING:
            nextStatus = DeliveryStatus.PROCESSING;
            break;
          default:
            nextStatus = DeliveryStatus.PROCESSING;
            break;
        }
        
        // Update the order with the new delivery status
        _orderController.updateDeliveryStatus(order.id, nextStatus);
      }
    }
  }
  
  // Get estimated delivery date based on order creation and current status
  DateTime getEstimatedDeliveryDate(OrderModel order) {
    // Base delivery time is 5-7 days from order date
    final int baseDays = 6;
    
    // Adjust based on current delivery status
    int adjustedDays;
    
    switch (order.deliveryStatus) {
      case DeliveryStatus.PENDING:
        adjustedDays = baseDays;
        break;
      case DeliveryStatus.PROCESSING:
        adjustedDays = baseDays - 1;
        break;
      case DeliveryStatus.SHIPPED:
        adjustedDays = baseDays - 3;
        break;
      case DeliveryStatus.OUT_FOR_DELIVERY:
        adjustedDays = 0; // Delivery expected today
        break;
      case DeliveryStatus.DELIVERED:
        return order.updatedAt; // Already delivered
      case DeliveryStatus.PENDING:
        adjustedDays = baseDays;
        break;
      default:
        adjustedDays = baseDays;
        break;
    }
    
    // Calculate the estimated delivery date
    return order.createdAt.add(Duration(days: adjustedDays));
  }
  
  // Generate a mock tracking URL for the given tracking number
  String getTrackingUrl(String trackingNumber) {
    // In a real app, this would link to an actual carrier's tracking page
    return 'https://tracking.example.com/$trackingNumber';
  }
  
  // Get delivery progress percentage based on current status
  double getDeliveryProgress(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.PENDING:
        return 0.0;
      case DeliveryStatus.PROCESSING:
        return 0.25;
      case DeliveryStatus.SHIPPED:
        return 0.5;
      case DeliveryStatus.OUT_FOR_DELIVERY:
        return 0.75;
      case DeliveryStatus.PENDING:
        return 0.0;
      case DeliveryStatus.DELIVERED:
        return 1.0;
      default:
        return 0.0;
    }
  }
  
  // Add a mock tracking event for demonstration purposes
  Future<void> addTrackingEvent(String orderId, String event, String location) async {
    // In a real app, this would store tracking events in a database
    // For this demo, we'll just print the event
    print('Tracking event for order $orderId: $event at $location');
  }
}