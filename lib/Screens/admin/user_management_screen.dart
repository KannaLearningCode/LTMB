import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await MongoDatabase.userCollection.find().toList();
      setState(() {
        _allUsers = users;
        _filteredUsers = List.from(_allUsers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final username = user['Username']?.toString().toLowerCase() ?? '';
        final email = user['Email']?.toString().toLowerCase() ?? '';
        final phone = user['Phone']?.toString().toLowerCase() ?? '';
        final role = user['Role']?.toString().toLowerCase() ?? '';
        
        return username.contains(query) || 
               email.contains(query) || 
               phone.contains(query) ||
               role.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFB7252A), // Màu đỏ KFC
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB7252A)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFB7252A)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Không có người dùng nào'
                                  : 'Không tìm thấy kết quả phù hợp',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterUsers();
                                },
                                child: const Text(
                                  'Xóa bộ lọc',
                                  style: TextStyle(color: Color(0xFFB7252A)),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 2,
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user['Role'] == 'admin'
                                    ? const Color(0xFFB7252A).withOpacity(0.2)
                                    : Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: user['Role'] == 'admin'
                                      ? const Color(0xFFB7252A)
                                      : Colors.grey[600],
                                ),
                              ),
                              title: Text(
                                user['Username'] ?? 'Không có tên',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['Email'] ?? 'Không có email'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        user['Phone'] ?? 'Chưa cập nhật',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      user['Role'] == 'admin' ? 'ADMIN' : 'USER',
                                      style: TextStyle(
                                        color: user['Role'] == 'admin'
                                            ? Colors.white
                                            : const Color(0xFFB7252A),
                                      ),
                                    ),
                                    backgroundColor: user['Role'] == 'admin'
                                        ? const Color(0xFFB7252A)
                                        : const Color(0xFFB7252A).withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: user['Role'] != 'admin'
                                  ? PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      color: Colors.white,
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'make_admin',
                                          child: ListTile(
                                            leading: Icon(Icons.admin_panel_settings,
                                                color: Color(0xFFB7252A)),
                                            title: Text('Đặt làm admin'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('Xóa người dùng'),
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'make_admin') {
                                          _confirmMakeAdmin(user);
                                        } else if (value == 'delete') {
                                          _confirmDeleteUser(user);
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMakeAdmin(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Bạn có chắc muốn đặt "${user['Username'] ?? 'người dùng này'}" làm admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý', style: TextStyle(color: Color(0xFFB7252A))),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã đặt ${user['Username']} làm admin!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa người dùng "${user['Username'] ?? 'này'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MongoDatabase.userCollection.remove({'_id': user['_id']});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa ${user['Username']}!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}