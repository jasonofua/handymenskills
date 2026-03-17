import 'package:get/get.dart';
import '../data/repositories/application_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class ApplicationController extends GetxController {
  final _appRepo = Get.find<ApplicationRepository>();
  final _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> myApplications = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> jobApplications = <Map<String, dynamic>>[].obs;
  final RxSet<String> appliedJobIds = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  Future<void> loadAppliedJobIds() async {
    try {
      final ids = await _appRepo.getAppliedJobIds(_authController.userId);
      appliedJobIds.assignAll(ids);
    } catch (_) {}
  }

  Future<void> loadMyApplications({String? status}) async {
    try {
      isLoading.value = true;
      final data = await _appRepo.getMyApplications(
        _authController.userId,
        status: status,
      );
      myApplications.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load applications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJobApplications(String jobId) async {
    try {
      isLoading.value = true;
      final data = await _appRepo.getJobApplications(jobId);
      jobApplications.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load applications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> applyToJob({
    required String jobId,
    required String coverLetter,
    required double proposedPrice,
    String? estimatedDuration,
  }) async {
    try {
      isSubmitting.value = true;
      await _appRepo.applyToJob(
        jobId,
        coverLetter,
        proposedPrice,
        estimatedDuration: estimatedDuration,
      );
      appliedJobIds.add(jobId);
      AppSnackbar.success('Application submitted!');
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('subscription')) {
        AppSnackbar.error('Active subscription required to apply');
      } else if (message.contains('already applied')) {
        AppSnackbar.error('You have already applied to this job');
      } else if (message.contains('limit')) {
        AppSnackbar.error('Application limit reached for your plan');
      } else {
        AppSnackbar.error('Failed to submit application');
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> hasAppliedToJob(String jobId) async {
    try {
      return await _appRepo.hasAppliedToJob(_authController.userId, jobId);
    } catch (e) {
      return false;
    }
  }

  Future<void> withdrawApplication(String applicationId) async {
    try {
      await _appRepo.withdrawApplication(applicationId);
      myApplications.removeWhere((a) => a['id'] == applicationId);
      AppSnackbar.success('Application withdrawn');
    } catch (e) {
      AppSnackbar.error('Failed to withdraw application');
    }
  }

  Future<Map<String, dynamic>?> acceptApplication(String applicationId) async {
    try {
      final booking = await _appRepo.acceptApplication(applicationId);
      // Update accepted application in list
      final index = jobApplications.indexWhere((a) => a['id'] == applicationId);
      if (index != -1) {
        jobApplications[index] = {...jobApplications[index], 'status': 'accepted'};
      }
      // Mark other applications as rejected
      for (var i = 0; i < jobApplications.length; i++) {
        if (jobApplications[i]['id'] != applicationId &&
            jobApplications[i]['status'] == 'pending') {
          jobApplications[i] = {...jobApplications[i], 'status': 'rejected'};
        }
      }
      jobApplications.refresh();
      AppSnackbar.success('Application accepted. Booking created!');
      return booking;
    } catch (e) {
      AppSnackbar.error('Failed to accept application');
      return null;
    }
  }

  Future<void> rejectApplication(String applicationId) async {
    try {
      await _appRepo.rejectApplication(applicationId);
      final index = jobApplications.indexWhere((a) => a['id'] == applicationId);
      if (index != -1) {
        jobApplications[index] = {...jobApplications[index], 'status': 'rejected'};
        jobApplications.refresh();
      }
    } catch (e) {
      AppSnackbar.error('Failed to reject application');
    }
  }
}
