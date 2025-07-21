import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class OrderService {
  static Future<void> insertOrder(Order order) async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();

    final ordersCollection = db.collection(ORDER_COLLECTION); // Sử dụng tên từ constants
    await ordersCollection.insertOne(order.toJson());

    await db.close();
  }

  static Future<List<Order>> getAllOrders() async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();
    final ordersCollection = db.collection(ORDER_COLLECTION);
    final orderMaps = await ordersCollection.find().toList();
    await db.close();

    return orderMaps.map((e) => Order.fromJson(e)).toList();
  }

  static Future<Mongodbmodel?> getUserById(String userId) async {
    final db = await Db.create(MONGO_CONN_URL);
    await db.open();

    final userCollection = db.collection(USER_COLLECTION);
    final userMap = await userCollection.findOne({'_id': userId});
    
    await db.close();

    if (userMap != null) {
      return Mongodbmodel.fromJson(userMap);
    }
    return null;
  }

  static Future<void> updateOrderStatus(mongo.ObjectId orderId, String newStatus) async {
  try {
    final db = await MongoDatabase.connect();
    if (db == null) {
      print('❌ Không thể kết nối MongoDB');
      return;
    }

    final collection = db.collection('orders');

    await collection.updateOne(
      mongo.where.eq('_id', orderId),
      mongo.modify.set('status', newStatus).set('updatedAt', DateTime.now().toIso8601String()),
    );
  } catch (e) {
    print('❌ Lỗi khi cập nhật trạng thái đơn hàng: $e');
  }
}

static Future<List<Order>> getOrdersByUserId(mongo.ObjectId userId) async {
  final db = await Db.create(MONGO_CONN_URL);
  await db.open();

  final ordersCollection = db.collection(ORDER_COLLECTION);
  final orderMaps = await ordersCollection.find({'userId': userId}).toList();

  await db.close();

  return orderMaps.map((e) => Order.fromJson(e)).toList();
}


}
