  import 'package:flutter/material.dart';
  import 'package:kfc_seller/Models/product.dart';
  import 'package:kfc_seller/DbHelper/mongdb.dart';
  import 'package:kfc_seller/Screens/Menu/detail_product_screen.dart';
  import 'package:mongo_dart/mongo_dart.dart' as mongo;
  import 'package:intl/intl.dart';
  import 'package:kfc_seller/Models/Mongdbmodel.dart';

  class MenuTab extends StatefulWidget {
    final mongo.ObjectId userId;
    final Mongodbmodel user;
    const MenuTab({super.key, required this.userId, required this.user});

    @override
    State<MenuTab> createState() => _MenuTabState();
  }

  class _MenuTabState extends State<MenuTab> {
    late Future<List<Product>> _productsFuture;
    List<Product> allProducts = [];
    List<String> categories = [];
    String selectedCategory = 'Tất cả';

    @override
    void initState() {
      super.initState();
      _productsFuture = _fetchProducts();
    }

    Future<List<Product>> _fetchProducts() async {
      final productData = await MongoDatabase.db.collection('products').find().toList();
      final products = productData.map<Product>((json) => Product.fromJson(json)).toList();

      // Lấy danh sách category duy nhất
      final uniqueCategories = products.map((p) => p.category).toSet().toList();
      setState(() {
        allProducts = products;
        categories = ['Tất cả', ...uniqueCategories];
      });

      return products;
    }

    List<Product> get filteredProducts {
      if (selectedCategory == 'Tất cả') return allProducts;
      return allProducts.where((p) => p.category == selectedCategory).toList();
    }

    @override
    Widget build(BuildContext context) {
      final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
      return Scaffold(
        backgroundColor: const Color.fromRGBO(102, 187, 106, 1),
        body: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            if (allProducts.isEmpty) {
              return const Center(child: Text('Không có sản phẩm nào.'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Thanh trượt category ---
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green[800] : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    },
                  ),
                ),

                // --- Danh sách sản phẩm ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailProductPage(product: product, userId: widget.userId, user: widget.user,),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fastfood, size: 32),
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyFormatter.format(product.price),
                                  style: const TextStyle(
                                    color: Color(0xFFB7252A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  product.category,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã thêm ${product.name}')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                'Thêm',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }
