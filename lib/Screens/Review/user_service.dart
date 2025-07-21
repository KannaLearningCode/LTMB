import 'package:kfc_seller/DbHelper/mongdb.dart'; // Đảm bảo bạn có kết nối Mongo
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class UserService {
  static final _userCollection = MongoDatabase.db.collection('users'); // hoặc 'accounts', tuỳ tên của bạn

  static Future<Mongodbmodel?> getUserById(mongo.ObjectId userId) async {
    final data = await _userCollection.findOne({'_id': userId});
    if (data != null) {
      return Mongodbmodel.fromJson(data);
    }
    return null;
  }
}
