import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/models/order_model.dart';
import 'dart:io';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  final OrderController _orderController = Get.find<OrderController>();
  final AuthController _authController = Get.find<AuthController>();
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Purchases',),
            Tab(text: 'Sales'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchasesTab(),
          _buildSalesTab(),
        ],
      ),
    );
  }
  
  Widget _buildPurchasesTab() {
    final userId = _authController.currentUser.value!.id;
    
    return Obx(() {
      final purchases = _orderController.orders
          .where((order) => order.buyerId == userId)
          .toList();
      
      if (purchases.isEmpty) {
        return const Center(
          child: Text(
            'You haven\'t made any purchases yet',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final order = purchases[index];
          return _buildOrderCard(order, isBuyer: true);
        },
      );
    });
  }
  
  Widget _buildSalesTab() {
    final userId = _authController.currentUser.value!.id;
    
    return Obx(() {
      final sales = _orderController.orders
          .where((order) => order.sellerId == userId)
          .toList();
      
      if (sales.isEmpty) {
        return const Center(
          child: Text(
            'You haven\'t made any sales yet',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final order = sales[index];
          return _buildOrderCard(order, isBuyer: false);
        },
      );
    });
  }
  
  Widget _buildOrderCard(OrderModel order, {required bool isBuyer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(order.orderDate),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Order Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: order.productImage.isNotEmpty
                      ? Image.file(
                          File(order.productImage),
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
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 16),
                
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${order.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Status: '),
                          _buildStatusChip(order.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Delivery Tracking
          if (order.status != OrderStatus.PENDING)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDeliveryTracker(order.deliveryStatus),
                ],
              ),
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
          if (isBuyer && order.status == OrderStatus.DELIVERED)
            TextButton.icon(
              onPressed: () {
                _orderController.confirmDelivery(order.id);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Receipt'),
            ),
          if (!isBuyer && order.status == OrderStatus.PENDING)
            TextButton.icon(
              onPressed: () {
                _orderController.updateOrderStatus(
                  order.id, 
                  OrderStatus.PROCESSING,
                );
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Process Order'),
            ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.toNamed('/tracking/${order.id}');
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Track Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    
    switch (status) {
      case OrderStatus.PENDING:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'Pending';
        break;
      case OrderStatus.PROCESSING:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Processing';
        break;
      case OrderStatus.SHIPPED:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        label = 'Shipped';
        break;
      case OrderStatus.DELIVERED:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'Delivered';
        break;
      case OrderStatus.COMPLETED:
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        label = 'Completed';
        break;
      case OrderStatus.CANCELLED:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Cancelled';
        break;
      case OrderStatus.PLACED:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Placed';
        break;
      case OrderStatus.PAID:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Paid';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        label = 'Unknown';
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Widget _buildDeliveryTracker(DeliveryStatus status) {
    final steps = [
      DeliveryStatus.PENDING,
      DeliveryStatus.PROCESSING,
      DeliveryStatus.SHIPPED,
      DeliveryStatus.DELIVERED,
    ];
    
    DeliveryStatus mappedStatus = status;
    
    final currentStep = steps.indexOf(mappedStatus);
    
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        // Even indices are steps, odd indices are connectors
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex <= currentStep;
          
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  _getDeliveryStatusLabel(steps[stepIndex]),
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          final beforeIndex = index ~/ 2;
          final isCompleted = beforeIndex < currentStep;
          
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
            ),
          );
        }
      }),
    );
  }
  
  String _getDeliveryStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.PENDING:
        return 'Order Placed';
      case DeliveryStatus.PROCESSING:
      case DeliveryStatus.SHIPPED:
        return 'Dispatched';
      case DeliveryStatus.OUT_FOR_DELIVERY:
        return 'Out for Delivery';
      case DeliveryStatus.DELIVERED:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}