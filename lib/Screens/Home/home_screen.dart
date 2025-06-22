import 'package:flutter/material.dart';
import 'package:kfc_seller/Screens/Authen/login_screen.dart';
import '../Tabs/home_tab.dart';
import '../Menu/menu_tab.dart';
import '../Tabs/cart_tab.dart';
import '../Tabs/more_tab.dart';
import 'profile_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart'; // Thêm dòng này

class HomeScreen extends StatefulWidget {
  final int index;
  final mongo.ObjectId userId;
  final Mongodbmodel user;
  const HomeScreen({
    Key? key,
    this.index = 0,
    required this.userId, required this.user,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm đổi tab (gọi từ CartTab khi người dùng muốn "Mua hàng ngay")
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Tạo danh sách tab (gọi trong build để có thể truyền callback)
  List<Widget> get _pages => [
        const HomeTab(),
        MenuTab(userId: widget.userId,user: widget.user,),
        CartTab(
          user: widget.user,
          userId: widget.userId,
          onGoToMenuTab: () => _onItemTapped(1), // 👈 index của Menu tab
        ),
        const MoreTab(),
      ];

  Future<bool> _onWillPop() async {
    if (currentBackPressTime == null ||
        DateTime.now().difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();

      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thoát ứng dụng'),
          content: const Text('Bạn có muốn thoát ứng dụng không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Có', style: TextStyle(color: Color(0xFFB7252A))),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 30,
        bottom: 15,
      ),
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ckicky',
                style: TextStyle(
                  color: Color(0xFFB7252A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  } else if (value == 'logout') {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFFB7252A)),
                        SizedBox(width: 10),
                        Text('Trang cá nhân'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.grey),
                        SizedBox(width: 10),
                        Text('Đăng xuất'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: const Color(0xFFB7252A),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFFB7252A), size: 24),
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
        backgroundColor: Colors.green,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
          ],
          body: Container(
            decoration: const BoxDecoration(color: Colors.green),
            child: _pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Thực đơn'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Giỏ hàng'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Thêm'),
            ],
            backgroundColor: Colors.green,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.yellowAccent,
            unselectedItemColor: Colors.white,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
