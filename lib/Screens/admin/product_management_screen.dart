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
  // Controllers cho form thêm/sửa món
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Controllers mới cho các trường bổ sung
  final _compareAtPriceController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  
  // Không dùng _imageController trực tiếp nữa, vì dùng _imageFile và Image.network
  // final _imageController = TextEditingController(); 

  // Biến để lưu giá trị được chọn từ Dropdown cho Category và Brand
  String? _selectedCategoryId;
  String? _selectedBrandId;

  // Thêm biến để lưu file ảnh đã chọn
  File? _imageFile;
  // Thêm biến để hiển thị trạng thái đang tải ảnh
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose(); // Dispose controller mới
    _skuController.dispose();            // Dispose controller mới
    _quantityController.dispose();       // Dispose controller mới
    // _categoryController.dispose(); // Không cần dispose nếu dùng _selectedCategoryId
    // _imageController.dispose(); // Không cần dispose nếu không dùng
    super.dispose();
  }

  Future<String> _uploadImage(File image) async {
    final cloudinary = CloudinaryPublic('dwdpxxkgs', 'KFC_Sellers'); // Thay bằng thông tin của bạn
    
    setState(() {
      _isUploading = true;
    });

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      setState(() {
        _isUploading = false;
      });
      return response.secureUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print(e.toString());
      if (mounted) { // Kiểm tra nếu widget vẫn còn được mount trước khi hiển thị SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải ảnh lên thất bại: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
      return '';
    }
  }

  // Hàm để chọn ảnh
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Hiển thị form thêm/sửa món
  void _showProductForm({Product? product}) {
    // Reset controllers và biến khi mở form mới
    _clearForm(); 

    if (product != null) {
      // Nếu là sửa, điền thông tin sẵn có
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      
      // Điền thông tin cho các trường mới
      _compareAtPriceController.text = product.compareAtPrice?.toString() ?? '';
      _skuController.text = product.sku ?? '';
      _quantityController.text = product.quantity.toString();

      // Điền giá trị cho dropdown
      _selectedCategoryId = product.category; // Category là String trong Product model
      _imageFile = null; // Đặt _imageFile về null để hiển thị ảnh từ URL nếu có
    }

    // Lưu context vào biến local để tránh truy cập sau khi widget bị hủy
    final currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(product == null ? 'Thêm món mới' : 'Sửa món'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
              // Thêm các trường mới
              TextField(
                controller: _compareAtPriceController,
                decoration: const InputDecoration(labelText: 'Giá so sánh (nếu có)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'Mã SKU (nếu có)'),
              ),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Dropdown cho Danh mục
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MongoDatabase.db.collection('categories').find().toList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Lỗi tải danh mục: ${snapshot.error}');
                  }

                  final categories = snapshot.data ?? [];
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String, // Hoặc category['_id'].toHexString() nếu bạn muốn lưu ObjectId
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() { // Cần setState để cập nhật UI của Dropdown
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn danh mục';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Dropdown cho Thương hiệu (ví dụ, bạn cần collection 'brands' tương tự categories)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MongoDatabase.db.collection('brands').find().toList(), // Giả sử có collection 'brands'
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Lỗi tải thương hiệu: ${snapshot.error}');
                  }

                  final brands = snapshot.data ?? [];
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(labelText: 'Thương hiệu'),
                    items: brands.map<DropdownMenuItem<String>>((brand) {
                      return DropdownMenuItem<String>(
                        value: brand['name'] as String, // Hoặc brand['_id'].toHexString()
                        child: Text(brand['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrandId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Thêm phần chọn và hiển thị ảnh
              _imageFile != null
                  ? Image.file(_imageFile!, height: 150)
                  : (product?.image != null && product!.image.isNotEmpty
                      ? Image.network(product.image, height: 150)
                      : Container()),
              
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh từ thư viện'),
              ),

              if (_isUploading) const CircularProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear form và đóng dialog
              _clearForm();
              Navigator.pop(dialogContext);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Nếu đang upload thì không cho nhấn
              if (_isUploading) return;

              // Kiểm tra các trường nhập liệu bắt buộc
              if (_nameController.text.isEmpty || 
                  _priceController.text.isEmpty || 
                  _selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đủ thông tin bắt buộc (Tên, Giá, Danh mục).'), backgroundColor: Colors.orange),
                  );
                  return;
              }

              String imageUrl = product?.image ?? '';

              // Nếu có chọn ảnh mới thì mới tải lên
              if (_imageFile != null) {
                imageUrl = await _uploadImage(_imageFile!);
                if (imageUrl.isEmpty) {
                  // Có lỗi xảy ra khi upload, không tiếp tục
                  return;
                }
              }

              // Nếu không có ảnh mới và cũng không có ảnh cũ thì báo lỗi
              if (imageUrl.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn ảnh cho sản phẩm.'), backgroundColor: Colors.orange),
                  );
                  return;
              }

              try {
                final double price = double.parse(_priceController.text);
                final double? compareAtPrice = double.tryParse(_compareAtPriceController.text);
                final int quantity = int.tryParse(_quantityController.text) ?? 0; // Default về 0 nếu không nhập hoặc lỗi

                final productData = Product(
                  id: product?.id ?? M.ObjectId(), // Nếu là thêm mới, tạo ObjectId mới
                  name: _nameController.text,
                  description: _descriptionController.text,
                  price: price,
                  compareAtPrice: compareAtPrice, // Thêm
                  sku: _skuController.text.isEmpty ? null : _skuController.text, // Thêm
                  quantity: quantity, // Thêm
                  image: imageUrl, // Giờ là URL ảnh từ Cloudinary
                  category: _selectedCategoryId!, // Lấy từ dropdown
                  isAvailable: true, // Bạn có thể thêm toggle cho trạng thái này
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (product == null) {
                  // Thêm mới
                  await MongoDatabase.db
                      .collection('products')
                      .insert(productData.toJson());
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Thêm món thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  // Cập nhật
                  await MongoDatabase.db.collection('products').update(
                    M.where.id(product.id),
                    productData.toJson(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật món thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }

                // Clear form và đóng dialog
                _clearForm();
                if (mounted) {
                  Navigator.pop(dialogContext);
                }
                
                // Refresh danh sách
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                print('Lỗi khi lưu sản phẩm: $e'); // Log lỗi chi tiết
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
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
    _compareAtPriceController.clear(); // Clear controller mới
    _skuController.clear();            // Clear controller mới
    _quantityController.clear();       // Clear controller mới
    // _categoryController.clear(); // Không cần clear nếu dùng _selectedCategoryId
    // _imageController.clear(); // Không cần clear nếu không dùng
    setState(() {
      _imageFile = null;
      _selectedCategoryId = null; // Reset giá trị dropdown
      _selectedBrandId = null;    // Reset giá trị dropdown
      _isUploading = false;       // Reset trạng thái upload
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        backgroundColor: const Color(0xFFB7252A),
      ),
      body: FutureBuilder(
        future: MongoDatabase.db.collection('products').find().toList(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final productsData = snapshot.data ?? [];
          final products = productsData.map((json) => Product.fromJson(json)).toList();

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
                      product.image, // Sử dụng trường image từ model đã được cập nhật
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood),
                          ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          color: Color(0xFFB7252A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Danh mục: ${product.category}', // Hiển thị category string
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (product.quantity > 0) // Hiển thị số lượng nếu có
                        Text(
                          'Số lượng: ${product.quantity}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      if (product.compareAtPrice != null) // Hiển thị giá so sánh nếu có
                        Text(
                          'Giá gốc: ${product.compareAtPrice?.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (product.sku != null && product.sku!.isNotEmpty) // Hiển thị SKU nếu có
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showProductForm(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text('Bạn có chắc muốn xóa món này?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await MongoDatabase.db
                                  .collection('products')
                                  .remove({'_id': product.id});
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa món!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi xóa: $e'),
                                    backgroundColor: Colors.red,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFB7252A),
      ),
    );
  }
}