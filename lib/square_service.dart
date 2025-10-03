import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SquareService {
  // Square credentials
  static const String applicationId = 'sandbox-sq0idb-40uXa4rU4cti_NJ9YW3RgA';
  static const String accessToken =
      'EAAAl1YpZ1xah8aJWX57MLdWT77a9rQEw4XzIZHZ8LGBIfxnv93LPn06QH7c20tn';
  static const String environment = 'SANDBOX';

  // API endpoints
  static const String sandboxBaseUrl = 'https://connect.squareupsandbox.com';
  static const String productionBaseUrl = 'https://connect.squareup.com';

  static String get baseUrl =>
      environment == 'SANDBOX' ? sandboxBaseUrl : productionBaseUrl;

  // Initialize Square In-App Payments
  static Future<void> initialize() async {
    try {
      await InAppPayments.setSquareApplicationId(applicationId);
      print('Square service initialized successfully');
    } catch (e) {
      print('Square initialization error: $e');
      rethrow;
    }
  }

  // Process payment with Square
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String orderId,
    String? buyerEmailAddress,
    String? note,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        throw Exception('Payment amount must be greater than zero');
      }

      // Convert amount to cents
      final amountInCents = (amount * 100).round();

      // Get card details from user
      final cardDetails = await _getCardDetails();

      if (cardDetails == null) {
        return {'success': false, 'error': 'Payment cancelled by user'};
      }

      // Create payment request
      final paymentRequest = {
        'source_id': cardDetails.nonce,
        'amount_money': {'amount': amountInCents, 'currency': 'GBP'},
        'idempotency_key':
            '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
        'reference_id': orderId,
        'note': note ?? 'Tandoori Nights Order #$orderId',
        if (buyerEmailAddress != null) 'buyer_email_address': buyerEmailAddress,
      };

      // Send payment request to Square
      final response = await http.post(
        Uri.parse('$baseUrl/v2/payments'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Square-Version': '2023-10-18',
        },
        body: json.encode(paymentRequest),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['payment'] != null) {
        return {
          'success': true,
          'payment_id': responseData['payment']['id'],
          'status': responseData['payment']['status'],
          'amount': amount,
          'currency': 'GBP',
          'receipt_url': responseData['payment']['receipt_url'],
        };
      } else {
        final errors = responseData['errors'] ?? [];
        final errorMessage = errors.isNotEmpty
            ? errors[0]['detail'] ?? 'Payment processing failed'
            : 'Payment processing failed';

        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'error': 'Payment error: ${e.toString()}'};
    }
  }

  // Get card details from user
  static Future<CardDetails?> _getCardDetails() async {
    try {
      CardDetails? cardDetails;
      bool cardEntryCompleted = false;

      await InAppPayments.startCardEntryFlow(
        onCardNonceRequestSuccess: (details) {
          cardDetails = details;
          cardEntryCompleted = true;
        },
        onCardEntryCancel: () {
          cardDetails = null;
          cardEntryCompleted = true;
        },
      );

      // Wait for card entry to complete
      while (!cardEntryCompleted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return cardDetails;
    } catch (e) {
      print('Card entry error: $e');
      return null;
    }
  }

  // Verify payment status
  static Future<Map<String, dynamic>> verifyPayment(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Square-Version': '2023-10-18',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'payment': responseData['payment']};
      } else {
        return {'success': false, 'error': 'Failed to verify payment'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Verification error: ${e.toString()}'};
    }
  }

  // Refund payment
  static Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Refund amount must be greater than zero');
      }

      final amountInCents = (amount * 100).round();

      final refundRequest = {
        'amount_money': {'amount': amountInCents, 'currency': 'GBP'},
        'payment_id': paymentId,
        'idempotency_key':
            '${paymentId}_refund_${DateTime.now().millisecondsSinceEpoch}',
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v2/refunds'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Square-Version': '2023-10-18',
        },
        body: json.encode(refundRequest),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['refund'] != null) {
        return {
          'success': true,
          'refund_id': responseData['refund']['id'],
          'status': responseData['refund']['status'],
          'amount': amount,
        };
      } else {
        final errors = responseData['errors'] ?? [];
        final errorMessage = errors.isNotEmpty
            ? errors[0]['detail'] ?? 'Refund failed'
            : 'Refund failed';

        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'error': 'Refund error: ${e.toString()}'};
    }
  }

  // Check if Square is properly configured
  static bool isConfigured() {
    return applicationId.isNotEmpty &&
        accessToken.isNotEmpty &&
        applicationId != 'YOUR_SQUARE_APPLICATION_ID_HERE' &&
        accessToken != 'YOUR_SQUARE_ACCESS_TOKEN_HERE';
  }

  // Get environment info
  static String getEnvironment() {
    return environment;
  }

  // Format currency for display
  static String formatCurrency(double amount) {
    return '£${amount.toStringAsFixed(2)}';
  }
}
