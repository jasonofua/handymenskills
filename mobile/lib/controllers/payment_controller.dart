import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/repositories/payment_repository.dart';
import '../data/services/paystack_service.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  final _paymentRepo = Get.find<PaymentRepository>();
  final _paystackService = Get.find<PaystackService>();
  final _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> payouts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;

  Future<void> loadPaymentHistory({String? paymentType}) async {
    try {
      isLoading.value = true;
      final data = await _paymentRepo.getPaymentHistory(paymentType: paymentType);
      paymentHistory.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load payment history');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPayouts() async {
    try {
      isLoading.value = true;
      final data = await _paymentRepo.getPayouts();
      payouts.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load payouts');
    } finally {
      isLoading.value = false;
    }
  }

  /// Process a payment via Paystack, then insert into payments table for verification
  Future<bool> processPayment({
    required BuildContext context,
    required double amountInNaira,
    required String paymentType,
    String? bookingId,
    String? subscriptionId,
  }) async {
    try {
      isProcessing.value = true;
      final email = _authController.profile['email'] ?? '${_authController.userId}@artisan.ng';
      final reference = _paystackService.generateReference();
      final amountInKobo = (amountInNaira * 100).round();

      final result = await _paystackService.checkout(
        context: context,
        email: email,
        amountInKobo: amountInKobo,
        reference: reference,
      );

      if (result.success) {
        // Insert payment record - DB trigger verifies with Paystack
        await _paymentRepo.insertPayment({
          'user_id': _authController.userId,
          'booking_id': bookingId,
          'subscription_id': subscriptionId,
          'payment_type': paymentType,
          'amount': amountInNaira,
          'currency': 'NGN',
          'status': 'pending',
          'paystack_reference': result.reference,
        });
        AppSnackbar.success('Payment successful');
        return true;
      } else {
        AppSnackbar.error(result.message ?? 'Payment cancelled');
        return false;
      }
    } catch (e) {
      AppSnackbar.error('Payment failed: ${e.toString()}');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
}
