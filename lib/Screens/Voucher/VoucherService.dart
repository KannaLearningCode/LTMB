import 'package:kfc_seller/Models/Coupon.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CouponService {
  static const String _dbUrl = MONGO_CONN_URL;
  static const String _collectionName = 'coupons';

  static Future<List<Coupon>> fetchCoupons() async {
    final db = await Db.create(_dbUrl);
    await db.open();
    final collection = db.collection(_collectionName);

    final result = await collection.find().toList();
    await db.close();

    return result.map((e) => Coupon.fromJson(e)).toList();
  }

  static Future<void> addCoupon(Coupon coupon) async {
    final db = await Db.create(_dbUrl);
    await db.open();
    final collection = db.collection(_collectionName);

    await collection.insertOne(coupon.toJson());
    await db.close();
  }
}
