import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CouponService {
  static const String _dbUrl = MONGO_CONN_URL;
  static const String _collectionName = 'coupons';

  static Future<List<Coupon>> fetchCoupons() async {
    final db = await Db.create(_dbUrl);
    await db.open();
    final collection = db.collection(_collectionName);

    try {
      final result = await collection.find().toList();
      return result.map((e) {
        // Chuyển đổi các trường DateTime nếu cần
        if (e['expiresAt'] != null && e['expiresAt'] is! DateTime) {
          e['expiresAt'] = DateTime.parse(e['expiresAt']);
        }
        if (e['createdAt'] is! DateTime) {
          e['createdAt'] = DateTime.parse(e['createdAt']);
        }
        if (e['updatedAt'] is! DateTime) {
          e['updatedAt'] = DateTime.parse(e['updatedAt']);
        }
        return Coupon.fromJson(e);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  static Future<void> addCoupon(Coupon coupon) async {
    final db = await Db.create(_dbUrl);
    await db.open();
    final collection = db.collection(_collectionName);

    await collection.insertOne(coupon.toJson());
    await db.close();
  }

  static Future<bool> updateCouponUsage(String couponCode) async {
    final db = await Db.create(_dbUrl);
    await db.open();
    final collection = db.collection(_collectionName);

    // Lấy thông tin coupon hiện tại
    final coupon = await collection.findOne(where.eq('code', couponCode));
    
    if (coupon == null) {
      await db.close();
      throw Exception('Mã giảm giá không tồn tại');
    }

    // Kiểm tra nếu đã vượt quá giới hạn
    if (coupon['usageLimit'] > 0 && 
        coupon['usedCount'] >= coupon['usageLimit']) {
      await db.close();
      throw Exception('Mã giảm giá đã hết lượt sử dụng');
    }

    // Cập nhật số lần sử dụng
    final result = await collection.updateOne(
      where.eq('code', couponCode),
      modify
        .inc('usedCount', 1)
        .set('updatedAt', DateTime.now()),
    );

    await db.close();

    if (result.success) {
      return true;
    } else {
      throw Exception('Cập nhật thất bại');
    }
  }
}
