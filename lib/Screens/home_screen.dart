import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_tab.dart';
import 'menu_tab.dart';
import 'cart_tab.dart';
import 'more_tab.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Danh sách các widget tương ứng với từng tab
  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    MenuTab(),
    CartTab(),
    MoreTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(),
      ),
    );
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 30,
        bottom: 15,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal:0),
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
              GestureDetector(
                onTap: _navigateToProfile,
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color(0xFFB7252A),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 110.0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                ),
              ),
            ];
          },
          body: Container(
            decoration: BoxDecoration(
              color: Color(0xFFB7252A),
            ),
            child: _pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
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
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFFB7252A),
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
} 