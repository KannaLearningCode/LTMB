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
      String username = 'nguyenminh01060210@gmail.com';
      String password = 'ddhandbrzdlnonbf';
      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'KFC Seller App')
        ..recipients.add(recipientEmail)
        ..subject = 'Mã OTP đặt lại mật khẩu - KFC Seller'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 540px; margin: 0 auto; background: #fff; border-radius: 12px; border: 1px solid #ececec; box-shadow: 0 2px 8px rgba(228,0,43,0.07); padding: 32px 24px;">
            <h2 style="color: #E4002B; margin-top: 0; font-size: 26px; font-weight: bold; letter-spacing: 1px;">Đặt lại mật khẩu KFC Seller</h2>
            <p style="font-size: 15px; color: #212121; margin-bottom: 20px;">
              Xin chào,<br>
              Sau đây là mã OTP xác thực để đặt lại mật khẩu của bạn:
            </p>
            <div style="background: #FFF5F6; padding: 24px; border-radius: 12px; text-align: center; margin: 20px 0 28px;">
              <span style="color: #E4002B; font-size: 38px; font-weight: bold; letter-spacing: 12px; font-family: 'Courier New', Courier, monospace;">$otp</span>
            </div>
            <p style="font-size: 15px; color: #4f4f4f; margin-bottom: 8px;">
              <b>Lưu ý:</b> Mã OTP này có hiệu lực trong <span style="color: #E4002B; font-weight: 500;">10 phút</span>. Vui lòng không chia sẻ mã này với bất kỳ ai vì lý do bảo mật tài khoản.
            </p>
            <div style="padding: 16px; font-size: 14px; background: #FDEBEE; border-left: 4px solid #E4002B; border-radius: 8px; margin-top: 16px; color: #B71C1C;">
              Nếu bạn không thực hiện yêu cầu này, xin vui lòng bỏ qua email này hoặc liên hệ bộ phận hỗ trợ của KFC Seller.
            </div>
            <div style="text-align: right; color: #888; font-size: 13px; margin-top: 36px;">
              Trân trọng,<br>
              <span style="color: #E4002B; font-weight: bold;">KFC Seller Team</span>
            </div>
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
