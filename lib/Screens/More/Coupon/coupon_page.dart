// lib/Screens/More/Coupons/coupon_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/Screens/Voucher/VoucherService.dart';
import 'package:kfc_seller/Theme/app_theme.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  late Future<List<Coupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = CouponService.fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khuyến mãi & Voucher'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Coupon>>(
        future: _couponsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return const Center(child: Text('Không có voucher nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _buildCouponCard(coupon);
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final expiry = coupon.expiresAt != null
        ? DateFormat('dd/MM/yyyy').format(coupon.expiresAt!)
        : 'Không hết hạn';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coupon.code,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coupon.discountType == 'percentage'
                  ? 'Giảm ${coupon.discountValue}%'
                  : 'Giảm ${coupon.discountValue.toStringAsFixed(0)}đ',
              style: const TextStyle(fontSize: 16),
            ),
            if (coupon.minOrderAmount > 0)
              Text(
                'Đơn tối thiểu: ${coupon.minOrderAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (coupon.maxDiscountAmount > 0)
              Text(
                'Giảm tối đa: ${coupon.maxDiscountAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HSD: $expiry',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Đã dùng: ${coupon.usedCount}/${coupon.usageLimit}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
