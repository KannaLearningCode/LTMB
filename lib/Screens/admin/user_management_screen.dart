import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý người dùng',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: MongoDatabase.userCollection.find().toList(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['Role'] == 'admin' 
                        ? Colors.red[100] 
                        : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: user['Role'] == 'admin' 
                          ? Color(0xFFB7252A)
                          : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    user['Username'] ?? 'Không có tên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['Email'] ?? 'Không có email'),
                      Text(
                        'SĐT: ${user['Phone'] ?? 'Chưa cập nhật'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Vai trò: ${user['Role'] ?? 'user'}',
                        style: TextStyle(
                          color: user['Role'] == 'admin' 
                              ? Color(0xFFB7252A)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: user['Role'] != 'admin' 
                      ? PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'make_admin',
                              child: Text('Đặt làm admin'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa người dùng'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'make_admin') {
                              // Xác nhận đặt làm admin
                              final confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Xác nhận'),
                                  content: Text(
                                    'Bạn có chắc muốn đặt người dùng này làm admin?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => 
                                          Navigator.pop(context, false),
                                      child: Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => 
                                          Navigator.pop(context, true),
                                      child: Text('Đồng ý'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await MongoDatabase.userCollection.update(
                                    {'_id': user['_id']},
                                    {'\$set': {'Role': 'admin'}},
                                  );
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã đặt làm admin!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else if (value == 'delete') {
                              // Xác nhận xóa
                              final confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Xác nhận xóa'),
                                  content: Text(
                                    'Bạn có chắc muốn xóa người dùng này?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => 
                                          Navigator.pop(context, false),
                                      child: Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => 
                                          Navigator.pop(context, true),
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await MongoDatabase.userCollection
                                      .remove({'_id': user['_id']});
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã xóa người dùng!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 