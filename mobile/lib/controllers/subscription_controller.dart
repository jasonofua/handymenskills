import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/repositories/subscription_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'payment_controller.dart';

class SubscriptionController extends GetxController {
  final _subscriptionRepo = Get.find<SubscriptionRepository>();

  final RxList<Map<String, dynamic>> plans = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> currentSubscription = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;
  final RxString subscriptionStatus = 'expired'.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
    loadMySubscription();
  }

  Future<void> loadPlans() async {
    try {
      final data = await _subscriptionRepo.getPlans();
      plans.assignAll(data);
    } catch (e) {
      debugPrint('SubscriptionController: Failed to load plans: $e');
    }
  }

  Future<void> loadMySubscription() async {
    try {
      isLoading.value = true;
      currentSubscription.value = await _subscriptionRepo.getMySubscription();
      if (currentSubscription.value != null) {
        subscriptionStatus.value = currentSubscription.value!['status'] ?? 'expired';
      }
    } catch (e) {
      debugPrint('SubscriptionController: Failed to load subscription: $e');
      subscriptionStatus.value = 'expired';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> subscribe(BuildContext context, Map<String, dynamic> plan) async {
    try {
      final paymentController = Get.find<PaymentController>();
      final success = await paymentController.processPayment(
        context: context,
        amountInNaira: (plan['price'] as num).toDouble(),
        paymentType: 'subscription_payment',
      );
      if (success) {
        await loadMySubscription();
        return true;
      }
      return false;
    } catch (e) {
      AppSnackbar.error('Subscription failed');
      return false;
    }
  }

  bool get isActive => subscriptionStatus.value == 'active';
  bool get isGracePeriod => subscriptionStatus.value == 'grace_period';
  bool get isExpired => subscriptionStatus.value == 'expired';

  int get daysRemaining {
    if (currentSubscription.value == null) return 0;
    final expiresAt = DateTime.tryParse(currentSubscription.value!['expires_at'] ?? '');
    if (expiresAt == null) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }
}
