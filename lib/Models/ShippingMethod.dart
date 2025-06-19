import 'package:mongo_dart/mongo_dart.dart';

class ShippingMethod {
  final ObjectId id;
  final String name;
  final String description;
  final double cost;
  final String estimatedDeliveryTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShippingMethod({
    required this.id,
    required this.name,
    this.description = '',
    this.cost = 0.0,
    this.estimatedDeliveryTime = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    return ShippingMethod(
      id: json['_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] is int)
          ? (json['cost'] as int).toDouble()
          : (json['cost'] as num).toDouble(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
