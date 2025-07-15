import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/product.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';

class ProductService {
  static final _products = MongoDatabase.db.collection('products');

  static Future<List<Product>> getProductsByIds(List<mongo.ObjectId> ids) async {
  if (ids.isEmpty) {
    print("Không có productId nào được yêu thích.");
    return [];
  }

  print("Đang tìm product có _id: $ids");

  final results = await _products.find({
    '_id': {r'$in': ids}
  }).toList();

  print("Kết quả tìm được: $results");

  return results.map<Product>((e) => Product.fromJson(e)).toList(); // ✅ ép kiểu rõ ràng
}


}
