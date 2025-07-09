import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class VNPayService {
  static const String _baseUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String _tmnCode = 'ZB2CAHDR';
  static const String _returnUrl = 'https://sandbox.vnpayment.vn/return';
  static const String _hashKey = 'QBMWNZ5XHK2NGARCY75SQEHG0B5NYPQZ';

  /// ✅ Tạo URL thanh toán VNPay
  static Future<String?> createVNPayPaymentUrl({
    required double amount,
    required String orderInfo,
    String orderType = 'other',
  }) async {
    try {
      final txnRef = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final expireDate = now.add(const Duration(minutes: 15));
      final ipAddr = await getIpAddress(); // ✅ lấy IP thật

      final sanitizedOrderInfo = removeUnicode(orderInfo);

      final params = <String, String>{
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': _tmnCode,
        'vnp_Amount': (amount * 100).round().toString(),
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': txnRef,
        'vnp_OrderInfo': sanitizedOrderInfo,
        'vnp_OrderType': orderType,
        'vnp_Locale': 'vn',
        'vnp_ReturnUrl': _returnUrl,
        'vnp_IpAddr': ipAddr,
        'vnp_CreateDate': DateFormat('yyyyMMddHHmmss').format(now),
        'vnp_ExpireDate': DateFormat('yyyyMMddHHmmss').format(expireDate),
      };

      // ✅ Sort keys alphabetically
      final sortedKeys = params.keys.toList()..sort();
      final rawData = sortedKeys.map((k) => '$k=${params[k]}').join('&');

      // ✅ HMAC SHA512 Signature
      final secureHash = hmacSHA512(_hashKey, rawData);
      params['vnp_SecureHashType'] = 'SHA512';
      params['vnp_SecureHash'] = secureHash;

      final fullQuery = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final fullUrl = '$_baseUrl?$fullQuery';

      // Log ra debug nếu cần
      print('🔗 VNPay URL: $fullUrl');
      print('🔐 rawData: $rawData');
      print('🔐 secureHash: $secureHash');

      return fullUrl;
    } catch (e) {
      print('❌ Lỗi tạo VNPay URL: $e');
      return null;
    }
  }

  /// ✅ Xác minh chữ ký từ URL trả về
  static bool verifyReturnUrlSignature(Uri uri) {
    final queryParams = uri.queryParameters;
    final secureHash = queryParams['vnp_SecureHash']?.toLowerCase();
    if (secureHash == null) return false;

    // Lấy các key bắt đầu bằng vnp_ (trừ hash)
    final sortedParams = Map.fromEntries(
      queryParams.entries
          .where((e) =>
              e.key.startsWith('vnp_') &&
              e.key != 'vnp_SecureHash' &&
              e.key != 'vnp_SecureHashType')
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    final rawData = sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final generated = hmacSHA512(_hashKey, rawData);

    return generated.toLowerCase() == secureHash;
  }

  /// ✅ Tạo chữ ký SHA512 (giống C#)
  static String hmacSHA512(String key, String inputData) {
    final keyBytes = utf8.encode(key);
    final inputBytes = utf8.encode(inputData);
    final hmac = Hmac(sha512, keyBytes);
    final hash = hmac.convert(inputBytes);
    return hash.toString(); // hex string
  }

  /// ✅ Lấy địa chỉ IP thực tế
  static Future<String> getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'];
      }
    } catch (e) {
      print('❌ Lỗi lấy IP: $e');
    }
    return '127.0.0.1'; // fallback nếu không có mạng
  }

  /// ✅ Tách dữ liệu từ return URL
  static Map<String, String>? parseVNPayReturnUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return {
        'code': uri.queryParameters['vnp_ResponseCode'] ?? '',
        'txnRef': uri.queryParameters['vnp_TxnRef'] ?? '',
        'transactionStatus': uri.queryParameters['vnp_TransactionStatus'] ?? '',
        'secureHash': uri.queryParameters['vnp_SecureHash'] ?? '',
      };
    } catch (e) {
      print('❌ Lỗi phân tích return URL: $e');
      return null;
    }
  }

  /// ✅ Bỏ dấu tiếng Việt
  static String removeUnicode(String text) {
    const vietnamese = 'àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệ'
        'ìíỉĩịòóỏõọôồốổỗộơờớởỡợ'
        'ùúủũụưừứửữựỳýỷỹỵđ'
        'ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆ'
        'ÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ'
        'ÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
    const ascii = 'aaaaaaaaaaaaaaaaaeeeeeeeeeee'
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
