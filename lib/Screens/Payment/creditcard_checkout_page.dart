
import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';

class CreditCardCheckoutPage extends StatelessWidget {
  final List<CartItem> cartItems;
  final String paymentMethod;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final Mongodbmodel user;
  final dynamic userId;
  final double discountAmount;
  final Function(String) onFinish;

  const CreditCardCheckoutPage({
    super.key,
    required this.cartItems,
    required this.paymentMethod,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.user,
    required this.userId,
    required this.discountAmount,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    // Đây là UI giả lập – bạn có thể tích hợp Stripe, ZaloPay card API, v.v.
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán thẻ tín dụng')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Mô phỏng thanh toán thành công
            onFinish('CARD-${DateTime.now().millisecondsSinceEpoch}');
            Navigator.pop(context);
          },
          child: const Text('Xác nhận thanh toán'),
        ),
      ),
    );
  }
}
