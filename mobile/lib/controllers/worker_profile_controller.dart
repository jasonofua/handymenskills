import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/repositories/worker_repository.dart';
import '../data/repositories/skill_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class WorkerProfileController extends GetxController {
  final _workerRepo = Get.find<WorkerRepository>();
  final _skillRepo = Get.find<SkillRepository>();
  final _authController = Get.find<AuthController>();

  final RxMap<String, dynamic> workerProfile = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> skills = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> workerSkills = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> schedule = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWorkerProfile();
    loadCategories();
  }

  Future<void> loadWorkerProfile() async {
    try {
      isLoading.value = true;
      final data = await _workerRepo.getWorkerProfile(_authController.userId);
      if (data != null) {
        workerProfile.assignAll(data);
        isAvailable.value = data['is_available'] ?? false;
        if (data['worker_skills'] != null) {
          workerSkills.assignAll(List<Map<String, dynamic>>.from(data['worker_skills']));
        }
      }
    } catch (e) {
      AppSnackbar.error('Failed to load worker profile');
    } finally {
      isLoading.value = false;
    }
  }

  final RxBool isCategoriesLoading = false.obs;
  final RxBool isSkillsLoading = false.obs;

  Future<void> loadCategories() async {
    try {
      isCategoriesLoading.value = true;
      categories.assignAll(await _skillRepo.getCategories());
    } catch (e) {
      AppSnackbar.error('Failed to load categories');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> loadSkillsByCategory(String categoryId) async {
    try {
      isSkillsLoading.value = true;
      skills.clear();
      skills.assignAll(await _skillRepo.getSkillsByCategory(categoryId));
    } catch (e) {
      AppSnackbar.error('Failed to load skills');
    } finally {
      isSkillsLoading.value = false;
    }
  }

  Future<void> toggleAvailability() async {
    try {
      final newValue = !isAvailable.value;
      await _workerRepo.toggleAvailability(_authController.userId, newValue);
      isAvailable.value = newValue;
    } catch (e) {
      AppSnackbar.error('Failed to update availability');
    }
  }

  Future<void> updateWorkerProfile(Map<String, dynamic> data) async {
    try {
      isSaving.value = true;
      await _workerRepo.updateWorkerProfile(_authController.userId, data);
      workerProfile.addAll(data);
      AppSnackbar.success('Profile updated');
    } catch (e) {
      AppSnackbar.error('Failed to update profile');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addSkill(Map<String, dynamic> skillData) async {
    try {
      await _skillRepo.addWorkerSkill(skillData);
      await loadWorkerProfile();
      AppSnackbar.success('Skill added');
    } catch (e) {
      AppSnackbar.error('Failed to add skill');
    }
  }

  Future<void> removeSkill(String workerSkillId) async {
    try {
      await _skillRepo.removeWorkerSkill(workerSkillId);
      workerSkills.removeWhere((s) => s['id'] == workerSkillId);
      AppSnackbar.success('Skill removed');
    } catch (e) {
      AppSnackbar.error('Failed to remove skill');
    }
  }

  Future<void> uploadPortfolioImage(File file) async {
    try {
      isSaving.value = true;
      debugPrint('[Portfolio] Uploading image: ${file.path}');
      debugPrint('[Portfolio] File exists: ${file.existsSync()}, size: ${file.lengthSync()} bytes');
      final url = await _workerRepo.uploadPortfolioImage(_authController.userId, file);
      debugPrint('[Portfolio] Upload success, URL: $url');
      final images = List<String>.from(workerProfile['portfolio_images'] ?? []);
      images.add(url);
      await _workerRepo.updateWorkerProfile(
        _authController.userId,
        {'portfolio_images': images},
      );
      workerProfile['portfolio_images'] = images;
      workerProfile.refresh();
      AppSnackbar.success('Image uploaded');
    } catch (e) {
      debugPrint('[Portfolio] Upload FAILED: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(msg);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removePortfolioImage(String imageUrl) async {
    try {
      isSaving.value = true;
      await _workerRepo.removePortfolioImage(_authController.userId, imageUrl);
      final images = List<String>.from(workerProfile['portfolio_images'] ?? []);
      images.remove(imageUrl);
      await _workerRepo.updateWorkerProfile(
        _authController.userId,
        {'portfolio_images': images},
      );
      workerProfile['portfolio_images'] = images;
      workerProfile.refresh();
      AppSnackbar.success('Image removed');
    } catch (e) {
      AppSnackbar.error('Failed to remove image');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> uploadIdDocument(File file) async {
    try {
      isSaving.value = true;
      final url = await _workerRepo.uploadIdDocument(_authController.userId, file);
      await _workerRepo.updateWorkerProfile(
        _authController.userId,
        {'id_document_url': url, 'verification_status': 'pending'},
      );
      workerProfile['id_document_url'] = url;
      workerProfile['verification_status'] = 'pending';
      workerProfile.refresh();
      AppSnackbar.success('Document uploaded for verification');
    } catch (e) {
      AppSnackbar.error('Failed to upload document');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> loadSchedule() async {
    try {
      final workerProfileId = workerProfile['id'];
      if (workerProfileId == null) return;
      final data = await _workerRepo.getSchedule(workerProfileId as String);
      schedule.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load schedule');
    }
  }

  Future<void> updateScheduleDay({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isAvailableDay,
  }) async {
    try {
      final workerProfileId = workerProfile['id'];
      if (workerProfileId == null) return;

      await _workerRepo.upsertScheduleDay({
        'worker_id': workerProfileId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailableDay,
      });
      await loadSchedule();
    } catch (e) {
      AppSnackbar.error('Failed to update schedule');
    }
  }

  Future<void> toggleDayAvailability(int dayOfWeek, bool available) async {
    try {
      final workerProfileId = workerProfile['id'];
      if (workerProfileId == null) return;

      final existing = schedule.firstWhereOrNull(
          (s) => s['day_of_week'] == dayOfWeek);

      await _workerRepo.upsertScheduleDay({
        'worker_id': workerProfileId,
        'day_of_week': dayOfWeek,
        'start_time': existing?['start_time'] ?? '09:00:00',
        'end_time': existing?['end_time'] ?? '17:00:00',
        'is_available': available,
      });
      await loadSchedule();
    } catch (e) {
      AppSnackbar.error('Failed to update schedule');
    }
  }

  Future<void> updateBankDetails(Map<String, dynamic> bankData) async {
    try {
      isSaving.value = true;
      await _workerRepo.updateBankDetails(_authController.userId, bankData);
      workerProfile.addAll(bankData);
      AppSnackbar.success('Bank details updated');
    } catch (e) {
      AppSnackbar.error('Failed to update bank details');
    } finally {
      isSaving.value = false;
    }
  }
}
