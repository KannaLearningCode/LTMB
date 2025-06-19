import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.person_outline,
      'title': 'Thông tin cá nhân',
      'subtitle': 'Tên, số điện thoại, địa chỉ...',
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'title': 'Đơn hàng của tôi',
      'subtitle': 'Xem lịch sử đơn hàng',
    },
    {
      'icon': Icons.favorite_border,
      'title': 'Món ăn yêu thích',
      'subtitle': 'Các món ăn đã lưu',
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Địa chỉ đã lưu',
      'subtitle': 'Quản lý địa chỉ giao hàng',
    },
    {
      'icon': Icons.payment_outlined,
      'title': 'Phương thức thanh toán',
      'subtitle': 'Thêm và quản lý phương thức thanh toán',
    },
    {
      'icon': Icons.settings_outlined,
      'title': 'Cài đặt',
      'subtitle': 'Thông báo, bảo mật, ngôn ngữ',
    },
  ];

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 15,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        height: 60,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KFC',
                style: TextStyle(
                  color: Color(0xFFB7252A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(
                    color: Color(0xFFB7252A),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: Color(0xFFB7252A),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              image: DecorationImage(
                image: AssetImage('assets/images/avatar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyễn Văn A',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '0123456789',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFB7252A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item['icon'],
            color: Color(0xFFB7252A),
            size: 24,
          ),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item['subtitle'],
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: () {
          // TODO: Xử lý khi nhấn vào từng mục
          print('Tapped on ${item['title']}');
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Thực đơn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Giỏ hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Thêm',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFFB7252A),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index != _selectedIndex) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB7252A),
      body: Column(
        children: [
          _buildHeader(),
          _buildProfileInfo(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFB7252A),
              ),
              child: Center(
                child: Text(
                  'Nội dung trang profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }
} 