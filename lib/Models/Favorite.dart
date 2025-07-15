import 'package:mongo_dart/mongo_dart.dart';

class Favorite {
  final ObjectId id;
  final ObjectId userId;
  final ObjectId productId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['_id'] as ObjectId,
      userId: json['userId'] as ObjectId,
      productId: json['productId'] as ObjectId,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
