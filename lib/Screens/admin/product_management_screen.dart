import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:kfc_seller/DbHelper/mongdb.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    super.dispose();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Danh mục'),
              ),
              TextField(
                controller: _imageController,
                decoration: InputDecoration(labelText: 'Link ảnh'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear form và đóng dialog
              _clearForm();
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newProduct = Product(
                  id: product?.id ?? M.ObjectId(),
                  name: _nameController.text,
                  description: _descriptionController.text,
                  price: double.parse(_priceController.text),
                  category: _categoryController.text,
                  image: _imageController.text,
                  isAvailable: true,
                  createdAt: product?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (product == null) {
                  // Thêm mới
                  await MongoDatabase.db
                      .collection('products')
                      .insert(newProduct.toJson());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thêm món thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Cập nhật
                  await MongoDatabase.db.collection('products').update(
                    {'_id': product.id},
                    newProduct.toJson(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cập nhật món thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                // Clear form và đóng dialog
                _clearForm();
                Navigator.pop(context);
                
                // Refresh danh sách
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
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
    _imageController.clear();
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