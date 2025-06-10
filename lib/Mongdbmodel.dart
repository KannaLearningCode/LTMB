// To parse this JSON data, do
//
//     final mongodbmodel = mongodbmodelFromJson(jsonString);

import 'dart:convert';

Mongodbmodel mongodbmodelFromJson(String str) => Mongodbmodel.fromJson(json.decode(str));

String mongodbmodelToJson(Mongodbmodel data) => json.encode(data.toJson());

class Mongodbmodel {
    String id;
    String name;
    String email;
    String password;
    String rePassword;
    String role; // <--- THÊM DÒNG NÀY
    String phone; // Thêm trường phone

    Mongodbmodel({
        required this.id,
        required this.name,
        required this.email,
        required this.password,
        required this.rePassword,
        required this.role, // <--- THÊM DÒNG NÀY
        required this.phone, // Thêm vào constructor
    });

    factory Mongodbmodel.fromJson(Map<String, dynamic> json) => Mongodbmodel(
        id: json["_id"],
        name: json["Name"],
        email: json["Email"],
        password: json["Password"],
        rePassword: json["RePassword"],
        role: json["Role"], // <--- THÊM DÒNG NÀY
        phone: json["Phone"] ?? "", // Thêm vào fromJson với giá trị mặc định là chuỗi rỗng
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "Name": name,
        "Email": email,
        "Password": password,
        "RePassword": rePassword,
        "Role": role, // <--- THÊM DÒNG NÀY
        "Phone": phone, // Thêm vào toJson
    };
}