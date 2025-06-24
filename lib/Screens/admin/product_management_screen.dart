import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

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

  // Thêm vào class _ProductManagementScreenState:
  String? selectedFilterCategoryId;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Lấy danh mục trước
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    super.dispose();
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
          SnackBar(content: Text('Tải ảnh lên thất bại: $e'), backgroundColor: Colors.red),
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

    final currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(product == null ? 'Thêm món mới' : 'Sửa món'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên món')),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
              TextField(controller: _compareAtPriceController, decoration: const InputDecoration(labelText: 'Giá so sánh (nếu có)'), keyboardType: TextInputType.number),
              TextField(controller: _skuController, decoration: const InputDecoration(labelText: 'Mã SKU (nếu có)')),
              TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Số lượng'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MongoDatabase.db.collection('categories').find().toList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  if (snapshot.hasError) return Text('Lỗi tải danh mục: ${snapshot.error}');
                  final categories = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String,
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MongoDatabase.db.collection('brands').find().toList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  if (snapshot.hasError) return Text('Lỗi tải thương hiệu: ${snapshot.error}');
                  final brands = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(labelText: 'Thương hiệu'),
                    items: brands.map<DropdownMenuItem<String>>((brand) {
                      return DropdownMenuItem<String>(
                        value: brand['name'] as String,
                        child: Text(brand['name']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedBrandId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 150)
                  : (product?.image != null && product!.image.isNotEmpty
                      ? Image.network(product.image, height: 150)
                      : Container()),
              TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Chọn ảnh từ thư viện')),
              if (_isUploading) const CircularProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (_isUploading) return;
              if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đủ thông tin bắt buộc.'), backgroundColor: Colors.orange),
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
                  const SnackBar(content: Text('Vui lòng chọn ảnh.'), backgroundColor: Colors.orange),
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
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(product == null ? 'Thêm' : 'Cập nhật'),
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
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'Quản lý sản phẩm',
          style: const TextStyle(color: Colors.white),
          ), 
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green),
      body: FutureBuilder(
        future: MongoDatabase.db.collection('products').find().toList(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

          final products = (snapshot.data ?? []).map((json) => Product.fromJson(json)).toList();
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
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
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood),
                      ),
                    ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${product.price.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('Danh mục: ${product.category}', style: TextStyle(color: Colors.grey[600])),
                      if (product.quantity > 0) Text('Số lượng: ${product.quantity}', style: TextStyle(color: Colors.grey[600])),
                      if (product.compareAtPrice != null) Text('Giá gốc: ${product.compareAtPrice?.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      if (product.sku != null && product.sku!.isNotEmpty) Text('SKU: ${product.sku}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showProductForm(product: product)),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text('Bạn có chắc muốn xóa món này?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
                                TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await MongoDatabase.db.collection('products').remove({'_id': product.id});
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xóa món!'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
