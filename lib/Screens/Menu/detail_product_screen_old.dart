import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Home/home_screen_old.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart'; // Thêm dòng này

class DetailProductPage extends StatefulWidget {
  final Product product;
  final mongo.ObjectId userId;
  final Mongodbmodel user;

  const DetailProductPage({super.key, required this.product, required this.userId, required this.user});

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  int quantity = 1;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Chuyển hướng về HomeScreen với tab tương ứng
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(index: index, userId: widget.userId, user: widget.user,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    final totalPrice = widget.product.price * quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: const TextStyle(color: Colors.white),
          ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.network(
                widget.product.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(height: 16),

            // Tên và giá
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.product.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                currencyFormatter.format(widget.product.price),
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
            ),
            const Divider(),

            // Mô tả
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mô tả sản phẩm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.product.description ?? 'Không có mô tả.'),
            ),

            const Divider(),

            // Thông tin thêm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(widget.product.category),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Tình trạng:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(widget.product.isAvailable ? 'Còn hàng' : 'Hết hàng'),
                ],
              ),
            ),
          ],
        ),
      ),

      // Nút thêm vào giỏ
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Số lượng + Tổng tiền
            Row(
              children: [
                const Text('Số lượng:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () {
                                setState(() {
                                  quantity--;
                                });
                              }
                            : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'Tổng: ${currencyFormatter.format(totalPrice)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nút thêm vào giỏ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
              onPressed: () async {
                // Lưu context sớm
                final messenger = ScaffoldMessenger.of(context);

                // Lấy CartProvider an toàn
                final cartProvider = Provider.of<CartProvider>(context, listen: false);

                // Tạo CartItem
                final newItem = CartItem(
                  productId: widget.product.id,
                  productName: widget.product.name,
                  productImage: widget.product.image,
                  description: widget.product.description,
                  price: widget.product.price,
                  quantity: quantity,
                  addedAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                // Thêm vào giỏ hàng trong memory
                cartProvider.addToCart(newItem);

                // Lấy cart hiện có
                final existingCart = await cartProvider.fetchCartForUser(widget.userId);

                // Cập nhật giỏ hàng vào DB
                await cartProvider.updateCartInDB(
                  Cart(
                    id: existingCart?.id ?? mongo.ObjectId(),
                    userId: widget.userId,
                    items: cartProvider.items,
                    createdAt: existingCart?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                // ✅ Hiển thị thông báo với context đã lưu
                messenger.showSnackBar(
                  SnackBar(content: Text('Đã thêm $quantity x ${widget.product.name} vào giỏ hàng')),
                );
              },
                icon: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                ),
                label: const Text(
                  'Thêm vào giỏ hàng',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),

      // Thanh điều hướng giống HomeScreen
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
        backgroundColor: Colors.green,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellowAccent,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

