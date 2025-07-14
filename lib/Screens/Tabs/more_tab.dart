// lib/Screens/Tabs/more_tab_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Screens/More/order_history_page.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class MoreTabRedesigned extends StatefulWidget {
  final Mongodbmodel currentUser;
  const MoreTabRedesigned({super.key, required this.currentUser});

  @override
  State<MoreTabRedesigned> createState() => _MoreTabRedesignedState();
}

class _MoreTabRedesignedState extends State<MoreTabRedesigned> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildUserSection(),
            const SizedBox(height: 20),
            _buildMenuItems(context),
            const SizedBox(height: 20),
            _buildAppInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào mừng!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khám phá thêm nhiều tính năng',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.history,
        'title': 'Lịch sử đơn hàng',
        'subtitle': 'Xem các đơn hàng đã đặt',
        'color': Colors.blue,
      },
      {
        'icon': Icons.favorite,
        'title': 'Món ăn yêu thích',
        'subtitle': 'Danh sách các món đã lưu',
        'color': Colors.red,
      },
      {
        'icon': Icons.location_on,
        'title': 'Địa chỉ giao hàng',
        'subtitle': 'Quản lý địa chỉ của bạn',
        'color': Colors.green,
      },
      {
        'icon': Icons.payment,
        'title': 'Phương thức thanh toán',
        'subtitle': 'Thêm và quản lý thẻ',
        'color': Colors.orange,
      },
      {
        'icon': Icons.local_offer,
        'title': 'Khuyến mãi & Voucher',
        'subtitle': 'Xem các ưu đãi hiện có',
        'color': Colors.purple,
      },
      {
        'icon': Icons.notifications,
        'title': 'Thông báo',
        'subtitle': 'Cài đặt thông báo',
        'color': Colors.teal,
      },
      {
        'icon': Icons.help,
        'title': 'Hỗ trợ',
        'subtitle': 'Liên hệ với chúng tôi',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.settings,
        'title': 'Cài đặt',
        'subtitle': 'Tùy chỉnh ứng dụng',
        'color': Colors.grey,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: menuItems.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade200,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
                size: 24,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              item['subtitle'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _handleMenuTap(context, item['title'] as String);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo1.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'CKICKY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gà Nóng Giòn – Bán Linh Hoạt – Ckicky Đồng Hành',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Phiên bản 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String title) {
    switch (title) {
      case 'Lịch sử đơn hàng':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderHistoryPage(
              userId: mongo.ObjectId.parse(widget.currentUser.id),
            ),
          ),
        ).then((_) {
          // Refresh lại UI nếu cần
          setState(() {});
        });
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tính năng "$title" đang được phát triển'),
            backgroundColor: AppColors.info,
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
