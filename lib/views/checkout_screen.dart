import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/controllers/order_controller.dart';
import 'package:recyclehub/models/order_model.dart';
import 'package:recyclehub/models/product_model.dart';
import 'package:recyclehub/services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  final ProductModel product;

  const CheckoutScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final OrderController _orderController = Get.find<OrderController>();
  final PaymentService _paymentService = Get.find<PaymentService>();
  
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  
  String _selectedPaymentMethod = 'Razorpay';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Pre-fill city if available from user profile
    if (_authController.currentUser.value?.city != null) {
      _cityController.text = _authController.currentUser.value!.city!;
    }
  }
  
  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product summary
            _buildProductSummary(),
            
            const SizedBox(height: 24),
            
            // Shipping information
            _buildShippingInformation(),
            
            const SizedBox(height: 24),
            
            // Payment method selection
            _buildPaymentMethodSelection(),
            
            const SizedBox(height: 32),
            
            // Order summary
            _buildOrderSummary(),
            
            const SizedBox(height: 24),
            
            // Place order button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.product.images.isNotEmpty
                  ? Image.file(
                      File(widget.product.images[0]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Condition: ${widget.product.condition}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seller: ${widget.product.sellerName}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  Widget _buildShippingInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Enter your full address',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  hintText: 'Enter ZIP code',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ZIP code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.grey[100],
          child: RadioListTile<String>(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/razorpay_logo.png',
                  width: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.payment, size: 30);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Razorpay'),
              ],
            ),
            value: 'Razorpay',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.grey[100],
          child: RadioListTile<String>(
            title: Row(
              children: [
                const Icon(Icons.money, size: 30, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Cash on Delivery'),
              ],
            ),
            value: 'COD',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    // Calculate delivery fee
    final double deliveryFee = 40.0;
    final double totalAmount = widget.product.price + deliveryFee;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product Price', style: TextStyle(color: Colors.grey[700])),
            Text('₹${widget.product.price.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Delivery Fee', style: TextStyle(color: Colors.grey[700])),
            Text('₹${deliveryFee.toStringAsFixed(2)}'),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₹${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _placeOrder() async {
    // Validate form
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _zipCodeController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all shipping information',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create shipping address
      final shippingAddress = '${_addressController.text}, ${_cityController.text}, ${_zipCodeController.text}';
      
      // Calculate delivery fee and total amount
      final double deliveryFee = 40.0;
      final double totalAmount = widget.product.price + deliveryFee;

      // Create order
      final OrderModel order = OrderModel(
        id: _paymentService.generateMockOrderId(),
        productId: widget.product.id,
        productTitle: widget.product.title,
        productImage: widget.product.images.isNotEmpty ? widget.product.images[0] : '',
        amount: widget.product.price,
        totalAmount: totalAmount,
        buyerId: user.id,
        buyerName: user.name,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        shippingAddress: shippingAddress,
        status: _selectedPaymentMethod == 'COD' ? OrderStatus.PLACED : OrderStatus.PENDING,
        orderDate: DateTime.timestamp(),
        deliveryStatus: DeliveryStatus.PROCESSING,
        paymentMethod: _selectedPaymentMethod,
        trackingNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save order
      await _orderController.createOrder(order);

      if (_selectedPaymentMethod == 'Razorpay') {
        // Process payment with Razorpay
        _paymentService.startPayment(
          orderId: order.id,
          amount: totalAmount,
          productName: widget.product.title,
          onSuccess: (paymentId) {
            // Reset loading state after successful payment
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            setState(() {
              _isLoading = false;
            });
          },
        );
      } else {
        // For COD, just navigate to order confirmation
        Get.toNamed('/orders');
        Get.snackbar(
          'Order Placed',
          'Your order has been placed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (_selectedPaymentMethod == 'COD') {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}