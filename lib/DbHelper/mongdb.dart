import 'dart:developer';

import 'package:kfc_seller/Mongdbmodel.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:kfc_seller/constaint.dart';

class MongoDatabase {
  static var db, userCollection;

  static connect() async {
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    inspect(db);
    userCollection = db.collection(USER_COLLECTION);
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
}