import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/models/order_model.dart';
import 'package:timeline_tile/timeline_tile.dart';

class DeliveryTrackingScreen extends StatelessWidget {
  final OrderModel order;
  
  const DeliveryTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.find<OrderController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary card
            _buildOrderSummary(),
            
            const SizedBox(height: 24),
            
            // Tracking number
            _buildTrackingNumber(orderController),
            
            const SizedBox(height: 24),
            
            // Delivery timeline
            _buildDeliveryTimeline(),
            
            const SizedBox(height: 24),
            
            // Estimated delivery date
            _buildEstimatedDelivery(),
            
            const SizedBox(height: 24),
            
            // Shipping address
            _buildShippingAddress(),
            
            const SizedBox(height: 32),
            
            // Action buttons for buyer or seller
            _buildActionButtons(orderController),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order.productImage.isNotEmpty
                        ? order.productImage
                        : 'https://via.placeholder.com/80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order ID: ${order.id.substring(0, 8)}...',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order Date: ${_formatDate(order.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  order.paymentMethod ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Status',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                _buildStatusChip(order.orderStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingNumber(OrderController orderController) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking Number',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.trackingNumber ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.green),
                    onPressed: () {
                      // Copy tracking number to clipboard
                      // In a real app, you would use Clipboard.setData
                      Get.snackbar(
                        'Copied',
                        'Tracking number copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              )
            else if (order.sellerId == Get.find<OrderController>().getCurrentUserId())
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No tracking number added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showAddTrackingDialog(orderController);
                      },
                      child: const Text('Add Tracking Number'),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Tracking information will be available once the seller ships the item.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    // Define the delivery stages based on the current delivery status
    final List<Map<String, dynamic>> stages = [
      {
        'title': 'Order Placed',
        'subtitle': _formatDate(order.createdAt),
        'isCompleted': true,
        'icon': Icons.shopping_cart_checkout,
      },
      {
        'title': 'Processing',
        'subtitle': 'Preparing your order',
        'isCompleted': order.deliveryStatus.index >= DeliveryStatus.PROCESSING.index,
        'icon': Icons.inventory,
      },
      {
        'title': 'Shipped',
        'subtitle': order.deliveryStatus.index >= DeliveryStatus.SHIPPED.index
            ? 'Your order is on the way'
            : 'Waiting to be shipped',
        'isCompleted': order.deliveryStatus.index >= DeliveryStatus.SHIPPED.index,
        'icon': Icons.local_shipping,
      },
      {
        'title': 'Out for Delivery',
        'subtitle': order.deliveryStatus.index >= DeliveryStatus.OUT_FOR_DELIVERY.index
            ? 'Will be delivered today'
            : 'Waiting to reach your area',
        'isCompleted': order.deliveryStatus.index >= DeliveryStatus.OUT_FOR_DELIVERY.index,
        'icon': Icons.delivery_dining,
      },
      {
        'title': 'Delivered',
        'subtitle': order.deliveryStatus == DeliveryStatus.DELIVERED
            ? _formatDate(order.updatedAt)
            : 'Pending delivery',
        'isCompleted': order.deliveryStatus == DeliveryStatus.DELIVERED,
        'icon': Icons.check_circle,
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                return TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.2,
                  isFirst: index == 0,
                  isLast: index == stages.length - 1,
                  indicatorStyle: IndicatorStyle(
                    width: 30,
                    height: 30,
                    indicator: Container(
                      decoration: BoxDecoration(
                        color: stage['isCompleted'] ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stage['icon'],
                        color: stage['isCompleted'] ? Colors.white : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: stage['isCompleted'] ? Colors.green : Colors.grey.shade300,
                  ),
                  afterLineStyle: LineStyle(
                    color: index < stages.length - 1 && stages[index + 1]['isCompleted']
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
                  endChild: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: stage['isCompleted'] ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage['subtitle'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  startChild: const SizedBox(width: 30),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedDelivery() {
    // Calculate estimated delivery date (5-7 days from order date)
    final DateTime estimatedDate = order.createdAt.add(const Duration(days: 6));
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryStatus == DeliveryStatus.DELIVERED
                        ? 'Delivered on ${_formatDate(order.updatedAt)}'
                        : 'Expected by ${_formatDate(estimatedDate)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.shippingAddress,
                    style: TextStyle(
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderController orderController) {
    final bool isBuyer = order.buyerId == orderController.getCurrentUserId();
    final bool isSeller = order.sellerId == orderController.getCurrentUserId();
    
    if (isBuyer) {
      // Buyer actions
      return Column(
        children: [
          if (order.deliveryStatus == DeliveryStatus.DELIVERED &&
              order.orderStatus != OrderStatus.COMPLETED)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showConfirmDeliveryDialog(orderController);
                },
                child: const Text('Confirm Receipt'),
              ),
            ),
          if (order.orderStatus == OrderStatus.PENDING ||
              order.orderStatus == OrderStatus.PLACED)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showCancelOrderDialog(orderController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Cancel Order'),
              ),
            ),
        ],
      );
    } else if (isSeller) {
      // Seller actions
      return Column(
        children: [
          if (order.orderStatus == OrderStatus.PAID ||
              order.orderStatus == OrderStatus.PLACED ||
              order.orderStatus == OrderStatus.PENDING)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showUpdateDeliveryStatusDialog(orderController);
                },
                child: const Text('Update Delivery Status'),
              ),
            ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case OrderStatus.PENDING:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.PLACED:
        chipColor = Colors.blue;
        statusText = 'Placed';
        break;
      case OrderStatus.PAID:
        chipColor = Colors.purple;
        statusText = 'Paid';
        break;
      case OrderStatus.COMPLETED:
        chipColor = Colors.green;
        statusText = 'Completed';
        break;
      case OrderStatus.CANCELLED:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case OrderStatus.PROCESSING:
        chipColor = Colors.blue.shade700;
        statusText = 'Processing';
        break;
      case OrderStatus.SHIPPED:
        chipColor = Colors.purple;
        statusText = 'Shipped';
        break;
      case OrderStatus.DELIVERED:
        chipColor = Colors.green;
        statusText = 'Delivered';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAddTrackingDialog(OrderController orderController) {
    final TextEditingController trackingController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Add Tracking Number'),
        content: TextField(
          controller: trackingController,
          decoration: const InputDecoration(
            hintText: 'Enter tracking number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (trackingController.text.isNotEmpty) {
                orderController.addTrackingNumber(
                  order.id,
                  trackingController.text,
                );
                Get.back();
                Get.snackbar(
                  'Success',
                  'Tracking number added successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDeliveryStatusDialog(OrderController orderController) {
    DeliveryStatus selectedStatus = order.deliveryStatus;
    
    Get.dialog(
      AlertDialog(
        title: const Text('Update Delivery Status'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<DeliveryStatus>(
                  title: const Text('Processing'),
                  value: DeliveryStatus.PROCESSING,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                RadioListTile<DeliveryStatus>(
                  title: const Text('Shipped'),
                  value: DeliveryStatus.SHIPPED,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                RadioListTile<DeliveryStatus>(
                  title: const Text('Out for Delivery'),
                  value: DeliveryStatus.OUT_FOR_DELIVERY,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                RadioListTile<DeliveryStatus>(
                  title: const Text('Delivered'),
                  value: DeliveryStatus.DELIVERED,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              orderController.updateDeliveryStatus(order.id, selectedStatus);
              Get.back();
              Get.snackbar(
                'Success',
                'Delivery status updated successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeliveryDialog(OrderController orderController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Receipt'),
        content: const Text('Have you received this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              orderController.confirmDelivery(order.id);
              Get.back();
              Get.snackbar(
                'Success',
                'Order marked as completed',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(OrderController orderController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              orderController.cancelOrder(order.id);
              Get.back();
              Get.snackbar(
                'Order Cancelled',
                'Your order has been cancelled',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}