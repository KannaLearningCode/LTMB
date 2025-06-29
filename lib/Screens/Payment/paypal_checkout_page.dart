import 'package:flutter/material.dart';
import 'package:kfc_seller/Models/cart.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Paypal/PaypalService.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:webview_flutter/webview_flutter.dart';

class PaypalCheckoutPage extends StatefulWidget {
  final Function(String paymentId)? onFinish;
  final List<CartItem> cartItems;
  final String paymentMethod;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final Mongodbmodel user;
  final mongo.ObjectId userId;
  final double discountAmount; // 🔥 Thêm dòng này

  const PaypalCheckoutPage({
    super.key,
    this.onFinish,
    required this.cartItems,
    required this.paymentMethod,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.user,
    required this.userId,
    required this.discountAmount,
  });

  @override
  State<PaypalCheckoutPage> createState() => _PaypalCheckoutPageState();
}

class _PaypalCheckoutPageState extends State<PaypalCheckoutPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final PaypalServices services = PaypalServices();
  late final WebViewController _webViewController;

  String? checkoutUrl;
  String? executeUrl;
  String? accessToken;

  final Map<String, dynamic> defaultCurrency = {
    "symbol": "USD ",
    "decimalDigits": 2,
    "symbolBeforeTheNumber": true,
    "currency": "USD"
  };

  String returnURL = 'return.example.com';
  String cancelURL = 'cancel.example.com';

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            if (url.contains(returnURL)) {
              final uri = Uri.parse(url);
              final payerId = uri.queryParameters['PayerID'];
            if (payerId != null && executeUrl != null && accessToken != null) {
              services.executePayment(Uri.parse(executeUrl!), payerId, accessToken!).then((paymentId) {
                if (paymentId != null && widget.onFinish != null) {
                  widget.onFinish!(paymentId); // ✅ Gọi callback và để callback tự xử lý Navigator
                } else {
                  Navigator.of(context).pop(); // ❗️Chỉ pop nếu không có callback
                }
              });
            }
              return NavigationDecision.prevent;
            }

            if (url.contains(cancelURL)) {
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    _createPaypalCheckout();
  }

  Future<void> _createPaypalCheckout() async {
    try {
      accessToken = await services.getAccessToken();
      if (accessToken == null) {
        showError("Không lấy được access token.");
        return;
      }

      final transactions = getOrderParams(widget.cartItems);
      final res = await services.createPaypalPayment(transactions, accessToken!);
print("📦 Phản hồi từ PayPal: $res");
      if (res != null) {
        setState(() {
          checkoutUrl = res["approvalUrl"];
          executeUrl = res["executeUrl"];
        });

        if (checkoutUrl != null) {
          _webViewController.loadRequest(Uri.parse(checkoutUrl!));
        }
      } else {
        showError("Không tạo được thanh toán.");
      }
    } catch (ex) {
      showError("Lỗi: ${ex.toString()}");
    }
  }

  void showError(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Đóng',
          onPressed: () {},
        ),
      ),
    );
  }

  Map<String, dynamic> getOrderParams(List<CartItem> cartItems) {
  const double exchangeRate = 25000; // 1 USD = 25,000 VNĐ

  // 🧮 Tính tổng giá trước khi giảm giá
  double subtotalUSD = cartItems.fold(
    0,
    (sum, item) => sum + (item.price * item.quantity) / exchangeRate,
  );

  double discountUSD = widget.discountAmount / exchangeRate;
  double finalTotal = subtotalUSD - discountUSD;

  if (finalTotal < 0.01) {
    showError("Số tiền sau giảm giá quá thấp, không thể thanh toán qua PayPal.");
    return {};
  }

  // 🎯 Danh sách sản phẩm
  List<Map<String, dynamic>> items = cartItems.map((item) => {
        "name": item.productName,
        "quantity": item.quantity.toString(),
        "price": (item.price / exchangeRate).toStringAsFixed(2),
        "currency": defaultCurrency["currency"]
      }).toList();

  // ✅ Thêm item giảm giá âm vào đây
  if (discountUSD > 0) {
    items.add({
      "name": "Giảm giá",
      "quantity": "1",
      "price": (-discountUSD).toStringAsFixed(2),
      "currency": defaultCurrency["currency"]
    });
  }

  return {
    "intent": "sale",
    "payer": {"payment_method": "paypal"},
    "transactions": [
      {
        "amount": {
          "total": finalTotal.toStringAsFixed(2),
          "currency": defaultCurrency["currency"],
          "details": {
            "subtotal": finalTotal.toStringAsFixed(2),
            "shipping": '0',
            "shipping_discount": '0.00'
          }
        },
        "description": "Thanh toán đơn hàng qua PayPal.",
        "payment_options": {
          "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
        },
        "item_list": {
          "items": items,
        }
      }
    ],
    "note_to_payer": "Liên hệ chúng tôi nếu có bất kỳ thắc mắc nào.",
    "redirect_urls": {
      "return_url": returnURL,
      "cancel_url": cancelURL,
    }
  };
}



  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("PayPal Checkout"),
        ),
        body: checkoutUrl != null
            ? WebViewWidget(controller: _webViewController)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
