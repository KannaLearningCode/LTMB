// lib/Services/review_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:kfc_seller/Models/review.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';

class ReviewService {
  static final _reviews = MongoDatabase.db.collection('reviews');

  static Future<List<Review>> getReviewsByProductId(ObjectId productId) async {
  final result = await _reviews.find(where.eq('productId', productId)).toList();
  return result.map<Review>((e) => Review.fromJson(e)).toList();
}


  static Future<void> submitReview(Review review) async {
    await _reviews.insert(review.toJson());
  }
}
