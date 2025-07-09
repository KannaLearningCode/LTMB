
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart' as mongo;

Mongodbmodel mongodbmodelFromJson(String str) => Mongodbmodel.fromJson(json.decode(str));

String mongodbmodelToJson(Mongodbmodel data) => json.encode(data.toJson());

class Mongodbmodel {
   String id;
  String name;
  String email;
  String? password;
  String? rePassword;
  String role;
  String phone;
  String? fullName;
  String? address;
  DateTime? birthday;
  String? bio;
  String? avatarUrl;
  bool isActive;
  DateTime? lastLoginAt;
  DateTime createdAt;
  DateTime updatedAt;
  String? provider;

  Mongodbmodel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.rePassword,
    required this.role,
    required this.phone,
    this.fullName,
    this.address,
    this.birthday,
    this.bio,
    this.avatarUrl,
    this.isActive = true,
    this.lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.provider,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Mongodbmodel.fromJson(Map<String, dynamic> json) => Mongodbmodel(
        id: json["_id"] is mongo.ObjectId ? (json["_id"] as mongo.ObjectId).toHexString() : json["_id"].toString(),
        name: json["Username"] ?? "",
        email: json["Email"] ?? "",
        password: json["Password"] ?? "",
        rePassword: json["RePassword"] ?? "",
        role: json["Role"] ?? "user",
        phone: json["Phone"] ?? "",
        fullName: json["FullName"],
        address: json["Address"],
        birthday:
            json["Birthday"] != null ? DateTime.parse(json["Birthday"]) : null,
        bio: json["Bio"],
        avatarUrl: json["AvatarUrl"],
        isActive: json["IsActive"] ?? true,
        lastLoginAt: json["LastLoginAt"] != null
            ? DateTime.parse(json["LastLoginAt"])
            : null,
        createdAt: json["CreatedAt"] != null
            ? DateTime.parse(json["CreatedAt"])
            : DateTime.now(),
        updatedAt: json["UpdatedAt"] != null
            ? DateTime.parse(json["UpdatedAt"])
            : DateTime.now(),
        provider: json["Provider"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "Username": name,
        "Email": email,
        "Password": password,
        "RePassword": rePassword,
        "Role": role,
        "Phone": phone,
        "FullName": fullName,
        "Address": address,
        "Birthday": birthday?.toIso8601String(),
        "Bio": bio,
        "AvatarUrl": avatarUrl,
        "IsActive": isActive,
        "LastLoginAt": lastLoginAt?.toIso8601String(),
        "CreatedAt": createdAt.toIso8601String(),
        "UpdatedAt": updatedAt.toIso8601String(),
        "Provider": provider,
      };
}