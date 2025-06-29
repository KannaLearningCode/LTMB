import 'package:mongo_dart/mongo_dart.dart';

class OrderItem {
  final int id;
  final ObjectId orderId;
  final ObjectId productId;
  final int quantity;
  final double price;
  final String productName;
  final String productImage;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.productName,
    required this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num).toDouble(),
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
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
  final double totalAmount;
  // final double discountAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String shippingAddress;
  final String billingAddress;
  final ObjectId? couponId;
  final ObjectId? shippingMethodId;
  final String phone;
  final String? notes;
  final String? voucherCode; // ✅ Thêm dòng này
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    // required this.discountAmount,
    this.status = 'Đang xử lý',
    required this.paymentMethod,
    this.paymentStatus = 'Chưa thanh toán',
    required this.shippingAddress,
    required this.billingAddress,
    this.couponId,
    this.shippingMethodId,
    required this.phone,
    this.notes,
    this.voucherCode,
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
      totalAmount: (json['totalAmount'] as num).toDouble(),
      // discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Đang xử lý',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'Chưa thanh toán',
      shippingAddress: json['shippingAddress'] ?? '',
      billingAddress: json['billingAddress'] ?? '',
      couponId: json['couponId'],
      shippingMethodId: json['shippingMethodId'],
      phone: json['phone'] ?? '',
      notes: json['notes'],
      voucherCode: json['voucherCode'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      // 'discountAmount': discountAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,
      'couponId': couponId,
      'shippingMethodId': shippingMethodId,
      'phone': phone,
      'notes': notes,
      'voucherCode': voucherCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
