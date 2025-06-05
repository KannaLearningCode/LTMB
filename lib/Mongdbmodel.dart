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

    Mongodbmodel({
        required this.id,
        required this.name,
        required this.email,
        required this.password,
        required this.rePassword,
    });

    factory Mongodbmodel.fromJson(Map<String, dynamic> json) => Mongodbmodel(
        id: json["_id"],
        name: json["Name"],
        email: json["Email"],
        password: json["Password"],
        rePassword: json["RePassword"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "Name": name,
        "Email": email,
        "Password": password,
        "RePassword": rePassword,
    };
}
