// lib/Screens/Cart/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  late ObjectId _userId;
  bool _disposed = false; // ✅ Track dispose state

  List<CartItem> get items => _items;

  void setUser(ObjectId userId) {
    _userId = userId;
  }

  void addToCart(CartItem item) {
    if (_disposed) return; // ✅ Check disposed state
    
    final index = _items.indexWhere((e) => e.productId == item.productId);
    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }

    _safeNotifyListeners();
  }

  Future<void> removeItem(ObjectId productId) async {
    if (_disposed) return;
    
    _items.removeWhere((item) => item.productId == productId);
    _safeNotifyListeners();
    await _saveCartToDb();
  }

  Future<void> increaseQuantity(ObjectId productId) async {
    if (_disposed) return;
    
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index].quantity++;
      await _saveCartToDb();
      _safeNotifyListeners();
    }
  }

  Future<void> decreaseQuantity(ObjectId productId) async {
    if (_disposed) return;
    
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }

      await _saveCartToDb();
      _safeNotifyListeners();
    }
  }

  Future<void> _saveCartToDb() async {
    if (_disposed) return;
    
    try {
      final existingCart = await fetchCartForUser(_userId);
      final cart = Cart(
        id: existingCart?.id ?? ObjectId(),
        userId: _userId,
        items: _items,
        createdAt: existingCart?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateCartInDB(cart);
    } catch (e) {
      print('Error saving cart to DB: $e');
    }
  }

  Future<Cart?> fetchCartForUser(ObjectId userId) async {
    if (_disposed) return null;
    
    try {
      final db = await Db.create(MONGO_CONN_URL);
      await db.open();
      final collection = db.collection('carts');
      final data = await collection.findOne(where.eq('userId', userId));
      await db.close();
      if (data != null) {
        return Cart.fromJson(data);
      }
    } catch (e) {
      print('Error fetching cart: $e');
    }
    return null;
  }

  Future<void> updateCartInDB(Cart cart) async {
    if (_disposed) return;
    
    try {
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
    } catch (e) {
      print('Error updating cart in DB: $e');
    }
  }

  Future<void> loadCart(ObjectId userId) async {
    if (_disposed) return;
    
    setUser(userId);
    try {
      final cart = await fetchCartForUser(userId);
      _items.clear();
      if (cart != null) {
        _items.addAll(cart.items);
      }
      _safeNotifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> clearCartFromDb() async {
    if (_disposed) return;
    
    try {
      final db = await Db.create(MONGO_CONN_URL);
      await db.open();
      final collection = db.collection('carts');
      await collection.deleteOne(where.eq('userId', _userId));
      await db.close();
    } catch (e) {
      print('Error clearing cart from DB: $e');
    }
  }

  Future<void> clearCart() async {
    if (_disposed) return;
    
    _items.clear();
    _safeNotifyListeners();
    await clearCartFromDb();
  }

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  // ✅ Safe notify listeners - check disposed state
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true; // ✅ Mark as disposed
    super.dispose();
  }
}
