// lib/Services/review_service.dart
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:kfc_seller/Models/review.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';

class ReviewService {
  static final _reviews = MongoDatabase.db.collection('reviews');
  static final _users = MongoDatabase.db.collection('users');
  
  static Future<List<Review>> getReviewsByProductId(ObjectId productId) async {
  final result = await _reviews.find(where.eq('productId', productId)).toList();
  return result.map<Review>((e) => Review.fromJson(e)).toList();
}


  static Future<void> submitReview(Review review) async {
    await _reviews.insert(review.toJson());
  }

static Future<List<Map<String, dynamic>>> getReviewsWithUser(ObjectId productId) async {
    final reviewList = await _reviews.find(where.eq('productId', productId)).toList();

    List<Map<String, dynamic>> result = [];

    for (var reviewMap in reviewList) {
      final review = Review.fromJson(reviewMap);
      final userId = review.userId;

      Mongodbmodel? user;

      if (userId != null) {
        final userMap = await _users.findOne(where.eq('_id', userId));
        if (userMap != null) {
          user = Mongodbmodel.fromJson(userMap);
        }
      }

      result.add({
        'review': review,
        'user': user,
      });
    }

    return result;
  }
  
}
