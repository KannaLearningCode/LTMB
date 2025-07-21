// lib/Screens/Menu/detail_product_screen_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/Models/review.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Home/home_screen.dart';
import 'package:kfc_seller/Screens/More/Favorite/favorite_service.dart';
import 'package:kfc_seller/Screens/Review/review_service.dart';
import 'package:kfc_seller/Screens/Review/user_service.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';

class DetailProductPageRedesigned extends StatefulWidget {
  final Product product;
  final mongo.ObjectId userId;
  final Mongodbmodel user;

  const DetailProductPageRedesigned({
    super.key,
    required this.product,
    required this.userId,
    required this.user,
  });

  @override
  State<DetailProductPageRedesigned> createState() => _DetailProductPageRedesignedState();
}

class _DetailProductPageRedesignedState extends State<DetailProductPageRedesigned>
    with TickerProviderStateMixin {
  
  int quantity = 1;
  int _selectedIndex = 1;
  bool _isLoading = false;
  bool _isFavorite = false;

  late AnimationController _imageAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _contentSlideAnimation;

  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  final _commentController = TextEditingController();
  int _selectedStars = 5;


  @override
  void initState() {
    super.initState();
    
    FavoriteService.isFavorite(widget.userId, widget.product.id).then((value) {
      setState(() => _isFavorite = value);
    });

    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _imageScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _contentSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _imageAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });

    // Load cart để hiển thị số lượng có sẵn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setUser(widget.userId);
      cartProvider.loadCart(widget.userId);
    });

    _loadReviews();
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }
void _toggleFavorite() async {
  HapticFeedback.lightImpact();
  setState(() => _isFavorite = !_isFavorite);

  if (_isFavorite) {
    await FavoriteService.addFavorite(widget.userId, widget.product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào yêu thích')),
    );
  } else {
    await FavoriteService.removeFavorite(widget.userId, widget.product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
    );
  }
}


Future<void> _loadReviews() async {
  final reviews = await ReviewService.getReviewsByProductId(widget.product.id);
  List<Map<String, dynamic>> combined = [];

  double totalRating = 0;

  for (var review in reviews) {
    final user = await UserService.getUserById(review.userId);

    totalRating += review.rating;

    combined.add({
      'review': review,
      'user': user,
    });
  }

  setState(() {
    _reviews = combined;
    _averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
  });
}




  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            HomeScreenRedesigned(index: index, userId: widget.userId, user: widget.user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _addToCart() async {
    if (!widget.product.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sản phẩm hiện không có sẵn'),
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

    setState(() => _isLoading = true);
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      final newItem = CartItem(
        productId: widget.product.id,
        productName: widget.product.name,
        productImage: widget.product.image,
        description: widget.product.description,
        price: widget.product.price,
        quantity: quantity,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      cartProvider.addToCart(newItem);
      
      final existingCart = await cartProvider.fetchCartForUser(widget.userId);
      await cartProvider.updateCartInDB(
        Cart(
          id: existingCart?.id ?? mongo.ObjectId(),
          userId: widget.userId,
          items: cartProvider.items,
          createdAt: existingCart?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $quantity x ${widget.product.name} vào giỏ hàng'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Xem giỏ hàng',
            textColor: Colors.white,
            onPressed: () => _onItemTapped(2),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm vào giỏ hàng: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final totalPrice = widget.product.price * quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Tìm sản phẩm hiện tại trong giỏ hàng
          final existingItem = cartProvider.items.firstWhere(
            (item) => item.productId == widget.product.id,
            orElse: () => CartItem(
              productId: mongo.ObjectId(),
              productName: '',
              productImage: '',
              description: '',
              price: 0,
              quantity: 0,
              addedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final currentCartQuantity = existingItem.productName.isNotEmpty ? existingItem.quantity : 0;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Custom App Bar với image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      // Favorite button
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : AppColors.primary,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                      // Cart button
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
                                onPressed: () => _onItemTapped(2),
                              ),
                            ),
                            if (cartProvider.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${cartProvider.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: AnimatedBuilder(
                        animation: _imageScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _imageScaleAnimation.value,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  widget.product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 64,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!widget.product.isAvailable)
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Hết hàng',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Product content
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _contentSlideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _contentSlideAnimation.value),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product name và price
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.product.name,
                                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    widget.product.category,
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                // Hiển thị số lượng trong giỏ hàng
                                                if (currentCartQuantity > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.success.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.shopping_cart,
                                                          size: 12,
                                                          color: AppColors.success,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '$currentCartQuantity trong giỏ',
                                                          style: const TextStyle(
                                                            color: AppColors.success,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${currencyFormatter.format(widget.product.price)}VNĐ',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Description
                                  Text(
                                    'Mô tả sản phẩm',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.product.description ?? 'Món ăn ngon từ CKICKY với hương vị đặc trưng, được chế biến từ những nguyên liệu tươi ngon nhất.',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Product info cards
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoCard(
                                          'Trạng thái',
                                          widget.product.isAvailable ? 'Còn hàng' : 'Hết hàng',
                                          widget.product.isAvailable ? Icons.check_circle : Icons.cancel,
                                          widget.product.isAvailable ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildInfoCard(
                                          'Thời gian',
                                          '15-20 phút',
                                          Icons.access_time,
                                          AppColors.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),

                                  Text(
                                    'Đánh giá & Bình luận',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRatingSummary(),
                                  const SizedBox(height: 12),
                                  _buildReviewInput(),
                                  const SizedBox(height: 24),
                                  _buildReviewList(),

                                  const SizedBox(height: 180),

                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              // Bottom sheet với quantity và add to cart
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
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
                      
                      // Quantity selector
                      Row(
                        children: [
                          Text(
                            'Số lượng:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: quantity > 1 ? () {
                                    setState(() => quantity--);
                                    HapticFeedback.lightImpact();
                                  } : null,
                                  icon: const Icon(Icons.remove, color: AppColors.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '$quantity',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => quantity++);
                                    HapticFeedback.lightImpact();
                                  },
                                  icon: const Icon(Icons.add, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tổng: ${currencyFormatter.format(totalPrice)}đ',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (currentCartQuantity > 0)
                                Text(
                                  'Đã có $currentCartQuantity trong giỏ',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Add to cart button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: widget.product.isAvailable ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ) : null,
                          color: widget.product.isAvailable ? null : AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: widget.product.isAvailable ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ] : null,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: widget.product.isAvailable && !_isLoading ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add_shopping_cart, color: Colors.white),
                          label: Text(
                            _isLoading 
                                ? 'Đang thêm...' 
                                : currentCartQuantity > 0 
                                    ? 'Thêm nữa vào giỏ hàng'
                                    : 'Thêm vào giỏ hàng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // Bottom navigation
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Thực đơn'),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Giỏ hàng',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Thêm'),
              ],
              backgroundColor: Colors.white,
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
  return Row(
    children: [
      const Icon(Icons.star, color: Colors.amber),
      const SizedBox(width: 4),
      Text('${_averageRating.toStringAsFixed(1)} (${_reviews.length} đánh giá)'),
    ],
  );
}

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đánh giá sản phẩm của bạn:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _selectedStars ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() => _selectedStars = index + 1);
              },
            );
          }),
        ),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Viết bình luận...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            if (_commentController.text.trim().isEmpty) return;

            final review = Review(
              id: mongo.ObjectId(),
              userId: widget.userId,
              productId: widget.product.id,
              rating: _selectedStars,
              comment: _commentController.text.trim(),
              images: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userName: widget.user.name, // gắn tên user hiện tại
              userAvatar: widget.user.avatarUrl, // gắn avatar user hiện tại
            );

            await ReviewService.submitReview(review);
            _commentController.clear();
            _selectedStars = 5;
            _loadReviews();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gửi đánh giá!')),
            );
          },
          child: const Text('Gửi đánh giá'),
        ),
      ],
    );
  }

    Widget _buildReviewList() {
  if (_reviews.isEmpty) return const Text('Chưa có đánh giá nào.');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _reviews.map((reviewData) {
      final Review review = reviewData['review'];
      final Mongodbmodel? user = reviewData['user'];

      final avatarUrl = user?.avatarUrl?.isNotEmpty == true
          ? user!.avatarUrl
          : review.userAvatar;
      final userName = user?.name?.isNotEmpty == true
          ? user!.name
          : review.userName ?? 'Người dùng';

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : const AssetImage('assets/images/profile.png') as ImageProvider,
        ),
        title: Text(userName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(review.comment),
          ],
        ),
      );
    }).toList(),
  );
}

}
