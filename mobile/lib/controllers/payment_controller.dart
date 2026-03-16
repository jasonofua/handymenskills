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
  RxDouble walletBalance = 0.0.obs;
  Rxn<String> lastTopUpTime = Rxn<String>();

  Future<void> loadWalletBalance() async {
    try {
      final data = await _paymentRepo.getWalletPayments();
      double topUpSum = 0.0;
      double bookingSum = 0.0;
      String? latestTopUp;
      for (final payment in data) {
        final status = payment['status']?.toString();
        if (status != 'success' && status != 'pending') continue;
        final rawAmount = payment['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount.toString()) ?? 0.0;
        final paymentType = payment['payment_type']?.toString();
        if (paymentType == 'wallet_topup') {
          topUpSum += amount;
          final createdAt = payment['created_at']?.toString();
          if (createdAt != null) {
            if (latestTopUp == null || createdAt.compareTo(latestTopUp) > 0) {
              latestTopUp = createdAt;
            }
          }
        } else if (paymentType == 'booking_payment' || paymentType == 'booking_deposit') {
          bookingSum += amount;
        }
      }
      walletBalance.value = topUpSum - bookingSum;
      lastTopUpTime.value = latestTopUp;
    } catch (e) {
      AppSnackbar.error('Failed to load wallet balance');
    }
  }

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
        final paymentData = <String, dynamic>{
          'user_id': _authController.userId,
          'payment_type': paymentType,
          'amount': amountInNaira,
          'currency': 'NGN',
          'status': 'success',
          'paystack_reference': result.reference,
        };
        if (bookingId != null) paymentData['booking_id'] = bookingId;
        if (subscriptionId != null) paymentData['subscription_id'] = subscriptionId;
        await _paymentRepo.insertPayment(paymentData);
        await loadWalletBalance();
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
