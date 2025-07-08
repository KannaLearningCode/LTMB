// lib/services/email_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

class EmailService {
  static String generateOTP() {
    Random random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  static Future<bool> sendOTPEmail(String recipientEmail, String otp) async {
    try {
      // Cấu hình SMTP (sử dụng Gmail như ví dụ)
      String username = 'nguyenminh01060210@gmail.com';
      String password = 'ddhandbrzdlnonbf'; // Sử dụng App Password
      
      final smtpServer = gmail(username, password);
      
      final message = Message()
        ..from = Address(username, 'KFC Seller App')
        ..recipients.add(recipientEmail)
        ..subject = 'Mã OTP đặt lại mật khẩu - KFC Seller'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #4CAF50;">Đặt lại mật khẩu</h2>
            <p>Mã OTP để đặt lại mật khẩu của bạn là:</p>
            <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #4CAF50; font-size: 32px; margin: 0;">$otp</h1>
            </div>
            <p>Mã này sẽ hết hạn trong <strong>10 phút</strong>.</p>
            <p style="color: #888;">Vui lòng không chia sẻ mã này với bất kỳ ai.</p>
          </div>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
