import 'dart:developer';

import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:kfc_seller/constants.dart';

class MongoDatabase {
  static var db, userCollection, orderCollection;

  static connect() async {
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    inspect(db);
    userCollection = db.collection(USER_COLLECTION);
    orderCollection = db.collection(ORDER_COLLECTION);
    // Tạo tài khoản admin mặc định nếu chưa có
    await createDefaultAdmin();
    return db;
  }

  static Future<bool> insert(Mongodbmodel data) async {
    try {
      var result = await userCollection.insertOne(data.toJson());
      if (result.isSuccess) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Hàm tạo tài khoản admin mặc định
  static Future<void> createDefaultAdmin() async {
    try {
      // Kiểm tra xem đã có tài khoản admin chưa
      var adminExists = await userCollection.findOne({"Role": "admin"});
      if (adminExists == null) {
        // Tạo tài khoản admin mặc định
        final adminUser = Mongodbmodel(
          id: ObjectId().toHexString(),
          name: "Admin",
          email: "admin@kfc.com",
          password: "Admin@123",
          rePassword: "Admin@123",
          phone: "0000000000",
          role: "admin"
        );
        
        await insert(adminUser);
        print("Đã tạo tài khoản admin mặc định");
      }
    } catch (e) {
      print("Lỗi khi tạo tài khoản admin: $e");
    }
  }
}