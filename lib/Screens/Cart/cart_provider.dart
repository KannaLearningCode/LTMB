import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  late ObjectId _userId; // ✅ Thêm userId riêng

  List<CartItem> get items => _items;

  // ✅ Gọi từ ngoài (CartTab, DetailProductPage, v.v.)
  void setUser(ObjectId userId) {
    _userId = userId;
  }

  void addToCart(CartItem item) {
    final index = _items.indexWhere((e) => e.productId == item.productId);
    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  Future<void> removeItem(ObjectId productId) async {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
    await _saveCartToDb(); // ✅ Cập nhật DB
  }

  Future<void> increaseQuantity(ObjectId productId) async {
  final index = _items.indexWhere((item) => item.productId == productId);
  if (index != -1) {
    _items[index].quantity++;
    await _saveCartToDb(); // gọi ngay sau khi cập nhật
    notifyListeners();
  }
}

Future<void> decreaseQuantity(ObjectId productId) async {
  final index = _items.indexWhere((item) => item.productId == productId);
  if (index != -1) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    await _saveCartToDb(); // gọi sau khi thay đổi
    notifyListeners();
  }
}


  // ✅ Sửa: dùng _userId thay vì item.userId
  Future<void> _saveCartToDb() async {
    final existingCart = await fetchCartForUser(_userId);

    final cart = Cart(
      id: existingCart?.id ?? ObjectId(),
      userId: _userId,
      items: _items,
      createdAt: existingCart?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await updateCartInDB(cart);
  }

  Future<Cart?> fetchCartForUser(ObjectId userId) async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();
    final collection = db.collection('carts');

    final data = await collection.findOne(where.eq('userId', userId));
    await db.close();

    if (data != null) {
      return Cart.fromJson(data);
    }
    return null;
  }

  Future<void> updateCartInDB(Cart cart) async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();
    final collection = db.collection('carts');

    await collection.updateOne(
      where.eq('userId', cart.userId),
      modify
          .set('items', cart.items.map((e) => e.toJson()).toList())
          .set('updatedAt', DateTime.now().toIso8601String()),
      upsert: true,
    );

    await db.close();
  }

  Future<void> loadCart(ObjectId userId) async {
    setUser(userId); // ✅ Ghi nhớ userId khi load
    final cart = await fetchCartForUser(userId);
    _items.clear();
    if (cart != null) {
      _items.addAll(cart.items);
    }
    notifyListeners();
  }
  Future<void> clearCartFromDb() async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();

    final collection = db.collection('carts');
    await collection.deleteOne(where.eq('userId', _userId)); // Xoá giỏ hàng theo user

    await db.close();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await clearCartFromDb(); // ✅ Gọi xoá DB
  }

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);
}
