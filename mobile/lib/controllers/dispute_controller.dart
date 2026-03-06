import 'package:get/get.dart';
import '../data/repositories/dispute_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class DisputeController extends GetxController {
  final _disputeRepo = Get.find<DisputeRepository>();
  final _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> disputes = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> currentDispute = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  Future<void> loadMyDisputes() async {
    try {
      isLoading.value = true;
      final data = await _disputeRepo.getMyDisputes();
      disputes.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load disputes');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDisputeDetail(String id) async {
    try {
      isLoading.value = true;
      final data = await _disputeRepo.getDisputeById(id);
      currentDispute.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load dispute details');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createDispute({
    required String bookingId,
    required String reason,
    List<String> evidence = const [],
  }) async {
    try {
      isSubmitting.value = true;
      await _disputeRepo.createDispute({
        'booking_id': bookingId,
        'initiator_id': _authController.userId,
        'reason': reason,
        'evidence': evidence,
      });
      AppSnackbar.success('Dispute submitted successfully');
      return true;
    } catch (e) {
      AppSnackbar.error('Failed to submit dispute');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
