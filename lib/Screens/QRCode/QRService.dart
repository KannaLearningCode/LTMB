class QRService {
  static const String bankShortName = 'VCB'; // Ví dụ: Vietcombank
  static const String accountNumber = '1027754185';
  static const String accountName = 'PHAM CONG MINH'; // Không dấu, viết hoa

  /// Tạo URL ảnh mã QR thanh toán VietQR
  static String generateQRImageUrl({
    required int amount,
    required String content,
  }) {
    return 'https://img.vietqr.io/image/$bankShortName-$accountNumber-compact2.jpg'
        '?amount=$amount&addInfo=$content&accountName=$accountName';
  }

  /// Tạo nội dung hiển thị thông tin chuyển khoản
  static String generateBankInfoText({
    required int amount,
    required String content,
  }) {
    return '''
Chủ tài khoản: $accountName
Ngân hàng: $bankShortName
Số tài khoản: $accountNumber
Nội dung chuyển khoản: $content
Số tiền: ${amount.toStringAsFixed(0)} đ
''';
  }
}
