import 'package:mongo_dart/mongo_dart.dart';
import 'constraints.dart';

class MongoDB {
  static late Db db;
  static late DbCollection usersCollection;
  static late DbCollection productsCollection;
  static late DbCollection categoriesCollection;
  static late DbCollection cartsCollection;
  static late DbCollection ordersCollection;
  static late DbCollection reviewsCollection;

  static connect() async {
    db = await Db.create('mongodb://localhost:27017/kfc_seller');
    await db.open();

    usersCollection = db.collection(Constraints.usersCollection);
    productsCollection = db.collection(Constraints.productsCollection);
    categoriesCollection = db.collection(Constraints.categoriesCollection);
    cartsCollection = db.collection(Constraints.cartsCollection);
    ordersCollection = db.collection(Constraints.ordersCollection);
    reviewsCollection = db.collection(Constraints.reviewsCollection);

    // Create indexes
    await _createIndexes();
  }

  static Future<void> _createIndexes() async {
    // Users collection indexes
    await usersCollection.createIndex(keys: {
      'email': 1,
    }, unique: true);

    // Products collection indexes
    await productsCollection.createIndex(keys: {
      'categoryId': 1,
    });

    // Carts collection indexes
    await cartsCollection.createIndex(keys: {
      'userId': 1,
    }, unique: true);

    // Orders collection indexes
    await ordersCollection.createIndex(keys: {
      'userId': 1,
    });
    await ordersCollection.createIndex(keys: {
      'status': 1,
    });

    // Reviews collection indexes
    await reviewsCollection.createIndex(keys: {
      'productId': 1,
    });
    await reviewsCollection.createIndex(keys: {
      'userId': 1,
    });
  }
} 