// lib/Screens/Order/confirm_order_screen_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Home/home_screen_old.dart';
import 'package:kfc_seller/Screens/Order/order_service.dart';
import 'package:kfc_seller/Screens/Order/order_success_page.dart';
import 'package:kfc_seller/Screens/Payment/paypal_checkout_page.dart';
import 'package:kfc_seller/Screens/Payment/vnpay_checkout_page.dart';
import 'package:kfc_seller/Screens/Voucher/VoucherService.dart';
import 'package:kfc_seller/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/VNPay/vnpay_helper.dart';
import 'package:kfc_seller/VNPay/vnpay_webview_page.dart';

class ConfirmOrderScreenRedesigned extends StatefulWidget {
  final Mongodbmodel user;
  final mongo.ObjectId userId;
  final List<CartItem> items;
  final double totalPrice;

  const ConfirmOrderScreenRedesigned({
    super.key,
    required this.user,
    required this.userId,
    required this.items,
    required this.totalPrice,
  });

  @override
  State<ConfirmOrderScreenRedesigned> createState() => _ConfirmOrderScreenRedesignedState();
}

class _ConfirmOrderScreenRedesignedState extends State<ConfirmOrderScreenRedesigned>
    with TickerProviderStateMixin {
  
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  String selectedPayment = 'COD';
  final shippingFee = 20000;
  final TextEditingController discountController = TextEditingController();
  final GlobalKey _dropdownKey = GlobalKey();
  List<Coupon> availableCoupons = [];
  bool isLoadingCoupons = true;

  Coupon? appliedCoupon;
  double discountAmount = 0;

  String? receiverName;
  String? receiverPhone;
  String? receiverAddress;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
    
    // Initialize data
    receiverName = widget.user.name ?? '';
    receiverPhone = widget.user.phone ?? '';
    receiverAddress = widget.user.address ?? '';
    loadAvailableCoupons();
  }

  @override
  void dispose() {
    _animationController.dispose();
    discountController.dispose();
    super.dispose();
  }

  // Giữ nguyên toàn bộ logic xử lý từ code cũ
  void loadAvailableCoupons() async {
    final allCoupons = await CouponService.fetchCoupons();
    final now = DateTime.now();

    print('All coupons: ${allCoupons.map((c) => c.code)}');
    for (var c in allCoupons) {
      print(
        '↪️ ${c.code} | active: ${c.isActive} | used: ${c.usedCount}/${c.usageLimit} | expiresAt: ${c.expiresAt}');
    }

    if (mounted) {
      setState(() {
        availableCoupons = allCoupons.where((coupon) =>
          coupon.isActive &&
          (coupon.usageLimit == 0 || coupon.usageLimit > coupon.usedCount) &&
          (coupon.expiresAt == null || coupon.expiresAt!.isAfter(now))
        ).toList();
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Thông tin người nhận',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              _buildInputField(nameController, 'Họ tên người nhận', Icons.person),
              const SizedBox(height: 16),
              _buildInputField(phoneController, 'Số điện thoại', Icons.phone, 
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildInputField(addressController, 'Địa chỉ giao hàng', Icons.location_on),
              
              const SizedBox(height: 24),
              
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      receiverName = nameController.text;
                      receiverPhone = phoneController.text;
                      receiverAddress = addressController.text;
                    });
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã lưu thông tin người nhận'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Lưu thông tin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = (cart.totalPrice - discountAmount) + shippingFee;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.background,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),
              
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: _buildMainContent(cart, total),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Xác nhận đơn hàng',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildMainContent(CartProvider cart, double total) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        // Order Items
        _buildOrderItems(cart),
        
        const SizedBox(height: 20),
        
        // Coupon Section
        _buildCouponSection(),
        
        const SizedBox(height: 20),
        
        // Shipping Info
        _buildShippingInfo(),
        
        const SizedBox(height: 20),
        
        // Payment Method
        _buildPaymentMethodSection(),
        
        const SizedBox(height: 20),
        
        // Order Summary
        _buildOrderSummary(cart, total),
        
        const SizedBox(height: 20),
        
        // Checkout Button
        _buildCheckoutButton(cart, total),
      ],
    ),
  );
}

Widget _buildOrderItems(CartProvider cart) {
  return Container(
    height: 300, // Đặt chiều cao cố định
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.shopping_bag, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Danh sách sản phẩm (${cart.items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cart.items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.productImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fastfood,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description ?? 'Món ăn ngon',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${currency.format(item.price)}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    ),
  );
}


  Widget _buildOrderSummary(CartProvider cart, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Tóm tắt đơn hàng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Tổng đơn hàng', '${currency.format(cart.totalPrice)}đ'),
          
          if (discountAmount > 0)
            _buildSummaryRow('Giảm giá', '-${currency.format(discountAmount)}đ', 
                color: AppColors.success),
          
          _buildSummaryRow('Phí vận chuyển', '${currency.format(shippingFee)}đ'),
          
          const Divider(thickness: 1),
          
          _buildSummaryRow(
            'Tổng thanh toán',
            '${currency.format(total)}đ',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Mã giảm giá',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: _dropdownKey,
                  onTap: () async {
                    if (availableCoupons.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Không có mã giảm giá khả dụng.'),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
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
                        offset.dy + 50,
                        offset.dx + 200,
                        offset.dy,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: TextFormField(
                        controller: discountController,
                        decoration: const InputDecoration(
                          labelText: 'Chọn mã giảm giá',
                          suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Giữ nguyên logic áp dụng coupon từ code cũ
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
                        SnackBar(
                          content: const Text('Mã giảm giá không hợp lệ.'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    } else {
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

                      if (calculatedDiscount > cartTotal) {
                        calculatedDiscount = cartTotal;
                      }

                      setState(() {
                        appliedCoupon = coupon;
                        discountAmount = calculatedDiscount;
                      });

                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Áp dụng mã ${coupon.code} thành công!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã áp dụng mã ${appliedCoupon!.code}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          appliedCoupon = null;
                          discountAmount = 0;
                          discountController.clear();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã hủy mã giảm giá.'),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close, color: AppColors.error, size: 16),
                      label: const Text(
                        'Hủy',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.info, size: 24),
              const SizedBox(width: 8),
              Text(
                'Thông tin giao hàng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (receiverName != null && receiverName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        receiverName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        receiverPhone!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          receiverAddress!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.info, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showShippingInfoBottomSheet(context);
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text(
                receiverName != null && receiverName!.isNotEmpty
                    ? 'Chỉnh sửa thông tin'
                    : 'Thêm thông tin người nhận',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'Phương thức thanh toán',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildPaymentMethodCard('COD', Icons.inventory, 'Tiền mặt'),
              _buildPaymentMethodCard('MoMo', 'momo', 'MoMo'),
              _buildPaymentMethodCard('PayPal', 'paypal', 'PayPal'),
              _buildPaymentMethodCard('Zalopay', 'zalopay', 'ZaloPay'),
              _buildPaymentMethodCard('VNPay', 'vnpay', 'VNPay'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method, dynamic icon, String label) {
    bool isSelected = selectedPayment == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = method;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 32,
              )
            else
              Image.asset(
                'assets/images/banking/$icon.png',
                height: 32,
                color: isSelected ? AppColors.primary : null,
              ),
            
            const SizedBox(height: 8),
            
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(CartProvider cart, double total) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          
          // Giữ nguyên toàn bộ logic xử lý thanh toán từ code cũ
          if (selectedPayment != 'PayPal' && selectedPayment != 'VNPay' && selectedPayment != 'COD') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🔧 Chức năng đang phát triển. Vui lòng chọn phương thức khác!'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
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

          // Xử lý thanh toán theo từng phương thức (giữ nguyên logic cũ)
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
                            builder: (_) => OrderSuccessPageRedesigned(
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
                              builder: (_) => OrderSuccessPageRedesigned(
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
            // COD và các phương thức khác
            try {
              await OrderService.insertOrder(order);
              cart.clearCart();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderSuccessPageRedesigned(
                      paymentId: order.id.toHexString(),
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
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Thanh toán ${currency.format(total)}đ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
