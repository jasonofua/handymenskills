import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

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
/// Uses [FlutterPaystackPlus] which opens a WebView-based checkout page.
/// All amounts are expected in **kobo** (i.e. Naira * 100).
class PaystackService {
  final _random = Random();

  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  /// Opens the Paystack checkout popup and waits for the user to complete or
  /// cancel the payment.
  ///
  /// [context]      -- the build context required for the WebView overlay.
  /// [email]        -- the customer's email address.
  /// [amountInKobo] -- the charge amount in kobo (e.g. 5000 = NGN 50).
  /// [reference]    -- a unique transaction reference. Generate one with
  ///                   [generateReference] if you don't already have one.
  /// [metadata]     -- optional key-value pairs attached to the transaction on
  ///                   the Paystack dashboard.
  ///
  /// Returns a [PaymentResponse] indicating success or cancellation.
  Future<PaymentResponse> checkout({
    required BuildContext context,
    required String email,
    required int amountInKobo,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    PaymentResponse? result;

    await FlutterPaystackPlus().checkout(
      context: context,
      publicKey: AppConstants.paystackPublicKey,
      secretKey: '',
      amount: amountInKobo.toString(),
      email: email,
      ref: reference,
      callBackUrl: '',
      onSuccess: (response) {
        result = PaymentResponse(
          success: true,
          reference: reference,
          message: 'Payment completed successfully',
        );
      },
      onCancelled: () {
        result = PaymentResponse(
          success: false,
          reference: reference,
          message: 'Payment was cancelled by the user',
        );
      },
    );

    // If the callback was never invoked (edge case), treat it as a failure.
    return result ??
        PaymentResponse(
          success: false,
          reference: reference,
          message: 'Payment could not be processed',
        );
  }

  // ---------------------------------------------------------------------------
  // Reference generation
  // ---------------------------------------------------------------------------

  /// Generates a unique payment reference string.
  ///
  /// Format: `ART_<epoch_millis>_<random_6_digits>`
  ///
  /// Example: `ART_1709472000000_839271`
  String generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(900000) + 100000; // 6-digit number
    return 'ART_${timestamp}_$randomSuffix';
  }
}
