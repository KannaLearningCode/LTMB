import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHash {
  // Hàm mã hóa mật khẩu sử dụng SHA-256
  static String hashPassword(String password) {
    // Chuyển đổi mật khẩu thành bytes
    var bytes = utf8.encode(password);
    // Tạo hash từ bytes sử dụng SHA-256
    var digest = sha256.convert(bytes);
    // Trả về chuỗi hash dạng hex
    return digest.toString();
  }

  // Hàm kiểm tra mật khẩu có khớp với hash không
  static bool verifyPassword(String password, String hashedPassword) {
    var hashedInput = hashPassword(password);
    return hashedInput == hashedPassword;
  }
} 