import 'package:mongo_dart/mongo_dart.dart';

class Coupon {
  final ObjectId id;
  final String code;
  final String discountType; // e.g. 'percentage' or 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final int usageLimit;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount = 0.0,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['_id'],
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'fixed',
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      maxDiscountAmount: (json['maxDiscountAmount'] ?? 0).toDouble(),
      usageLimit: json['usageLimit'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      expiresAt: json['expiresAt'] != null 
        ? (json['expiresAt'] is DateTime 
            ? json['expiresAt'] 
            : DateTime.parse(json['expiresAt']))
        : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is DateTime 
          ? json['updatedAt'] 
          : DateTime.parse(json['updatedAt']),
      );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
