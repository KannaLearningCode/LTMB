// lib/Screens/Tabs/home_tab_redesigned.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Screens/Home/location_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTabRedesigned extends StatefulWidget {
  final Function(String)? onCategorySelected;
  final Function(String)? onSearchQueryChanged;
  final Function(int)? onNavigateToMenu; // Thêm callback để navigate
  
  const HomeTabRedesigned({
    super.key,
    this.onCategorySelected,
    this.onSearchQueryChanged,
    this.onNavigateToMenu,
  });

  @override
  State<HomeTabRedesigned> createState() => _HomeTabRedesignedState();
}

class _HomeTabRedesignedState extends State<HomeTabRedesigned>
    with TickerProviderStateMixin {
  
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  Timer? _timer;
  Map<String, List<Product>> _productsByCategory = {}; // Thay đổi structure
  List<String> _categories = [];
  bool _isLoading = true;
  String _currentAddress = "Đang tải vị trí...";
  bool _isLoadingLocation = true;

  final List<String> _banners = [
    'assets/images/banner/1.png',
    'assets/images/banner/2.png',
    'assets/images/banner/3.png',
  ];

  final List<String> _defaultAddresses = [
    "105/20/14 Cao Thắng, Quận 3, TP.HCM",
    "123 Nguyễn Văn Cừ, Quận 5, TP.HCM",
    "456 Lê Văn Sỹ, Quận 3, TP.HCM",
  ];

  @override
  void initState() {
    super.initState();
    
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
    
    _animationController.forward();
    
    // Load data
    _loadProductsByCategory(); // Thay đổi method load
    _getCurrentLocation();
    
    // Auto slide banner
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        _currentPage++;
        if (_currentPage >= _banners.length) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method mới để load products theo category
  Future<void> _loadProductsByCategory() async {
    try {
      final productData = await MongoDatabase.db.collection('products').find().toList();
      final products = productData.map<Product>((json) => Product.fromJson(json)).toList();
      
      // Group products by category
      Map<String, List<Product>> groupedProducts = {};
      for (var product in products) {
        if (!groupedProducts.containsKey(product.category)) {
          groupedProducts[product.category] = [];
        }
        groupedProducts[product.category]!.add(product);
      }
      
      if (mounted) {
        setState(() {
          _productsByCategory = groupedProducts;
          _categories = groupedProducts.keys.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading products by category: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      String address = await LocationService.getCurrentAddress();
      
      if (mounted) {
        setState(() {
          _currentAddress = address;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = _defaultAddresses[0];
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _openGoogleMaps() async {
    const url = 'https://www.google.com/maps';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
    }
  }

  void _showAddressOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn địa chỉ giao hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ..._defaultAddresses.map((address) => ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: Text(address),
              onTap: () {
                setState(() {
                  _currentAddress = address;
                });
                Navigator.pop(context);
              },
            )),
            ListTile(
              leading: const Icon(Icons.add_location, color: AppColors.secondary),
              title: const Text('Thêm địa chỉ mới'),
              onTap: () {
                Navigator.pop(context);
                _addNewAddress();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addNewAddress() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm địa chỉ mới'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập địa chỉ của bạn',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _currentAddress = controller.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Search và Address section
            _buildSearchAndAddress(),
            
            // Banner carousel
            _buildBannerCarousel(),
            
            // Categories với products - THAY ĐỔI CHÍNH Ở ĐÂY
            if (_isLoading)
              _buildLoadingState()
            else
              ..._buildCategoryProductSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Address bar
          GestureDetector(
            onTap: _showAddressOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giao đến',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_isLoadingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            _currentAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                widget.onSearchQueryChanged?.call(query);
                if (query.isNotEmpty) {
                  // Chuyển sang MenuTab khi search
                  widget.onNavigateToMenu?.call(1);
                }
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchQueryChanged?.call('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _currentPage = index);
                }
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.asset(
                          _banners[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surfaceVariant,
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Page indicators
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppColors.primary 
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải món ăn...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // METHOD MỚI - Tạo các section cho từng category
  List<Widget> _buildCategoryProductSections() {
    List<Widget> sections = [];
    
    for (String category in _categories) {
      final products = _productsByCategory[category] ?? [];
      if (products.isNotEmpty) {
        sections.add(_buildCategorySection(category, products));
        sections.add(const SizedBox(height: 24));
      }
    }
    
    return sections;
  }

  Widget _buildCategorySection(String category, List<Product> products) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final displayProducts = products.take(10).toList(); // Chỉ hiển thị 10 món đầu
    
    IconData categoryIcon;
    switch (category.toLowerCase()) {
      case 'gà rán':
      case 'ga ran':
        categoryIcon = Icons.food_bank;
        break;
      case 'burger':
        categoryIcon = Icons.lunch_dining;
        break;
      case 'combo':
        categoryIcon = Icons.set_meal;
        break;
      case 'nước uống':
      case 'nuoc uong':
        categoryIcon = Icons.local_drink;
        break;
      case 'tráng miệng':
      case 'trang mieng':
        categoryIcon = Icons.cake;
        break;
      default:
        categoryIcon = Icons.fastfood;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Category header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${products.length} món ăn',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút "Xem tất cả"
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Chuyển sang MenuTab với category được chọn
                    widget.onCategorySelected?.call(category);
                    widget.onNavigateToMenu?.call(1);
                  },
                  icon: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  label: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Product list horizontal
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                final product = displayProducts[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                product.image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Available status
                            if (!product.isAvailable)
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Hết hàng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Product info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${currencyFormatter.format(product.price)}đ',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: product.isAvailable ? () {
                                      HapticFeedback.lightImpact();
                                      // Add to cart logic
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã thêm ${product.name} vào giỏ hàng'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } : null,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: product.isAvailable 
                                            ? AppColors.primary 
                                            : AppColors.textSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}
