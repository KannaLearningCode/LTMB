import 'package:flutter/material.dart';

class QRCodePaymentPage extends StatelessWidget {
  final String qrImageUrl; // 🟢 thêm dòng này
  final String bankInfoText;
  final Function(String) onFinish;

  const QRCodePaymentPage({
    super.key,
    required this.qrImageUrl, // 🟢 và dòng này
    required this.bankInfoText,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán bằng mã QR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(qrImageUrl, height: 240), // 🟢 dùng ảnh QR
            const SizedBox(height: 20),
            Text(
              bankInfoText,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sau khi chuyển khoản, vui lòng nhấn nút bên dưới để xác nhận.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tôi đã chuyển khoản'),
              onPressed: () {
                final paymentId = 'QR-${DateTime.now().millisecondsSinceEpoch}';
                onFinish(paymentId);
              },
            )
          ],
        ),
      ),
    );
  }
}
