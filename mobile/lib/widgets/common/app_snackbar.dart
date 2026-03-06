import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';

class AppSnackbar {
  static void success(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Success',
      message,
      backgroundColor: AppColors.success,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void error(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Error',
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void info(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Info',
      message,
      backgroundColor: AppColors.info,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void warning(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Warning',
      message,
      backgroundColor: AppColors.warning,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning, color: AppColors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
