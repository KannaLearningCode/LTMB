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
  final _categoryController = TextEditingController();
  final _imageController = TextEditingController();

  // Thêm biến để lưu file ảnh đã chọn
  File? _imageFile;
  // Thêm biến để hiển thị trạng thái đang tải ảnh  
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<String> _uploadImage(File image) async {
    // Thay các giá trị sau bằng thông tin của bạn
    final cloudinary = CloudinaryPublic('dwdpxxkgs', 'KFC_Sellers');
    
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải ảnh lên thất bại: ${e.toString()}'), backgroundColor: Colors.red),
      );
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
    if (product != null) {
      // Nếu là sửa, điền thông tin sẵn có
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _categoryController.text = product.category;
      _imageController.text = product.image;
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
                decoration: InputDecoration(labelText: 'Tên món'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MongoDatabase.db.collection('categories').find().toList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Lỗi: ${snapshot.error}');
                  }

                  final categories = snapshot.data ?? [];
                  
                  return DropdownButtonFormField<String>(
                    value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                    decoration: InputDecoration(labelText: 'Danh mục'),
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String,
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _categoryController.text = value;
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Thêm phần chọn và hiển thị ảnh
              _imageFile == null
                  ? (product?.image != null && product!.image.isNotEmpty
                      ? Image.network(product.image, height: 150)
                      : Container())
                  : Image.file(_imageFile!, height: 150),
              
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Chọn ảnh từ thư viện'),
              ),

              if (_isUploading) CircularProgressIndicator(),
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
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Nếu đang upload thì không cho nhấn
              if (_isUploading) return;

              // Kiểm tra các trường nhập liệu
              if (_nameController.text.isEmpty || _priceController.text.isEmpty || _categoryController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Vui lòng nhập đủ thông tin bắt buộc.'), backgroundColor: Colors.orange),
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
                      SnackBar(content: Text('Vui lòng chọn ảnh cho sản phẩm.'), backgroundColor: Colors.orange),
                  );
                  return;
              }

              try {
                final newProduct = Product(
                  id: product?.id ?? M.ObjectId(),
                  name: _nameController.text,
                  description: _descriptionController.text,
                  price: double.parse(_priceController.text),
                  category: _categoryController.text,
                  image: imageUrl,
                  isAvailable: true,
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (product == null) {
                  // Thêm mới
                  await MongoDatabase.db
                      .collection('products')
                      .insert(newProduct.toJson());
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Thêm món thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Cập nhật
                  await MongoDatabase.db.collection('products').update(
                    M.where.id(product.id),
                    newProduct.toJson(),
                  );
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Cập nhật món thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                // Clear form và đóng dialog
                _clearForm();
                Navigator.pop(dialogContext);
                
                // Refresh danh sách
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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
    _categoryController.clear();
    _imageController.clear(); // Dù không dùng nhưng cứ clear
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý sản phẩm'),
        backgroundColor: Color(0xFFB7252A),
      ),
      body: FutureBuilder(
        future: MongoDatabase.db.collection('products').find().toList(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = Product.fromJson(products[index]);
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(Icons.fastfood),
                          ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: TextStyle(
                          color: Color(0xFFB7252A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.category,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showProductForm(product: product),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Xác nhận xóa'),
                              content: Text('Bạn có chắc muốn xóa món này?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await MongoDatabase.db
                                  .collection('products')
                                  .remove({'_id': product.id});
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa món!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi khi xóa: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFB7252A),
      ),
    );
  }
}