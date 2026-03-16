import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/repositories/profile_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final _profileRepo = Get.find<ProfileRepository>();
  final _authController = Get.find<AuthController>();

  final RxMap<String, dynamic> profile = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  Future<void> loadProfile(String userId) async {
    try {
      isLoading.value = true;
      final data = await _profileRepo.getProfile(userId);
      profile.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      isSaving.value = true;
      await _profileRepo.updateProfile(_authController.userId, data);
      profile.addAll(data);
      await _authController.refreshProfile();
      AppSnackbar.success('Profile updated');
    } catch (e) {
      AppSnackbar.error('Failed to update profile');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> uploadAvatar(File file) async {
    try {
      isSaving.value = true;
      final url = await _profileRepo.uploadAvatar(_authController.userId, file);
      await _profileRepo.updateProfile(_authController.userId, {'avatar_url': url});
      profile['avatar_url'] = url;
      profile.refresh();
      await _authController.refreshProfile();
      AppSnackbar.success('Avatar updated');
    } catch (e) {
      AppSnackbar.error('Failed to upload avatar');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    try {
      await _profileRepo.updateLocation(lat, lng);
    } catch (e) {
      debugPrint('ProfileController: Failed to update location: $e');
    }
  }
}
