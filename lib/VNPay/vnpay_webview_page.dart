import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VNPayWebViewPage extends StatelessWidget {
  final String paymentUrl;
  final String returnUrl;
  final Function(String)? onFinish;

  const VNPayWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.returnUrl,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains(returnUrl)) {
              if (onFinish != null) onFinish!(request.url);
              Navigator.pop(context, request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    controller.loadRequest(Uri.parse(paymentUrl));

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VNPay')),
      body: WebViewWidget(controller: controller),
    );
  }
}
