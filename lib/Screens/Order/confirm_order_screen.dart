import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart'; // Thêm dòng này

class ConfirmOrderScreen extends StatefulWidget {
  final Mongodbmodel user;

  const ConfirmOrderScreen({super.key, required this.user});

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  String selectedPayment = 'COD'; // COD, MoMo, PayPal, ZaloPay
  final shippingFee = 20000;
  final TextEditingController discountController = TextEditingController();
  // 🔽 Thêm biến lưu thông tin người nhận
  String? receiverName;
  String? receiverPhone;
  String? receiverAddress;
    @override
  void initState() {
    super.initState();
    // Gán mặc định từ user khi load lần đầu
    receiverName = widget.user.name ?? '';
    receiverPhone = widget.user.phone ?? '';
    receiverAddress = widget.user.address ?? '';
  }

void _showShippingInfoBottomSheet(BuildContext context) {
  final nameController = TextEditingController(text: receiverName);
  final phoneController = TextEditingController(text: receiverPhone);
  final addressController = TextEditingController(text: receiverAddress);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thông tin người nhận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ tên người nhận'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  receiverName = nameController.text;
                  receiverPhone = phoneController.text;
                  receiverAddress = addressController.text;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu thông tin người nhận')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalPrice + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(color: Colors.white),
          ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔶 DANH SÁCH SẢN PHẨM
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.lightBlueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productImage,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description ?? '(Không có mô tả)',
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, thickness: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${currency.format(item.price)}VNĐ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Bạn có mã giảm giá?', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,)
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    style: const TextStyle(fontSize: 16), 
                    decoration: const InputDecoration(
                      hintText: 'Mã giảm giá *',
                      hintStyle: TextStyle(fontSize: 16),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Áp dụng mã giảm giá
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(color: Colors.white),
                    ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // 🔶 Tổng đơn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng đơn hàng',
                  style: TextStyle(fontSize: 16),
                  ),
                Text(
                  '${currency.format(cart.totalPrice)}VNĐ',
                    style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí vận chuyển',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${currency.format(shippingFee)}VNĐ',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _showShippingInfoBottomSheet(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Thông tin người nhận hàng',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (receiverName != null && receiverName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👤 Người nhận: $receiverName', style: const TextStyle(fontSize: 16)),
                      Text('📞 SĐT: $receiverPhone', style: const TextStyle(fontSize: 16)),
                      Text('📍 Địa chỉ: $receiverAddress', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // 🔶 Phương thức thanh toán
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _paymentMethod('COD', Icons.inventory),
                _paymentMethod('MoMo', 'momo'),
                _paymentMethod('PayPal', 'paypal'),
                _paymentMethod('ZaloPay', 'zalopay'),
              ],
            ),
            const SizedBox(height: 16),

            // 🔶 Tổng thanh toán & nút
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${currency.format(total)}VNĐ', style: const TextStyle(color: Colors.red,fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Gửi đơn hàng
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đơn hàng đã được xác nhận!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Thanh toán ${currency.format(total)}VNĐ',
                  style: TextStyle(color: Colors.white),
                  ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _paymentMethod(String method, dynamic icon) {
    bool isSelected = selectedPayment == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = method;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? Colors.green : Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon is IconData
                ? Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 28)
                : Image.asset('assets/images/banking/$icon.png', height: 28),
          ),
          const SizedBox(height: 4),
          // 🔵 Dấu chấm chọn
          if (isSelected)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 8), // để giữ layout đều
        ],
      ),
    );
  }
}
