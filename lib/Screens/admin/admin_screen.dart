import 'package:flutter/material.dart';
import 'package:kfc_seller/Screens/admin/product_management_screen.dart';
import 'package:kfc_seller/Screens/admin/user_management_screen.dart';
import 'package:kfc_seller/Screens/admin/category_management_screen.dart';
import 'package:kfc_seller/Screens/admin/order_management_screen.dart';
import 'package:kfc_seller/Screens/admin/voucher_management_screen.dart';
import 'package:kfc_seller/Screens/Authen/login_screen.dart';
import 'package:kfc_seller/Theme/colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // Hàm tạo item quản lý
  Widget _buildManagementItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, String title, IconData icon, Widget destination) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý CKICKY',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: AppColors.textOnPrimary,  
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreenRedesigned()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề chào mừng
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chọn mục quản lý bên dưới',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Grid các mục quản lý
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  // Quản lý người dùng
                  _buildAdminTile(
                    context,
                    'Quản lý người dùng',
                    Icons.people,
                    UserManagementScreen(),
                  ),
                  
                  // Quản lý sản phẩm
                  _buildAdminTile(
                    context,
                    'Quản lý sản phẩm',
                    Icons.fastfood,
                    ProductManagementScreen(),
                  ),
                  
                  // Quản lý danh mục
                  _buildAdminTile(
                    context,
                    'Quản lý danh mục',
                    Icons.category,
                    CategoryManagementScreen(),
                  ),
                  
                  // Quản lý đơn hàng
                  _buildAdminTile(
                    context,
                    'Quản lý đơn hàng',
                    Icons.shopping_cart,
                    OrderManagementScreen(),
                  ),

                  // Quản lý mã giảm giá
                  _buildAdminTile(
                    context,
                    'Quản lý mã giảm giá',
                    Icons.card_giftcard,
                    VoucherManagementScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}