import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Screens/Home/home_screen.dart';

class OrderSuccessPage extends StatelessWidget {
  final String paymentId;
  final String paymentMethod;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final Mongodbmodel user;
  final mongo.ObjectId userId;

  const OrderSuccessPage({
    super.key,
    required this.paymentId,
    required this.paymentMethod,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.user,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán thành công', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo1.png', width: 180),
              const SizedBox(height: 24),
              const Text(
                'Cảm ơn bạn đã đặt hàng!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ✅ Hiển thị phương thức thanh toán
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Phương thức: $paymentMethod',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ Hiển thị thông tin người nhận
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 Người nhận: $receiverName', style: const TextStyle(fontSize: 16)),
                    Text('📞 Số điện thoại: $receiverPhone', style: const TextStyle(fontSize: 16)),
                    Text('📍 Địa chỉ: $receiverAddress', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Mã thanh toán:\n$paymentId',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(userId: userId, user: user),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('Quay về trang chính', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
