class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String location;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isSold;
  final double sustainabilityScore;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.images,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    this.isSold = false,
    this.sustainabilityScore = 0.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      category: json['category'],
      condition: json['condition'],
      location: json['location'],
      images: List<String>.from(json['images']),
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      createdAt: DateTime.parse(json['createdAt']),
      isSold: json['isSold'] ?? false,
      sustainabilityScore: json['sustainabilityScore']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'location': location,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt.toIso8601String(),
      'isSold': isSold,
      'sustainabilityScore': sustainabilityScore,
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? location,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    bool? isSold,
    double? sustainabilityScore,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,
      sustainabilityScore: sustainabilityScore ?? this.sustainabilityScore,
    );
  }
}