import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;

  // Danh sách các widget tương ứng với từng tab
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Trang chủ', style: TextStyle(fontSize: 24))),
    Center(child: Text('Thực đơn', style: TextStyle(fontSize: 24))),
    Center(child: Text('Giỏ hàng', style: TextStyle(fontSize: 24))),
    Center(child: Text('Thêm', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (currentBackPressTime == null || 
        DateTime.now().difference(currentBackPressTime!) > Duration(seconds: 2)) {
      // Lần nhấn back đầu tiên hoặc đã quá 2 giây từ lần nhấn trước
      currentBackPressTime = DateTime.now();
      
      // Hiển thị dialog xác nhận
      bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thoát ứng dụng'),
          content: Text('Bạn có muốn thoát ứng dụng không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Không',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Có',
                style: TextStyle(color: Color(0xFFB7252A)),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    // Nhấn back lần thứ 2 trong vòng 2 giây
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'KFC',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFFB7252A),
          automaticallyImplyLeading: false,
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
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
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
} 