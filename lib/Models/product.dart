import 'package:mongo_dart/mongo_dart.dart';

class Product {
  final ObjectId id;
  final String name;
  final String description;
  final double price;
  final double? compareAtPrice;
  final String? sku;
  final int quantity;
  final String image;
  final String category; // dùng string nếu không xử lý ObjectId liên bảng
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.compareAtPrice,
    this.sku,
    this.quantity = 0,
    this.image = '',
    this.category = '',
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] as ObjectId,
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num).toDouble(),
      compareAtPrice: json['compareAtPrice'] != null
          ? (json['compareAtPrice'] is int)
              ? (json['compareAtPrice'] as int).toDouble()
              : (json['compareAtPrice'] as num).toDouble()
          : null,
      sku: json['sku'],
      quantity: json['quantity'] ?? 0,
      image: json['imageUrl'],
      category: json['categoryId']?.toString() ?? '',
      isAvailable: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'sku': sku,
      'quantity': quantity,
      'imageUrl': image,
      'categoryId': category,
      'isActive': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
