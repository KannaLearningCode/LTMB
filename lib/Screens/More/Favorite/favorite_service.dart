import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class FavoriteService {
  static final _favorites = MongoDatabase.db.collection('favorites');

  static Future<void> addFavorite(ObjectId userId, ObjectId productId) async {
    final exists = await _favorites.findOne({
      'userId': userId,
      'productId': productId,
    });

    if (exists == null) {
      await _favorites.insertOne({
        'userId': userId,
        'productId': productId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> removeFavorite(ObjectId userId, ObjectId productId) async {
    await _favorites.deleteOne({
      'userId': userId,
      'productId': productId,
    });
  }

  static Future<bool> isFavorite(ObjectId userId, ObjectId productId) async {
    final doc = await _favorites.findOne({
      'userId': userId,
      'productId': productId,
    });
    return doc != null;
  }

static Future<List<mongo.ObjectId>> getUserFavoriteProductIds(mongo.ObjectId userId) async {
  final list = await _favorites.find({'userId': userId}).toList();
  print('Favorites found for user $userId: $list');

  return list
      .map<mongo.ObjectId>((e) =>
          e['productId'] is mongo.ObjectId
              ? e['productId'] as mongo.ObjectId
              : mongo.ObjectId.parse(e['productId'].toString()))
      .toList();
}



}
