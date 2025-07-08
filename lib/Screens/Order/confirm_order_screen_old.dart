import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Order/order_service.dart';
import 'package:kfc_seller/Screens/Order/order_success_page_old.dart';
import 'package:kfc_seller/Screens/Payment/paypal_checkout_page.dart';
import 'package:kfc_seller/Screens/Voucher/VoucherService.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart'; // Thêm dòng này
import 'package:kfc_seller/VNPay/vnpay_helper.dart';
import 'package:kfc_seller/VNPay/vnpay_webview_page.dart';

class ConfirmOrderScreen extends StatefulWidget {
  final Mongodbmodel user;
  final mongo.ObjectId userId;
  final List<CartItem> items;
  final double totalPrice;

  const ConfirmOrderScreen({super.key, required this.user, required this.userId, required this.items, required this.totalPrice,});

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  String selectedPayment = 'COD'; // COD, MoMo, PayPal, ZaloPay
  final shippingFee = 20000;
  final TextEditingController discountController = TextEditingController();
  final GlobalKey _dropdownKey = GlobalKey();
  List<Coupon> availableCoupons = [];
  bool isLoadingCoupons = true;

  Coupon? appliedCoupon;
  double discountAmount = 0;


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
    loadAvailableCoupons();
  }

void loadAvailableCoupons() async {
  final allCoupons = await CouponService.fetchCoupons();
  final now = DateTime.now();

  print('All coupons: ${allCoupons.map((c) => c.code)}'); // 🔍 Debug
  for (var c in allCoupons) {
    print(
      '↪️ ${c.code} | active: ${c.isActive} | used: ${c.usedCount}/${c.usageLimit} | expiresAt: ${c.expiresAt}');
  }

  setState(() {
    availableCoupons = allCoupons.where((coupon) =>
      coupon.isActive &&
      (coupon.usageLimit == 0 || coupon.usageLimit > coupon.usedCount) &&
      (coupon.expiresAt == null || coupon.expiresAt!.isAfter(now))
    ).toList();
  });
}



void _fetchAvailableCoupons() async {
    try {
      final coupons = await CouponService.fetchCoupons();
      final now = DateTime.now();

      setState(() {
        availableCoupons = coupons.where((coupon) {
          final notExpired = coupon.expiresAt == null || coupon.expiresAt!.isAfter(now);
          final hasRemainingUsage = coupon.usageLimit == 0 || coupon.usedCount < coupon.usageLimit;
          return coupon.isActive && notExpired && hasRemainingUsage;
        }).toList();
        isLoadingCoupons = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCoupons = false;
      });
    }
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
    final total = (cart.totalPrice - discountAmount) + shippingFee;
    
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
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
  ),
),
const SizedBox(height: 8),
Row(
  children: [
    Expanded(
      child: GestureDetector(
        key: _dropdownKey,
        onTap: () async {
          if (availableCoupons.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không có mã giảm giá khả dụng.')),
            );
            return;
          }

          final RenderBox renderBox =
              _dropdownKey.currentContext!.findRenderObject() as RenderBox;
          final Offset offset = renderBox.localToGlobal(Offset.zero);

          final selectedCode = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              offset.dx,
              offset.dy + 50, // điều chỉnh vị trí hiển thị dropdown
              offset.dx + 200,
              offset.dy,
            ),
            items: availableCoupons.map((coupon) {
              final displayValue = coupon.discountType == 'percentage'
                  ? '${coupon.discountValue}%'
                  : '${coupon.discountValue.toStringAsFixed(0)}đ';
              return PopupMenuItem<String>(
                value: coupon.code,
                child: Text('${coupon.code} ($displayValue)'),
              );
            }).toList(),
          );

          if (selectedCode != null) {
            setState(() {
              discountController.text = selectedCode;
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: discountController,
            decoration: const InputDecoration(
              labelText: 'Chọn mã giảm giá',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: 8),
    ElevatedButton(
      onPressed: () {
  final enteredCode = discountController.text.trim();
  final coupon = availableCoupons.firstWhere(
    (c) => c.code == enteredCode,
    orElse: () => Coupon(
      id: mongo.ObjectId(),
      code: '',
      discountType: 'fixed',
      discountValue: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
    ),
  );

  if (coupon.code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mã giảm giá không hợp lệ.')),
    );
  } else {
    // ✅ Tính số tiền giảm
    final cartTotal = widget.totalPrice;
    double calculatedDiscount = 0;

    if (coupon.discountType == 'percentage') {
      calculatedDiscount = (cartTotal * coupon.discountValue / 100);
      if (coupon.maxDiscountAmount > 0 &&
          calculatedDiscount > coupon.maxDiscountAmount) {
        calculatedDiscount = coupon.maxDiscountAmount;
      }
    } else {
      calculatedDiscount = coupon.discountValue;
    }

    // Không cho giảm quá tổng tiền
    if (calculatedDiscount > cartTotal) {
      calculatedDiscount = cartTotal;
    }

    setState(() {
      appliedCoupon = coupon;
      discountAmount = calculatedDiscount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Áp dụng mã ${coupon.code} thành công!')),
    );
  }
},

      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
      child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
    ),
    if (appliedCoupon != null)
  TextButton.icon(
    onPressed: () {
      setState(() {
        appliedCoupon = null;
        discountAmount = 0;
        discountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy mã giảm giá.')),
      );
    },
    icon: const Icon(Icons.close, color: Colors.red),
    label: const Text('Hủy mã', style: TextStyle(color: Colors.red)),
  ),

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
            if (discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giảm giá:', style: TextStyle(fontSize: 16)),
                Text('-${currency.format(discountAmount)}VNĐ', style: const TextStyle(fontSize: 16, color: Colors.green)),
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
                _paymentMethod('Zalopay', 'zalopay'),
                _paymentMethod('VNPay', 'vnpay'),
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
                onPressed: () async {
                   if (selectedPayment != 'PayPal' && selectedPayment != 'VNPay'  && selectedPayment != 'COD') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔧 Chức năng đang phát triển. Vui lòng chọn phương thức khác!')),
                    );
                    return;
                  }
                  final now = DateTime.now();
                  final mongo.ObjectId orderId = mongo.ObjectId();
                  final mongo.ObjectId userId = mongo.ObjectId.parse(widget.user.id);

                  final orderItems = cart.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return OrderItem(
                      id: i + 1,
                      orderId: orderId,
                      productId: item.productId,
                      quantity: item.quantity,
                      price: item.price,
                      productName: item.productName,
                      productImage: item.productImage,
                    );
                  }).toList();

                  final order = Order(
                    id: orderId,
                    userId: userId,
                    items: orderItems,
                    totalAmount: cart.totalPrice + shippingFee,
                    paymentMethod: selectedPayment,
                    paymentStatus: selectedPayment == 'COD' ? 'Đang xử lý' : 'Đã thanh toán',
                    shippingAddress: receiverAddress ?? '',
                    billingAddress: receiverAddress ?? '',
                    phone: receiverPhone ?? '',
                    createdAt: now,
                    updatedAt: now,
                  );

                  if (selectedPayment == 'PayPal') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaypalCheckoutPage(
                          cartItems: cart.items,
                          paymentMethod: 'PayPal',
                          receiverName: receiverName ?? '',
                          receiverPhone: receiverPhone ?? '',
                          receiverAddress: receiverAddress ?? '',
                          user: widget.user,
                          userId: widget.userId,
                          discountAmount: discountAmount,
                          onFinish: (paymentId) async {
                            try {
                              await OrderService.insertOrder(order);
                              cart.clearCart();

                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderSuccessPage(
                                      paymentId: paymentId,
                                      paymentMethod: 'PayPal',
                                      receiverName: receiverName ?? '',
                                      receiverPhone: receiverPhone ?? '',
                                      receiverAddress: receiverAddress ?? '',
                                      user: widget.user,
                                      userId: widget.userId,
                                    ),
                                  ),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi lưu đơn hàng: ${e.toString()}')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }
                  else if (selectedPayment == 'VNPay') {
  final url = createVNPayUrl(
    tmnCode: 'ZB2CAHDR',
    hashKey: 'QBMWNZ5XHK2NGARCY75SQEHG0B5NYPQZ',
    amount: cart.totalPrice + shippingFee - discountAmount,
    orderInfo: 'Thanh toan don hang cua ${receiverName ?? "Khach hang"}',
    returnUrl: 'https://sandbox.vnpayment.vn/return',
  );
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VNPayWebViewPage(
        paymentUrl: url,
        returnUrl: 'https://sandbox.vnpayment.vn/return',
        onFinish: (returnUrl) async {
          final uri = Uri.parse(returnUrl);
          final responseCode = uri.queryParameters['vnp_ResponseCode'];
          final txnRef = uri.queryParameters['vnp_TxnRef'] ?? '';

          if (responseCode == '00') {
            // Thành công, tạo Order mới
            try {
              final now = DateTime.now();
              final mongo.ObjectId newOrderId = mongo.ObjectId();
              final orderItems = cart.items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return OrderItem(
                  id: i + 1,
                  orderId: newOrderId,
                  productId: item.productId,
                  quantity: item.quantity,
                  price: item.price,
                  productName: item.productName,
                  productImage: item.productImage,
                );
              }).toList();

              final newOrder = Order(
                id: newOrderId,
                userId: widget.userId,
                items: orderItems,
                totalAmount: cart.totalPrice + shippingFee - discountAmount,
                paymentMethod: 'VNPay',
                paymentStatus: 'Đã thanh toán',
                shippingAddress: receiverAddress ?? '',
                billingAddress: receiverAddress ?? '',
                phone: receiverPhone ?? '',
                createdAt: now,
                updatedAt: now,
              );

              await OrderService.insertOrder(newOrder);
              cart.clearCart();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderSuccessPage(
                      paymentId: txnRef,
                      paymentMethod: 'VNPay',
                      receiverName: receiverName ?? '',
                      receiverPhone: receiverPhone ?? '',
                      receiverAddress: receiverAddress ?? '',
                      user: widget.user,
                      userId: widget.userId,
                    ),
                  ),
                  (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi lưu đơn hàng: ${e.toString()}')),
                );
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thanh toán thất bại hoặc bị hủy!')),
            );
          }
        },
      ),
    ),
  );
}

                 else {
                    // ✅ Xử lý thanh toán còn lại (COD, MoMo, ZaloPay)
                    try {
                      await OrderService.insertOrder(order);
                      cart.clearCart();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderSuccessPage(
                              paymentId: order.id.toHexString(), // dùng orderId làm mã thanh toán
                              paymentMethod: selectedPayment,
                              receiverName: receiverName ?? '',
                              receiverPhone: receiverPhone ?? '',
                              receiverAddress: receiverAddress ?? '',
                              user: widget.user,
                              userId: widget.userId,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi lưu đơn hàng: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Thanh toán ${currency.format(total)}VNĐ',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
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
