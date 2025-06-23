import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart';

class PaypalServices {
  /// PayPal endpoint
  final String domain = "https://api.sandbox.paypal.com"; // Test mode
  // final String domain = "https://api.paypal.com"; // Production mode

  /// Your PayPal credentials
  final String clientId = 'ARgItEKLioAmZIx70hh7FSfhWqsAU1bx8wfnz4sDQaTsD5gAYWjJwk1B_d7enIL4KQl1hHght6AGiGWg';
  final String secret = 'ELM3HPjj2oXell_p1pxJryVgFqXazfOkoFyw8anaJBwjy_MCh98KysUQ1U0ZBNfYP8FMZ-OfNjxDUnbH';

  /// Get access token from PayPal
  Future<String?> getAccessToken() async {
    try {
      var client = BasicAuthClient(clientId, secret);
      var response = await client.post(
        Uri.parse('$domain/v1/oauth2/token'),
        headers: {'Accept': 'application/json'},
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body);
        return body["access_token"];
      } else {
        print('Failed to get access token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  /// Create a payment on PayPal
  Future<Map<String, String>?> createPaypalPayment(
    Map<String, dynamic> transactions,
    String accessToken,
  ) async {
    try {
      var response = await http.post(
        Uri.parse("$domain/v1/payments/payment"),
        body: convert.jsonEncode(transactions),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      final body = convert.jsonDecode(response.body);

      if (response.statusCode == 201) {
        List links = body["links"] ?? [];

        String? approvalUrl;
        String? executeUrl;

        for (var link in links) {
          if (link["rel"] == "approval_url") {
            approvalUrl = link["href"];
          } else if (link["rel"] == "execute") {
            executeUrl = link["href"];
          }
        }

        if (approvalUrl != null && executeUrl != null) {
          return {
            "approvalUrl": approvalUrl,
            "executeUrl": executeUrl,
          };
        } else {
          print("Approval or execute URL not found");
          return null;
        }
      } else {
        print("Create payment failed: ${body['message']}");
        return null;
      }
    } catch (e) {
      print("Error creating PayPal payment: $e");
      rethrow;
    }
  }

  /// Execute the payment after user approval
  Future<String?> executePayment(
    Uri url,
    String payerId,
    String accessToken,
  ) async {
    try {
      var response = await http.post(
        url,
        body: convert.jsonEncode({"payer_id": payerId}),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      final body = convert.jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body["id"];
      } else {
        print("Payment execution failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error executing payment: $e");
      rethrow;
    }
  }
}
