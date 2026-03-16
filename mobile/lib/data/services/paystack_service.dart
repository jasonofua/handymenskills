import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';

/// Represents the outcome of a Paystack payment attempt.
class PaymentResponse {
  /// Whether the payment completed successfully.
  final bool success;

  /// The unique transaction reference (matches the one supplied at checkout).
  final String? reference;

  /// A human-readable status message.
  final String? message;

  const PaymentResponse({
    required this.success,
    this.reference,
    this.message,
  });

  @override
  String toString() =>
      'PaymentResponse(success: $success, reference: $reference, message: $message)';
}

/// Service for processing payments through Paystack.
///
/// Initializes a transaction via the Paystack API, then opens the SDK popup
/// with the authorization URL. All amounts are expected in **kobo**.
class PaystackService {
  final _random = Random();
  static const _callbackUrl = 'https://handymenskills.ng/payment/callback';

  /// Opens the Paystack checkout and waits for the user to complete or cancel.
  Future<PaymentResponse> checkout({
    required BuildContext context,
    required String email,
    required int amountInKobo,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    // Step 1: Initialize transaction via Paystack API to get authorization URL
    final authUrl = await _initializeTransaction(
      email: email,
      amountInKobo: amountInKobo,
      reference: reference,
      metadata: metadata,
    );

    if (authUrl == null) {
      return PaymentResponse(
        success: false,
        reference: reference,
        message: 'Failed to initialize payment',
      );
    }

    // Step 2: Open the SDK with the authorization URL (no secretKey = no
    // internal verification hang — onSuccess fires immediately on redirect)
    PaymentResponse? result;

    await FlutterPaystackPlus.openPaystackPopup(
      context: context,
      publicKey: AppConstants.paystackPublicKey,
      customerEmail: email,
      amount: amountInKobo.toString(),
      reference: reference,
      currency: 'NGN',
      callBackUrl: _callbackUrl,
      authorizationUrl: authUrl,
      metadata: metadata,
      onSuccess: () {
        result = PaymentResponse(
          success: true,
          reference: reference,
          message: 'Payment completed successfully',
        );
      },
      onClosed: () {
        result ??= PaymentResponse(
          success: false,
          reference: reference,
          message: 'Payment was cancelled by the user',
        );
      },
    );

    return result ??
        PaymentResponse(
          success: false,
          reference: reference,
          message: 'Payment could not be processed',
        );
  }

  /// Calls Paystack's /transaction/initialize endpoint and returns the
  /// authorization URL, or null on failure.
  Future<String?> _initializeTransaction({
    required String email,
    required int amountInKobo,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.paystackSecretKey}',
        },
        body: jsonEncode({
          'email': email,
          'amount': amountInKobo.toString(),
          'reference': reference,
          'currency': 'NGN',
          'callback_url': _callbackUrl,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == true) {
          return body['data']['authorization_url'] as String?;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generates a unique payment reference string.
  String generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(900000) + 100000;
    return 'ART_${timestamp}_$randomSuffix';
  }
}
