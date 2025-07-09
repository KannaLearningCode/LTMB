import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/VNPay/VNPayService.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class VNPayCheckoutPage extends StatefulWidget {
  final Function(String)? onFinish;
  final List<CartItem> cartItems;
  final String paymentMethod;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final Mongodbmodel user;
  final mongo.ObjectId userId;

  const VNPayCheckoutPage({
    super.key,
    this.onFinish,
    required this.cartItems,
    required this.paymentMethod,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.user,
    required this.userId,
  });

  @override
  State<VNPayCheckoutPage> createState() => _VNPayCheckoutPageState();
}

class _VNPayCheckoutPageState extends State<VNPayCheckoutPage> {
  late final WebViewController _webViewController;
  String? checkoutUrl;

  static const returnURL = 'https://sandbox.vnpayment.vn/return';

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
        ),
      );

    _startVNPayCheckout();
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (url.contains(returnURL)) {
      final parsed = VNPayService.parseVNPayReturnUrl(url);
      final responseCode = parsed?['code'];
      final txnRef = parsed?['txnRef'] ?? '';

      if (responseCode == '00') {
        widget.onFinish?.call(txnRef); // Gọi callback truyền mã giao dịch
      } else {
        _showError("Thanh toán thất bại hoặc bị hủy");
      }

      Navigator.pop(context);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  // Trong build và controller giữ nguyên

Future<void> _startVNPayCheckout() async {
  try {
    final total = widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    final orderInfo = 'Thanh toan don hang cua ${VNPayService.removeUnicode(widget.user.fullName ?? '')}';

    final url = await VNPayService.createVNPayPaymentUrl(
      amount: total,
      orderInfo: orderInfo,
    );

    if (url != null) {
      setState(() => checkoutUrl = url);
      _webViewController.loadRequest(Uri.parse(url));
    } else {
      _showError("Không thể tạo liên kết thanh toán VNPay");
    }
  } catch (e) {
    _showError("Lỗi khi khởi tạo thanh toán: $e");
  }
}


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán VNPay"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: checkoutUrl != null
          ? WebViewWidget(controller: _webViewController)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
