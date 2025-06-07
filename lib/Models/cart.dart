import 'package:mongo_dart/mongo_dart.dart';

class CartItem {
  final ObjectId productId;
  int quantity;
  final double price;
  final String productName;
  final String productImage;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.price,
    required this.productName,
    required this.productImage,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      productName: json['productName'],
      productImage: json['productImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'productName': productName,
      'productImage': productImage,
    };
  }
}

class Cart {
  final ObjectId id;
  final ObjectId userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
} 