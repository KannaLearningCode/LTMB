import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:kfc_seller/Theme/colors.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedBrandId;
  File? _imageFile;
  bool _isUploading = false;
  
  // Filter and search related state
  final TextEditingController _searchController = TextEditingController();
  String? selectedCategoryFilter;
  String? selectedAvailabilityFilter;
  bool showFeaturedOnly = false;
  
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> brands = [];
  List<Product> products = [];
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchBrands();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryData = await MongoDatabase.db.collection('categories').find().toList();
      setState(() {
        categories = categoryData;
      });
    } catch (e) {
      debugPrint('Lỗi tải danh mục: $e');
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final brandData = await MongoDatabase.db.collection('brands').find().toList();
      setState(() {
        brands = brandData;
      });
    } catch (e) {
      debugPrint('Lỗi tải thương hiệu: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      print('Đang fetch dữ liệu sản phẩm...');
      final productData = await MongoDatabase.db.collection('products').find().toList();
      print('Số lượng sản phẩm nhận được từ DB: ${productData.length}');
      
      setState(() {
        products = productData.map<Product>((json) => Product.fromJson(json)).toList();
        print('Số lượng sản phẩm sau khi chuyển đổi: ${products.length}');
        filteredProducts = List<Product>.from(products);
      });
      _filterProducts();
    } catch (e) {
      debugPrint('Lỗi tải sản phẩm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải sản phẩm: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    final searchQuery = _searchController.text.toLowerCase();
    final categoryFilter = selectedCategoryFilter;
    final availabilityFilter = selectedAvailabilityFilter;
    final featuredFilter = showFeaturedOnly;

    setState(() {
      filteredProducts = products.where((product) {
        // Kiểm tra tìm kiếm
        final matchesSearch = searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchQuery) ||
            product.description.toLowerCase().contains(searchQuery) ||
            (product.sku?.toLowerCase().contains(searchQuery) ?? false);
        
        // Kiểm tra danh mục
        final matchesCategory = categoryFilter == null || 
            categoryFilter.isEmpty || 
            product.category == categoryFilter;
        
        // Kiểm tra tình trạng
        final matchesAvailability = availabilityFilter == null ||
            (availabilityFilter == 'Có sẵn' && (product.isAvailable && product.quantity > 0)) ||
            (availabilityFilter == 'Hết hàng' && (!product.isAvailable || product.quantity <= 0));
        
        // Kiểm tra sản phẩm nổi bật
        final matchesFeatured = !featuredFilter || 
            (product.compareAtPrice != null && product.compareAtPrice! > product.price);

        return matchesSearch && matchesCategory && matchesAvailability && matchesFeatured;
      }).toList();
      
      print('Số lượng sản phẩm sau khi lọc: ${filteredProducts.length}');
    });
  }

  Future<String> _uploadImage(File image) async {
    final cloudinary = CloudinaryPublic('dwdpxxkgs', 'KFC_Sellers');
    setState(() => _isUploading = true);

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      setState(() => _isUploading = false);
      return response.secureUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải ảnh lên thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showProductForm({Product? product}) {
    _clearForm();
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _compareAtPriceController.text = product.compareAtPrice?.toString() ?? '';
      _skuController.text = product.sku ?? '';
      _quantityController.text = product.quantity.toString();
      _selectedCategoryId = product.category;
      _imageFile = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          product == null ? 'Thêm món mới' : 'Sửa món',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên món',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Giá',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _compareAtPriceController,
                decoration: InputDecoration(
                  labelText: 'Giá so sánh (nếu có)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'Mã SKU (nếu có)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Số lượng',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                items: categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'] as String,
                    child: Text(
                      category['name'],
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBrandId,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  labelText: 'Thương hiệu',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                items: brands.map<DropdownMenuItem<String>>((brand) {
                  return DropdownMenuItem<String>(
                    value: brand['name'] as String,
                    child: Text(
                      brand['name'],
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedBrandId = value),
              ),
              const SizedBox(height: 16),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 150)
                  : (product?.image != null && product!.image.isNotEmpty
                      ? Image.network(product.image, height: 150)
                      : Container()),
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image, color: AppColors.primary),
                label: Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              if (_isUploading) CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_isUploading) return;
              if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng nhập đủ thông tin bắt buộc.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              String imageUrl = product?.image ?? '';
              if (_imageFile != null) {
                imageUrl = await _uploadImage(_imageFile!);
                if (imageUrl.isEmpty) return;
              }
              if (imageUrl.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng chọn ảnh.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              try {
                final price = double.parse(_priceController.text);
                final compareAtPrice = double.tryParse(_compareAtPriceController.text);
                final quantity = int.tryParse(_quantityController.text) ?? 0;

                final productData = Product(
                  id: product?.id ?? M.ObjectId(),
                  name: _nameController.text,
                  description: _descriptionController.text,
                  price: price,
                  compareAtPrice: compareAtPrice,
                  sku: _skuController.text.isEmpty ? null : _skuController.text,
                  quantity: quantity,
                  image: imageUrl,
                  category: _selectedCategoryId!,
                  isAvailable: true,
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (product == null) {
                  await MongoDatabase.db.collection('products').insert(productData.toJson());
                } else {
                  await MongoDatabase.db.collection('products').update(M.where.id(product.id), productData.toJson());
                }

                _clearForm();
                if (mounted) Navigator.pop(dialogContext);
                _fetchProducts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              product == null ? 'Thêm' : 'Cập nhật',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _compareAtPriceController.clear();
    _skuController.clear();
    _quantityController.clear();
    setState(() {
      _imageFile = null;
      _selectedCategoryId = null;
      _selectedBrandId = null;
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý sản phẩm',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
        backgroundColor: AppColors.primary,
        actions: [
          // Featured filter toggle button
          IconButton(
            icon: Icon(
              showFeaturedOnly ? Icons.star : Icons.star_border,
              color: showFeaturedOnly ? AppColors.primary : AppColors.textOnPrimary,
            ),
            onPressed: () {
              setState(() {
                showFeaturedOnly = !showFeaturedOnly;
                _filterProducts();
              });
            },
            tooltip: 'Chỉ hiển thị sản phẩm nổi bật',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchProducts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm sản phẩm',
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategoryFilter,
                          decoration: InputDecoration(
                            labelText: 'Danh mục',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          dropdownColor: AppColors.surface,
                          style: TextStyle(color: AppColors.textPrimary),
                          items: <String?>[null, ...categories.map((c) => c['name'] as String)]
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category ?? 'Tất cả danh mục', 
                                        style: TextStyle(color: AppColors.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryFilter = value;
                              _filterProducts();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedAvailabilityFilter,
                          decoration: InputDecoration(
                            labelText: 'Tình trạng',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          dropdownColor: AppColors.surface,
                          style: TextStyle(color: AppColors.textPrimary),
                          items: <String?>[null, 'Có sẵn', 'Hết hàng']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status ?? 'Tất cả tình trạng', 
                                        style: TextStyle(color: AppColors.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAvailabilityFilter = value;
                              _filterProducts();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showFeaturedOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Đang hiển thị sản phẩm nổi bật',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy sản phẩm phù hợp',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty || 
                              selectedCategoryFilter != null || 
                              selectedAvailabilityFilter != null ||
                              showFeaturedOnly)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  selectedCategoryFilter = null;
                                  selectedAvailabilityFilter = null;
                                  showFeaturedOnly = false;
                                  _filterProducts();
                                });
                              },
                              child: Text(
                                'Xóa bộ lọc',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.surfaceVariant,
                                  child: Icon(Icons.fastfood, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currency.format(product.price)} VNĐ',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Danh mục: ${product.category}',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                if (product.quantity > 0) Text(
                                  'Số lượng: ${product.quantity}',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                if (product.compareAtPrice != null) Text(
                                  'Giá gốc: ${currency.format(product.compareAtPrice)} VNĐ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                if (product.sku != null && product.sku!.isNotEmpty) Text(
                                  'SKU: ${product.sku}',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.primary),
                                  onPressed: () => _showProductForm(product: product),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        title: Text(
                                          'Xác nhận xóa',
                                          style: TextStyle(color: AppColors.textPrimary),
                                        ),
                                        content: Text(
                                          'Bạn có chắc muốn xóa món này?',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext, false),
                                            child: Text(
                                              'Hủy',
                                              style: TextStyle(color: AppColors.textSecondary),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext, true),
                                            child: Text(
                                              'Xóa',
                                              style: TextStyle(color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await MongoDatabase.db.collection('products').remove({'_id': product.id});
                                        if (mounted) {
                                          _fetchProducts();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Đã xóa món!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi khi xóa: $e'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
    );
  }
}