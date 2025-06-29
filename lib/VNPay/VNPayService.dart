import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class VNPayService {
  static const String _baseUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String _tmnCode = 'ZB2CAHDR';
  static const String _returnUrl = 'https://sandbox.vnpayment.vn/return';
  static const String _hashKey = 'QBMWNZ5XHK2NGARCY75SQEHG0B5NYPQZ';

  static Future<String?> createVNPayPaymentUrl({
    required double amount,
    required String orderInfo,
  }) async {
    try {
      final txnRef = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final expireDate = now.add(const Duration(minutes: 15));
      final ipAddr = '127.0.0.1';
      final sanitizedOrderInfo = removeUnicode(orderInfo);

      final params = <String, String>{
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': _tmnCode,
        'vnp_Amount': (amount * 100).round().toString(),
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': txnRef,
        'vnp_OrderInfo': sanitizedOrderInfo,
        'vnp_Locale': 'vn',
        'vnp_ReturnUrl': _returnUrl,
        'vnp_IpAddr': ipAddr,
        'vnp_CreateDate': DateFormat('yyyyMMddHHmmss').format(now),
        'vnp_ExpireDate': DateFormat('yyyyMMddHHmmss').format(expireDate),
      };

      final sortedKeys = params.keys.toList()..sort();
      final rawData = sortedKeys.map((k) => '$k=${params[k]}').join('&');

      final hmac = Hmac(sha512, utf8.encode(_hashKey));
      final secureHash = hmac.convert(utf8.encode(rawData)).toString();

      params['vnp_SecureHashType'] = 'SHA512';
      params['vnp_SecureHash'] = secureHash;

      final fullQuery = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final fullUrl = '$_baseUrl?$fullQuery';
      return fullUrl;
    } catch (e) {
      print('❌ Lỗi tạo VNPay URL: $e');
      return null;
    }
  }

  static Map<String, String>? parseVNPayReturnUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return {
        'code': uri.queryParameters['vnp_ResponseCode'] ?? '',
        'txnRef': uri.queryParameters['vnp_TxnRef'] ?? '',
      };
    } catch (e) {
      print('❌ Lỗi phân tích return URL: $e');
      return null;
    }
  }

  static String removeUnicode(String text) {
    final vietnamese = 'àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệ'
        'ìíỉĩịòóỏõọôồốổỗộơờớởỡợ'
        'ùúủũụưừứửữựỳýỷỹỵđ'
        'ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆ'
        'ÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ'
        'ÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
    final ascii = 'aaaaaaaaaaaaaaaaaeeeeeeeeeee'
        'iiiiiooooooooooooooooo'
        'uuuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEE'
        'IIIIIooooooooooooooooo'
        'UUUUUUUUUUUYYYYYD';

    for (int i = 0; i < vietnamese.length; i++) {
      text = text.replaceAll(vietnamese[i], ascii[i]);
    }
    return text;
  }
}