import 'package:mongo_dart/mongo_dart.dart';

class Review {
  final ObjectId id;
  final ObjectId userId;
  final ObjectId productId;
  final int rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'],
      userId: json['userId'],
      productId: json['productId'],
      rating: json['rating'],
      comment: json['comment'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 