enum OrderStatus {
  PENDING,
  PROCESSING,
  SHIPPED,
  DELIVERED,
  COMPLETED,
  CANCELLED,
  PLACED,
  PAID,
}

enum DeliveryStatus {
  PENDING,
  PROCESSING,
  SHIPPED,
  OUT_FOR_DELIVERY,
  DELIVERED,
}

class OrderModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final double amount;
  final DateTime orderDate;
  final OrderStatus status;
  final DeliveryStatus deliveryStatus;
  final String shippingAddress;
  final String? trackingNumber;
  final String? paymentId;
  final String? paymentMethod;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Getters for compatibility with existing code
  OrderStatus get orderStatus => status;
  double get price => amount;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.orderDate,
    required this.status,
    required this.deliveryStatus,
    this.shippingAddress = '',
    this.trackingNumber,
    this.paymentId,
    this.paymentMethod,
    this.totalAmount = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : this.createdAt = createdAt ?? DateTime.now(),
       this.updatedAt = updatedAt ?? DateTime.now();

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      productId: json['productId'],
      productTitle: json['productTitle'],
      productImage: json['productImage'],
      buyerId: json['buyerId'],
      buyerName: json['buyerName'],
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      amount: json['amount'],
      orderDate: DateTime.parse(json['orderDate']),
      status: OrderStatus.values.byName(json['status']),
      deliveryStatus: DeliveryStatus.values.byName(json['deliveryStatus']),
      trackingNumber: json['trackingNumber'],
      paymentId: json['paymentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'orderDate': orderDate.toIso8601String(),
      'status': status.name,
      'deliveryStatus': deliveryStatus.name,
      'trackingNumber': trackingNumber,
      'paymentId': paymentId,
    };
  }

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? productImage,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    double? amount,
    DateTime? orderDate,
    OrderStatus? status,
    DeliveryStatus? deliveryStatus,
    String? trackingNumber,
    String? paymentId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      paymentId: paymentId ?? this.paymentId,
    );
  }
}