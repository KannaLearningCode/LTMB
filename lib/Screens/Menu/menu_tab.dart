// lib/Screens/Menu/menu_tab_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Screens/Menu/detail_product_screen.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/theme/app_theme.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';

class MenuTabRedesigned extends StatefulWidget {
  final mongo.ObjectId userId;
  final Mongodbmodel user;
  
  const MenuTabRedesigned({
    super.key, 
    required this.userId, 
    required this.user
  });

  @override
  State<MenuTabRedesigned> createState() => MenuTabRedesignedState();
}

class MenuTabRedesignedState extends State<MenuTabRedesigned>
    with TickerProviderStateMixin {
  
  late Future<List<Product>> _productsFuture;
  List<Product> allProducts = [];
  List<String> categories = [];
  String selectedCategory = 'Tất cả';
  String searchQuery = '';
  bool isGridView = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Method để filter theo category từ HomeTab
  void filterByCategory(String category) {
    if (mounted) {
      setState(() {
        selectedCategory = category;
        searchQuery = '';
        _searchController.clear();
      });
      
      // Scroll to top để user thấy kết quả
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Trigger rebuild để cập nhật UI
        }
      });
    }
  }

  // ✅ Method để search products từ HomeTab
  void searchProducts(String query) {
    if (mounted) {
      setState(() {
        searchQuery = query;
        selectedCategory = 'Tất cả'; // Reset category khi search
        _searchController.text = query;
      });
    }
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      final productData = await MongoDatabase.db.collection('products').find().toList();
      final products = productData.map<Product>((json) => Product.fromJson(json)).toList();

      final uniqueCategories = products.map((p) => p.category).toSet().toList();
      
      if (mounted) {
        setState(() {
          allProducts = products;
          categories = ['Tất cả', ...uniqueCategories];
        });
      }

      return products;
    } catch (e) {
      throw Exception('Lỗi khi tải sản phẩm: $e');
    }
  }

  List<Product> get filteredProducts {
    List<Product> filtered = selectedCategory == 'Tất cả' 
        ? allProducts 
        : allProducts.where((p) => p.category == selectedCategory).toList();
    
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  void _addToCart(Product product) async {
    if (!mounted) return;
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      final newItem = CartItem(
        productId: product.id,
        productName: product.name,
        productImage: product.image,
        description: product.description,
        price: product.price,
        quantity: 1,
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

      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${product.name} vào giỏ hàng'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');

    return Container(
      color: AppColors.background,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (allProducts.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                // Search và Filter Section
                _buildSearchAndFilter(),
                
                // Category Tabs
                _buildCategoryTabs(),
                
                // Results info
                if (searchQuery.isNotEmpty || selectedCategory != 'Tất cả')
                  _buildResultsInfo(),
                
                // Products Grid/List
                Expanded(
                  child: _buildProductsList(currencyFormatter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    final resultCount = filteredProducts.length;
    String infoText = '';
    
    if (searchQuery.isNotEmpty) {
      infoText = 'Tìm thấy $resultCount kết quả cho "$searchQuery"';
    } else if (selectedCategory != 'Tất cả') {
      infoText = '$resultCount sản phẩm trong "$selectedCategory"';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            infoText,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (searchQuery.isNotEmpty || selectedCategory != 'Tất cả')
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedCategory = 'Tất cả';
                  _searchController.clear();
                });
              },
              child: Text(
                'Xóa bộ lọc',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải sản phẩm...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _productsFuture = _fetchProducts();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có sản phẩm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
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
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món ăn...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // View toggle button
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
            child: IconButton(
              icon: Icon(
                isGridView ? Icons.view_list : Icons.grid_view,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  isGridView = !isGridView;
                });
                HapticFeedback.lightImpact();
              },
              tooltip: isGridView ? 'Xem dạng danh sách' : 'Xem dạng lưới',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ) : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(NumberFormat currencyFormatter) {
    final products = filteredProducts;
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty 
                  ? 'Không tìm thấy sản phẩm nào'
                  : 'Không có sản phẩm trong danh mục này',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Xem tất cả sản phẩm'),
              ),
            ]
          ],
        ),
      );
    }

    if (isGridView) {
      return _buildProductsGrid(products, currencyFormatter);
    } else {
      return _buildProductsList2(products, currencyFormatter);
    }
  }

  Widget _buildProductsGrid(List<Product> products, NumberFormat currencyFormatter) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductGridCard(product, currencyFormatter);
      },
    );
  }

  Widget _buildProductsList2(List<Product> products, NumberFormat currencyFormatter) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductListCard(product, currencyFormatter);
      },
    );
  }

  Widget _buildProductGridCard(Product product, NumberFormat currencyFormatter) {
    return Container(
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
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  DetailProductPageRedesigned(
                    product: product, 
                    userId: widget.userId, 
                    user: widget.user,
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
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Availability badge
                  if (!product.isAvailable)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
                          onTap: product.isAvailable 
                              ? () => _addToCart(product)
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.isAvailable 
                                  ? AppColors.primary 
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
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
      ),
    );
  }

  Widget _buildProductListCard(Product product, NumberFormat currencyFormatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  DetailProductPageRedesigned(
                    product: product, 
                    userId: widget.userId, 
                    user: widget.user,
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
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
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
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${currencyFormatter.format(product.price)}đ',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!product.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hết hàng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Add button
              Container(
                decoration: BoxDecoration(
                  gradient: product.isAvailable ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ) : null,
                  color: product.isAvailable ? null : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: product.isAvailable 
                        ? () => _addToCart(product)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Thêm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
}
