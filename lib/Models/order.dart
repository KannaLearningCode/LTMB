import 'package:mongo_dart/mongo_dart.dart';

class OrderItem {
  final ObjectId productId;
  final int quantity;
  final double price;
  final String productName;
  final String productImage;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
    required this.productName,
    required this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
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

class Order {
  final ObjectId id;
  final ObjectId userId;
  final List<OrderItem> items;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final String address;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.address,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      address: json['address'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'address': address,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 