import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Theme/colors.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCategoryForm({Map<String, dynamic>? category}) {
    if (category != null) {
      _nameController.text = category['name'];
      _descriptionController.text = category['description'] ?? '';
    } else {
      _nameController.clear();
      _descriptionController.clear();
    }

    final currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          category == null ? 'Thêm danh mục mới' : 'Sửa danh mục',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên danh mục',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                maxLines: 2,
              ),
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
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng nhập tên danh mục'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              try {
                final categoryData = {
                  'name': _nameController.text,
                  'description': _descriptionController.text,
                  'updatedAt': DateTime.now(),
                };

                if (category == null) {
                  // Thêm mới
                  categoryData['_id'] = M.ObjectId();
                  categoryData['createdAt'] = DateTime.now();
                  await MongoDatabase.db.collection('categories').insert(categoryData);
                  
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Thêm danh mục thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  // Cập nhật
                  await MongoDatabase.db.collection('categories').update(
                    M.where.id(category['_id']),
                    categoryData,
                  );
                  
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Cập nhật danh mục thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }

                Navigator.pop(dialogContext);
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              category == null ? 'Thêm' : 'Cập nhật',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý danh mục',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: Container(
        color: AppColors.background,
        child: FutureBuilder(
          future: MongoDatabase.db.collection('categories').find().toList(),
          builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  style: TextStyle(color: AppColors.error),
                ),
              );
            }

            final categories = snapshot.data ?? [];

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.surface,
                  child: ListTile(
                    title: Text(
                      category['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      category['description'] ?? '',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          color: AppColors.primary,
                          onPressed: () => _showCategoryForm(category: category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: AppColors.error,
                          onPressed: () async {
                            final confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Xác nhận xóa',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                                content: Text(
                                  'Bạn có chắc muốn xóa danh mục này?',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Hủy',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
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
                                await MongoDatabase.db
                                    .collection('categories')
                                    .remove(M.where.id(category['_id']));
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Xóa danh mục thành công!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                
                                setState(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: AppColors.error,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(),
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.add,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}
