import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme/app_colors.dart';

class AppSnackbar {
  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Icon icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.overlayContext == null) return;
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: AppColors.white,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      icon: icon,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void success(String message, {String? title}) {
    _show(
      title: title ?? 'Success',
      message: message,
      backgroundColor: AppColors.success,
      icon: const Icon(Icons.check_circle, color: AppColors.white),
    );
  }

  static void error(String message, {String? title}) {
    _show(
      title: title ?? 'Error',
      message: message,
      backgroundColor: AppColors.error,
      icon: const Icon(Icons.error, color: AppColors.white),
      duration: const Duration(seconds: 4),
    );
  }

  static void info(String message, {String? title}) {
    _show(
      title: title ?? 'Info',
      message: message,
      backgroundColor: AppColors.info,
      icon: const Icon(Icons.info, color: AppColors.white),
    );
  }

  static void warning(String message, {String? title}) {
    _show(
      title: title ?? 'Warning',
      message: message,
      backgroundColor: AppColors.warning,
      icon: const Icon(Icons.warning, color: AppColors.white),
    );
  }
}
