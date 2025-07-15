// lib/Screens/Favorite/favorite_page.dart
import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Screens/Menu/detail_product_screen.dart';
import 'package:kfc_seller/Screens/More/Favorite/favorite_service.dart';
import 'package:kfc_seller/Screens/More/Favorite/product_service.dart';
import 'package:kfc_seller/Theme/app_theme.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class FavoritePage extends StatefulWidget {
  final Mongodbmodel currentUser;
  const FavoritePage({super.key, required this.currentUser});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Product> favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final objectId = mongo.ObjectId.tryParse(widget.currentUser.id);
      if (objectId == null) {
        throw Exception("ID không hợp lệ: ${widget.currentUser.id}");
      }

      final productIds = await FavoriteService.getUserFavoriteProductIds(objectId);
      print("Danh sách productIds: $productIds");
      final products = await ProductService.getProductsByIds(productIds);
      print("Danh sách products lấy được: ${products.map((p) => p.name).toList()}");

      setState(() {
        favoriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi load favorites: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorite(Product product) async {
    final userId = mongo.ObjectId.parse(widget.currentUser.id);
    await FavoriteService.removeFavorite(userId, product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gỡ "${product.name}" khỏi yêu thích')),
    );
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Món ăn yêu thích"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteProducts.isEmpty
              ? const Center(child: Text("Bạn chưa có món ăn yêu thích nào"))
              : ListView.builder(
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) {
                    final product = favoriteProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.image),
                        ),
                        title: Text(product.name),
                        subtitle: Text("${product.price} VNĐ"),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromFavorite(product),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailProductPageRedesigned(
                                product: product,
                                userId: mongo.ObjectId.parse(widget.currentUser.id),
                                user: widget.currentUser,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
