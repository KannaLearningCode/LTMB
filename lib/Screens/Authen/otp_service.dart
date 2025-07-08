// lib/services/otp_service.dart
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:kfc_seller/constants.dart';

class OTPService {
  static Future<bool> saveOTPToDatabase(String email, String otp) async {
    try {
      final db = await M.Db.create(MONGO_CONN_URL);
      await db.open();
      final userCollection = db.collection(USER_COLLECTION);
      
      final expiryTime = DateTime.now().add(Duration(minutes: 10));
      
      await userCollection.updateOne(
        M.where.eq('Email', email),
        M.modify
            .set('resetToken', otp)
            .set('resetTokenExpiry', expiryTime.toIso8601String()),
      );
      
      await db.close();
      return true;
    } catch (e) {
      print('Error saving OTP: $e');
      return false;
    }
  }
  
  static Future<bool> verifyOTP(String email, String otp) async {
    try {
      final db = await M.Db.create(MONGO_CONN_URL);
      await db.open();
      final userCollection = db.collection(USER_COLLECTION);
      
      final user = await userCollection.findOne({
        'Email': email,
        'resetToken': otp,
      });
      
      if (user == null) {
        await db.close();
        return false;
      }
      
      // Kiểm tra thời hạn
      final expiryTimeStr = user['resetTokenExpiry'];
      if (expiryTimeStr != null) {
        final expiryTime = DateTime.parse(expiryTimeStr);
        if (DateTime.now().isAfter(expiryTime)) {
          await db.close();
          return false;
        }
      }
      
      await db.close();
      return true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }
  
  static Future<void> clearOTP(String email) async {
    try {
      final db = await M.Db.create(MONGO_CONN_URL);
      await db.open();
      final userCollection = db.collection(USER_COLLECTION);
      
      await userCollection.updateOne(
        M.where.eq('Email', email),
        M.modify
            .unset('resetToken')
            .unset('resetTokenExpiry'),
      );
      
      await db.close();
    } catch (e) {
      print('Error clearing OTP: $e');
    }
  }
}
