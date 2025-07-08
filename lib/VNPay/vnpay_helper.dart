import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

String createVNPayUrl({
  required String tmnCode,
  required String hashKey,
  required double amount,
  required String orderInfo,
  required String returnUrl,
}) {
  final now = DateTime.now();
  final expireDate = now.add(const Duration(minutes: 15));
  final txnRef = now.millisecondsSinceEpoch.toString();
  final ipAddr = '127.0.0.1';

  final params = <String, String>{
    'vnp_Version': '2.1.0',
    'vnp_Command': 'pay',
    'vnp_TmnCode': tmnCode,
    'vnp_Amount': (amount * 100).round().toString(),
    'vnp_CurrCode': 'VND',
    'vnp_TxnRef': txnRef,
    'vnp_OrderInfo': orderInfo,
    'vnp_OrderType': 'other',
    'vnp_Locale': 'vn',
    'vnp_ReturnUrl': returnUrl,
    'vnp_IpAddr': ipAddr,
    'vnp_CreateDate': DateFormat('yyyyMMddHHmmss').format(now),
    'vnp_ExpireDate': DateFormat('yyyyMMddHHmmss').format(expireDate),
  };

  final sortedKeys = params.keys.toList()..sort();
  // KHÔNG encode khi build rawData để ký hash!
  final rawData = sortedKeys
      .map((k) => '$k=${params[k]}')
      .join('&');

  print('VNPay rawData for hash: $rawData');
  print('VNPay hashKey: $hashKey');

  final hmac = Hmac(sha512, utf8.encode(hashKey));
  final secureHash = hmac.convert(utf8.encode(rawData)).toString();

  print('VNPay secureHash: $secureHash');

  params['vnp_SecureHashType'] = 'HMACSHA512';
  params['vnp_SecureHash'] = secureHash;

  // Khi build fullUrl mới encode value!
  final fullQuery = params.entries
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');

  final fullUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?$fullQuery';

  print('VNPay fullUrl: $fullUrl');

  return fullUrl;
}
