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

  String? userName;
  String? userAvatar;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] as ObjectId,
      userId: json['userId'] as ObjectId,
      productId: json['productId'] as ObjectId,
      rating: json['rating'] is int ? json['rating'] : int.parse(json['rating'].toString()),
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt']
          : DateTime.parse(json['updatedAt']),
      userName: json['userName'] as String?,       // thêm dòng này
      userAvatar: json['userAvatar'] as String?,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
    };
  }
} 