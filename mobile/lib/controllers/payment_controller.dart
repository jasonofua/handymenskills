import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/payment_repository.dart';
import '../data/services/paystack_service.dart';
import '../data/services/realtime_service.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  final _paymentRepo = Get.find<PaymentRepository>();
  final _paystackService = Get.find<PaystackService>();
  final _authController = Get.find<AuthController>();
  final _realtimeService = Get.find<RealtimeService>();

  final RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> payouts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  RxDouble walletBalance = 0.0.obs;
  RxDouble workerAvailableBalance = 0.0.obs;
  Rxn<String> lastTopUpTime = Rxn<String>();

  RealtimeChannel? _paymentChannel;

  @override
  void onInit() {
    super.onInit();
    _subscribeToPayments();
  }

  @override
  void onClose() {
    _paymentChannel?.unsubscribe();
    super.onClose();
  }

  void _subscribeToPayments() {
    final userId = _authController.userId;
    if (userId.isEmpty) return;
    _paymentChannel = _realtimeService.subscribeToPayments(
      userId,
      () => loadWalletBalance(),
    );
  }

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

  /// Loads the worker's available balance for withdrawal
  Future<void> loadWorkerBalance() async {
    try {
      final balance = await _paymentRepo.getWorkerBalance();
      workerAvailableBalance.value = balance;
    } catch (e) {
      debugPrint('Failed to load worker balance: $e');
    }
  }

  /// Processes a withdrawal via Paystack transfer:
  /// 1. Resolve bank code from bank name
  /// 2. Create Paystack transfer recipient
  /// 3. Initiate Paystack transfer
  /// 4. Record payout in DB
  Future<bool> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      isProcessing.value = true;
      debugPrint('[Withdrawal] Starting withdrawal: amount=$amount, bank=$bankName, account=$accountNumber');

      if (amount < 5000) {
        debugPrint('[Withdrawal] Amount below minimum');
        AppSnackbar.error('Minimum withdrawal amount is \u20A65,000');
        return false;
      }

      // Refresh balance before checking
      debugPrint('[Withdrawal] Loading worker balance...');
      await loadWorkerBalance();
      debugPrint('[Withdrawal] Worker balance: ${workerAvailableBalance.value}');
      if (workerAvailableBalance.value < amount) {
        debugPrint('[Withdrawal] Insufficient balance');
        AppSnackbar.error('Insufficient balance for this withdrawal');
        return false;
      }

      // Step 1: Resolve bank name → Paystack bank code
      debugPrint('[Withdrawal] Step 1: Resolving bank code for "$bankName"...');
      final bankCode = await _paystackService.resolveBankCode(bankName);
      debugPrint('[Withdrawal] Step 1 done: bankCode=$bankCode');

      // Step 2: Create Paystack transfer recipient
      debugPrint('[Withdrawal] Step 2: Creating transfer recipient...');
      final recipientCode = await _paystackService.createTransferRecipient(
        name: accountName,
        accountNumber: accountNumber,
        bankCode: bankCode,
      );
      debugPrint('[Withdrawal] Step 2 done: recipientCode=$recipientCode');

      // Step 3: Initiate Paystack transfer
      debugPrint('[Withdrawal] Step 3: Initiating transfer...');
      final reference = _paystackService.generateReference();
      final amountInKobo = (amount * 100).round();
      final transferData = await _paystackService.initiateTransfer(
        amountInKobo: amountInKobo,
        recipientCode: recipientCode,
        reference: reference,
      );
      debugPrint('[Withdrawal] Step 3 done: transferData=$transferData');

      // Step 4: Record in DB — transfer was initiated successfully
      debugPrint('[Withdrawal] Step 4: Recording in DB...');
      final transferCode = transferData['transfer_code']?.toString();
      final transferStatus = transferData['status']?.toString() ?? 'success';
      final dbStatus = (transferStatus == 'success' || transferStatus == 'otp')
          ? 'completed'
          : 'processing';

      await _paymentRepo.createWithdrawalRecord(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
        status: dbStatus,
        transferCode: transferCode,
        recipientCode: recipientCode,
        reference: reference,
      );
      debugPrint('[Withdrawal] Step 4 done: recorded with status=$dbStatus');

      await Future.wait([
        loadWorkerBalance(),
        loadPayouts(),
      ]);

      debugPrint('[Withdrawal] SUCCESS');
      AppSnackbar.success('Withdrawal successful! Funds are being sent to your bank.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Withdrawal] ERROR: $e');
      debugPrint('[Withdrawal] STACK: $stackTrace');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(msg);
      return false;
    } finally {
      isProcessing.value = false;
      debugPrint('[Withdrawal] isProcessing set to false');
    }
  }

  /// Creates a payout record for the worker after client confirms & pays
  Future<void> createWorkerPayout({
    required String workerId,
    required String bookingId,
    required double agreedPrice,
  }) async {
    try {
      final workerPayout = agreedPrice * (1 - 0.15); // 15% platform fee
      await _paymentRepo.createPayout(
        workerId: workerId,
        bookingId: bookingId,
        amount: workerPayout,
      );
    } catch (e) {
      // Non-critical — don't block the flow
      debugPrint('Failed to create worker payout: $e');
    }
  }

  /// Deduct payment from wallet balance (no Paystack checkout).
  /// Returns true on success, false if insufficient balance.
  Future<bool> payFromWallet({
    required double amountInNaira,
    required String paymentType,
    String? bookingId,
  }) async {
    try {
      isProcessing.value = true;
      await loadWalletBalance();

      if (walletBalance.value < amountInNaira) {
        AppSnackbar.error(
          'Insufficient wallet balance. Please top up your wallet first.',
        );
        return false;
      }

      final paymentData = <String, dynamic>{
        'user_id': _authController.userId,
        'payment_type': paymentType,
        'amount': amountInNaira,
        'currency': 'NGN',
        'status': 'success',
        'paystack_reference': 'WALLET_${DateTime.now().millisecondsSinceEpoch}',
      };
      if (bookingId != null) paymentData['booking_id'] = bookingId;

      await _paymentRepo.insertPayment(paymentData);
      await loadWalletBalance();
      AppSnackbar.success('Payment successful');
      return true;
    } catch (e) {
      AppSnackbar.error('Payment failed: ${e.toString()}');
      return false;
    } finally {
      isProcessing.value = false;
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
