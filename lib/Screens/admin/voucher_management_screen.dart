import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/Screens/Voucher/VoucherService.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  late Future<List<Coupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    setState(() {
      _couponsFuture = CouponService.fetchCoupons();
    });
  }

  void _showAddVoucherDialog(BuildContext context) {
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'percentage';
  final _usageLimitController = TextEditingController(); // THÊM DÒNG NÀY

  DateTime? _selectedDate;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Thêm mã voucher'),
      content: Form(
        key: _formKey,
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Mã voucher'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập mã voucher' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Giảm theo %')),
                  DropdownMenuItem(value: 'fixed', child: Text('Giảm cố định')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _discountValueController,
                decoration: const InputDecoration(labelText: 'Giá trị giảm'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị giảm';
                  if (double.tryParse(value) == null) return 'Giá trị không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(labelText: 'Số lần sử dụng tối đa'),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số lần sử dụng';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Chưa chọn ngày hết hạn'
                          : 'Hết hạn: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final code = _codeController.text.trim();
              final value = double.parse(_discountValueController.text.trim());
              final usageLimit = int.parse(_usageLimitController.text.trim());

              final newCoupon = Coupon(
                id: mongo.ObjectId(),
                code: code,
                discountType: _selectedType,
                discountValue: value,
                usageLimit: usageLimit,
                usedCount: 0,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                expiresAt: _selectedDate,
                minOrderAmount: 0.0,
                maxDiscountAmount: 0.0,
              );


              await CouponService.addCoupon(newCoupon);

              if (mounted) Navigator.pop(context);
              _loadCoupons();
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    ),
  );
}



  Widget _buildCouponList(List<Coupon> coupons) {
    if (coupons.isEmpty) {
      return const Center(child: Text('Không có voucher nào.'));
    }

    return ListView.builder(
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              Icons.card_giftcard,
              color: coupon.isActive ? Colors.green : Colors.grey,
            ),
            title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.discountType == 'percentage'
                      ? 'Giảm ${coupon.discountValue}%'
                      : 'Giảm ${coupon.discountValue.toStringAsFixed(0)} VNĐ',
                ),
                if (coupon.expiresAt != null)
                  Text(
                    'HSD: ${coupon.expiresAt!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),

            trailing: Icon(
              coupon.isActive ? Icons.check_circle : Icons.cancel,
              color: coupon.isActive ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Coupon>>(
        future: _couponsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu'));
          } else {
            return _buildCouponList(snapshot.data!);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVoucherDialog(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
