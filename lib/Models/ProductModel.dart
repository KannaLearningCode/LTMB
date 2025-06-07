import 'dart:convert';

ProductModel productModelFromJson(String str) => ProductModel.fromJson(json.decode(str));
String productModelToJson(ProductModel data) => json.encode(data.toJson());

class ProductModel {
    String id;
    String name;
    String description;
    double price;
    String imageUrl;
    String categoryId; // Để liên kết với Categories

    ProductModel({
        required this.id,
        required this.name,
        required this.description,
        required this.price,
        required this.imageUrl,
        required this.categoryId,
    });

    factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json["_id"],
        name: json["Name"],
        description: json["Description"],
        price: json["Price"].toDouble(),
        imageUrl: json["ImageUrl"],
        categoryId: json["CategoryId"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "Name": name,
        "Description": description,
        "Price": price,
        "ImageUrl": imageUrl,
        "CategoryId": categoryId,
    };
}