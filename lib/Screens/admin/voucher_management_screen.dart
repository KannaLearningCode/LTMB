import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/Screens/Voucher/VoucherService.dart';
import 'package:kfc_seller/Theme/colors.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  late Future<List<Coupon>> _couponsFuture;
  List<Coupon> _filteredCoupons = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // 'all', 'active', 'expired'
  String _filterType = 'all'; // 'all', 'percentage', 'fixed'

  @override
  void initState() {
    super.initState();
    _loadCoupons();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadCoupons() {
    setState(() {
      _couponsFuture = CouponService.fetchCoupons().then((coupons) {
        _filteredCoupons = coupons;
        return coupons;
      });
    });
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    _couponsFuture.then((coupons) {
      setState(() {
        _filteredCoupons = coupons.where((coupon) {
          // Search filter
          final searchMatch = coupon.code
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

          // Status filter
          final statusMatch = _filterStatus == 'all' ||
              (_filterStatus == 'active' && coupon.isActive) ||
              (_filterStatus == 'expired' &&
                  coupon.expiresAt != null &&
                  coupon.expiresAt!.isBefore(DateTime.now()));

          // Type filter
          final typeMatch = _filterType == 'all' ||
              coupon.discountType == _filterType;

          return searchMatch && statusMatch && typeMatch;
        }).toList();
      });
    });
  }

  void _showAddVoucherDialog(BuildContext context) {
    final codeController = TextEditingController();
    final discountValueController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'percentage';
    final usageLimitController = TextEditingController();
    final minOrderAmountController = TextEditingController(text: '0');
    final maxDiscountAmountController = TextEditingController(text: '0');

    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm mã voucher', style: TextStyle(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã voucher',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vui lòng nhập mã voucher' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại giảm giá',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Giảm theo %'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Giảm cố định'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: discountValueController,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị giảm',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị giảm';
                      if (double.tryParse(value) == null) return 'Giá trị không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usageLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Số lần sử dụng tối đa',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập số lần sử dụng';
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Số không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: minOrderAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn hàng tối thiểu (VNĐ)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
                      if (double.tryParse(value) == null) return 'Giá trị không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxDiscountAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Giảm tối đa (VNĐ)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
                      if (double.tryParse(value) == null) return 'Giá trị không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Chưa chọn ngày hết hạn'
                              : 'Hết hạn: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(color: AppColors.textSecondary)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: AppColors.textOnPrimary,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final code = codeController.text.trim();
                final value = double.parse(discountValueController.text.trim());
                final usageLimit = int.parse(usageLimitController.text.trim());
                final minOrderAmount = double.parse(minOrderAmountController.text.trim());
                final maxDiscountAmount = double.parse(maxDiscountAmountController.text.trim());

                final newCoupon = Coupon(
                  id: mongo.ObjectId(),
                  code: code,
                  discountType: selectedType,
                  discountValue: value,
                  usageLimit: usageLimit,
                  usedCount: 0,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  expiresAt: selectedDate,
                  minOrderAmount: minOrderAmount,
                  maxDiscountAmount: maxDiscountAmount,
                );

                await CouponService.addCoupon(newCoupon);

                if (mounted) Navigator.pop(context);
                _loadCoupons();
              }
            },
            child: const Text('Thêm', style: TextStyle(color: AppColors.textOnPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(List<Coupon> coupons) {
    if (coupons.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy voucher nào.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        final isExpired = coupon.expiresAt != null &&
            coupon.expiresAt!.isBefore(DateTime.now());
        final isActive = coupon.isActive && !isExpired;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppColors.surface,
          elevation: 2,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
            title: Text(
              coupon.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.discountType == 'percentage'
                      ? 'Giảm ${coupon.discountValue}%'
                      : 'Giảm ${coupon.discountValue.toStringAsFixed(0)} VNĐ',
                  style: TextStyle(
                    color: isActive ? AppColors.textSecondary : Colors.grey,
                  ),
                ),
                if (coupon.minOrderAmount > 0)
                  Text(
                    'Đơn tối thiểu: ${coupon.minOrderAmount.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (coupon.maxDiscountAmount > 0 && coupon.discountType == 'percentage')
                  Text(
                    'Giảm tối đa: ${coupon.maxDiscountAmount.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (coupon.expiresAt != null)
                  Text(
                    'HSD: ${coupon.expiresAt!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      color: isExpired ? AppColors.error : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  'Đã dùng: ${coupon.usedCount}/${coupon.usageLimit}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: isActive ? AppColors.success : AppColors.error,
            ),
            onTap: () {
              // Add edit functionality here if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              'Trạng thái:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildStatusChip('Đang hoạt động', 'active'),
                    const SizedBox(width: 8),
                    _buildStatusChip('Hết hạn', 'expired'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              'Loại giảm giá:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeChip('Tất cả', 'all'),
                    const SizedBox(width: 8),
                    _buildTypeChip('Giảm %', 'percentage'),
                    const SizedBox(width: 8),
                    _buildTypeChip('Giảm tiền', 'fixed'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildStatusChip(String label, String value) {
  return ChoiceChip(
    label: Text(label),
    selected: _filterStatus == value,
    onSelected: (selected) {
      setState(() {
        _filterStatus = value;
        _applyFilters();
      });
    },
    selectedColor: AppColors.primary ?? Colors.blue, // Fallback color
    backgroundColor: AppColors.surfaceVariant ?? Colors.grey[200], // Fallback color
    labelStyle: TextStyle(
      color: _filterStatus == value 
          ? (AppColors.textOnPrimary ?? Colors.white) // Fallback color
          : (AppColors.textSecondary ?? Colors.black), // Fallback color
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: _filterStatus == value 
            ? (AppColors.primary ?? Colors.blue) // Fallback color
            : (AppColors.outline ?? Colors.grey), // Fallback color
      ),
    ),
  );
}

Widget _buildTypeChip(String label, String value) {
  return ChoiceChip(
    label: Text(label),
    selected: _filterType == value,
    onSelected: (selected) {
      setState(() {
        _filterType = value;
        _applyFilters();
      });
    },
    selectedColor: AppColors.primary ?? Colors.blue, // Fallback color
    backgroundColor: AppColors.surfaceVariant ?? Colors.grey[200], // Fallback color
    labelStyle: TextStyle(
      color: _filterType == value 
          ? (AppColors.textOnPrimary ?? Colors.white) // Fallback color
          : (AppColors.textSecondary ?? Colors.black), // Fallback color
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: _filterType == value 
            ? (AppColors.primary ?? Colors.blue) // Fallback color
            : (AppColors.outline ?? Colors.grey), // Fallback color
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher', style: TextStyle(color: AppColors.textOnPrimary)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm voucher...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.textSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Coupon>>(
              future: _couponsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                } else {
                  return _buildCouponList(_filteredCoupons);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVoucherDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
    );
  }
}

