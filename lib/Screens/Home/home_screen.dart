// lib/Screens/Home/home_screen_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Authen/login_screen.dart';
import 'package:kfc_seller/Screens/Home/profile_screen.dart';
import 'package:kfc_seller/Screens/Order/confirm_order_screen_old.dart';

// Import các tab redesigned (SỬA: import đúng các tab redesigned)
import '../Tabs/home_tab.dart';
import '../Menu/menu_tab.dart';
import '../Tabs/cart_tab.dart';
import '../Tabs/more_tab.dart';

class HomeScreenRedesigned extends StatefulWidget {
  final int index;
  final mongo.ObjectId userId;
  final Mongodbmodel user;

  const HomeScreenRedesigned({
    super.key,
    this.index = 0,
    required this.userId,
    required this.user,
  });

  @override
  State<HomeScreenRedesigned> createState() => _HomeScreenRedesignedState();
}

class _HomeScreenRedesignedState extends State<HomeScreenRedesigned>
    with TickerProviderStateMixin {
  
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _appBarAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _appBarSlideAnimation;
  
  bool _isNotificationVisible = false;
  int _cartItemCount = 0;
  
  // SỬA: Thêm GlobalKey để access MenuTab methods
  final GlobalKey<MenuTabRedesignedState> _menuTabKey = GlobalKey<MenuTabRedesignedState>();
  
  // SỬA: Thêm CartProvider listener để tránh memory leak
  CartProvider? _cartProvider;
  VoidCallback? _cartListener;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index;
    _pageController = PageController(initialPage: _selectedIndex);
    
    // Initialize animations
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _appBarSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    _fabAnimationController.forward();
    _appBarAnimationController.forward();
    
    // Load cart and listen to changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartData();
    });
  }

  @override
  void dispose() {
    // SỬA: Proper disposal để tránh memory leak
    _pageController.dispose();
    _fabAnimationController.dispose();
    _appBarAnimationController.dispose();
    
    // Remove cart listener
    if (_cartListener != null && _cartProvider != null) {
      _cartProvider!.removeListener(_cartListener!);
    }
    
    super.dispose();
  }

  void _loadCartData() async {
    if (!mounted) return;
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      _cartProvider = cartProvider;
      
      cartProvider.setUser(widget.userId);
      await cartProvider.loadCart(widget.userId);
      
      // SỬA: Setup listener an toàn với mounted check
      _cartListener = () {
        if (mounted) {
          setState(() {
            _cartItemCount = cartProvider.items.length;
          });
        }
      };
      
      cartProvider.addListener(_cartListener!);
      
      if (mounted) {
        setState(() {
          _cartItemCount = cartProvider.items.length;
        });
      }
    } catch (e) {
      print('Error loading cart data: $e');
    }
  }

  // SỬA: Thêm callback để liên kết tabs
  List<Widget> get _pages => [
    HomeTabRedesigned(
      onCategorySelected: (category) {
        // Chuyển sang MenuTab và filter theo category
        _safeNavigation(() {
          setState(() => _selectedIndex = 1);
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // Filter category trong MenuTab
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_menuTabKey.currentState != null) {
              _menuTabKey.currentState!.filterByCategory(category);
            }
          });
        });
      },
      onSearchQueryChanged: (query) {
        // Chuyển sang MenuTab và search
        if (query.isNotEmpty) {
          _safeNavigation(() {
            setState(() => _selectedIndex = 1);
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_menuTabKey.currentState != null) {
                _menuTabKey.currentState!.searchProducts(query);
              }
            });
          });
        }
      },
    ),
    MenuTabRedesigned(
      key: _menuTabKey,
      userId: widget.userId, 
      user: widget.user,
    ),
    CartTabRedesigned(
      user: widget.user,
      userId: widget.userId,
      onGoToMenuTab: () => _onItemTapped(1),
    ),
    const MoreTabRedesigned(),
  ];

  // SỬA: Safe navigation helper
  void _safeNavigation(VoidCallback navigation) {
    if (!mounted) return;
    
    try {
      navigation();
    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi chuyển trang: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted || index == _selectedIndex) return;
    
    _safeNavigation(() {
      setState(() => _selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Animation cho FAB nếu chuyển sang cart
      if (index == 2) {
        _fabAnimationController.reset();
        _fabAnimationController.forward();
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      _onItemTapped(0);
      return false;
    }
    
    if (currentBackPressTime == null ||
        DateTime.now().difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Nhấn back một lần nữa để thoát ứng dụng',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'profile':
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                ProfileScreenRedesigned(
                  user: widget.user,
                  userId: widget.userId,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
        
      case 'settings':
        _showSettingsDialog();
        break;
        
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  // SỬA: Thêm method để navigate to checkout
  void _navigateToCheckout() {
    if (!mounted) return;
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giỏ hàng đang trống'),
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

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ConfirmOrderScreen(
              userId: widget.userId,
              user: widget.user,
              items: cartProvider.items,
              totalPrice: cartProvider.totalPrice,
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

  void _showNotifications() {
    if (!mounted) return;
    
    setState(() {
      _isNotificationVisible = !_isNotificationVisible;
    });
    
    HapticFeedback.lightImpact();
    
    if (_isNotificationVisible) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildNotificationSheet(),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isNotificationVisible = false;
          });
        }
      });
    }
  }

  void _showSettingsDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cài đặt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.primary),
              title: const Text('Thông báo'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: const Text('Ngôn ngữ'),
              subtitle: const Text('Tiếng Việt'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: AppColors.primary),
              title: const Text('Chế độ tối'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
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
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    if (!mounted) return;
    
    try {
      // Clear cart
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.clearCart();
      
      // Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const LoginScreenRedesigned(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
          child: Column(
            children: [
              // Custom App Bar với animation
              AnimatedBuilder(
                animation: _appBarSlideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _appBarSlideAnimation.value),
                    child: _buildCustomAppBar(),
                  );
                },
              ),
              
              // Page Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (mounted) {
                          setState(() => _selectedIndex = index);
                        }
                      },
                      children: _pages,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Custom Bottom Navigation
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }
  
  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Row(
        children: [
          // Logo và tên app
          Expanded(
            child: Row(
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/logo1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CKICKY",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Xin chào, ${widget.user.name ?? 'Khách hàng'}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Notification và Menu
          Row(
            children: [
              // Notification button với badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isNotificationVisible 
                            ? Icons.notifications 
                            : Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _showNotifications,
                    ),
                    // Notification badge
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Profile menu
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  offset: const Offset(0, 50),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: AppColors.primary),
                          SizedBox(width: 12),
                          Text('Trang cá nhân'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Text('Cài đặt'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.error),
                          SizedBox(width: 12),
                          Text('Đăng xuất'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: _handleMenuSelection,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomBottomNav() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 1),
              label: 'Thực đơn',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.shopping_cart_outlined, Icons.shopping_cart, 2, 
                  badge: _cartItemCount > 0 ? _cartItemCount.toString() : null),
              label: 'Giỏ hàng',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.more_horiz_outlined, Icons.more_horiz, 3),
              label: 'Thêm',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavIcon(IconData outlined, IconData filled, int index, {String? badge}) {
    final isSelected = _selectedIndex == index;
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isSelected ? filled : outlined,
            size: 24,
          ),
        ),
        // Badge cho số lượng cart
        if (badge != null)
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
                badge,
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
    );
  }

  Widget _buildNotificationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông báo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Đánh dấu đã đọc'),
                ),
              ],
            ),
          ),
          
          // Notification list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 5, // Mock data
              itemBuilder: (context, index) {
                return _buildNotificationItem(
                  title: 'Đơn hàng #${1000 + index} đã được xác nhận',
                  subtitle: 'Đơn hàng của bạn đang được chuẩn bị...',
                  time: '${index + 1} phút trước',
                  isRead: index > 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isRead ? Colors.grey[300] : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
