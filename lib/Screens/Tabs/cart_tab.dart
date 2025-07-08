// lib/Screens/Tabs/cart_tab_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Order/confirm_order_screen.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart';

class CartTabRedesigned extends StatefulWidget {
  final mongo.ObjectId userId;
  final Mongodbmodel user;
  final VoidCallback? onGoToMenuTab;

  const CartTabRedesigned({
    super.key,
    required this.userId,
    this.onGoToMenuTab, 
    required this.user,
  });

  @override
  State<CartTabRedesigned> createState() => _CartTabRedesignedState();
}

class _CartTabRedesignedState extends State<CartTabRedesigned>
    with TickerProviderStateMixin {
  
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  // ✅ Thêm biến để track provider listener
  CartProvider? _cartProvider;
  VoidCallback? _cartListener;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    // ✅ Load cart data an toàn
    _loadCartData();
  }

  @override
  void dispose() {
    // ✅ Cancel animation controller trước
    _animationController.dispose();
    
    // ✅ Remove listener của CartProvider
    if (_cartListener != null && _cartProvider != null) {
      _cartProvider!.removeListener(_cartListener!);
    }
    
    super.dispose();
  }

  void _loadCartData() async {
    if (!mounted) return; // ✅ Check mounted trước khi làm gì
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      _cartProvider = cartProvider; // ✅ Lưu reference để remove listener sau
      
      cartProvider.setUser(widget.userId);
      await cartProvider.loadCart(widget.userId);
      
      // ✅ Setup listener an toàn
      _cartListener = () {
        if (mounted) { // ✅ Always check mounted trong listener
          setState(() {
            // Cart updated
          });
        }
      };
      
      cartProvider.addListener(_cartListener!);
      
      // ✅ Check mounted trước khi setState
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      // ✅ Handle error an toàn
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');

    if (_isLoading) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (cart.items.isEmpty) {
      return Container(
        color: AppColors.background,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Giỏ hàng đang trống',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy thêm món ăn yêu thích vào giỏ hàng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
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
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Khám phá thực đơn',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onGoToMenuTab?.call();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Giỏ hàng (${cart.items.length} món)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _showClearCartDialog(cart);
                  },
                  icon: const Icon(Icons.clear_all, color: AppColors.error),
                  label: const Text(
                    'Xóa tất cả',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item.productImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: AppColors.textSecondary,
                                        size: 32,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Product info
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
                                      item.description ?? 'Sản phẩm ngon',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Price and quantity controls
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${currencyFormatter.format(item.price)}đ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        
                                        // Quantity controls
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  _safeCartOperation(() {
                                                    cart.decreaseQuantity(item.productId);
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.remove,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  _safeCartOperation(() {
                                                    cart.increaseQuantity(item.productId);
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Remove button
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _safeCartOperation(() {
                                    cart.removeItem(item.productId);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Total and checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Total price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng cộng:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${currencyFormatter.format(cart.totalPrice)}đ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Checkout button
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _navigateToCheckout(cart);
                      },
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text(
                        'Tiến hành thanh toán',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  // ✅ Helper method để thực hiện cart operations an toàn
  void _safeCartOperation(VoidCallback operation) {
    if (!mounted) return;
    
    try {
      operation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToCheckout(CartProvider cart) {
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ConfirmOrderScreenRedesigned(
              userId: widget.userId, 
              user: widget.user,  
              items: cart.items,
              totalPrice: cart.totalPrice,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showClearCartDialog(CartProvider cart) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xóa tất cả sản phẩm?'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _safeCartOperation(() {
                cart.clearCart();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
