import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class OrderService {
  static Future<void> insertOrder(Order order) async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();

    final ordersCollection = db.collection(ORDER_COLLECTION); // Sử dụng tên từ constants
    await ordersCollection.insertOne(order.toJson());

    await db.close();
  }
}
