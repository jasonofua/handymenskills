import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/realtime_service.dart';

class NotificationController extends GetxController {
  final _notificationRepo = Get.find<NotificationRepository>();
  final _realtimeService = Get.find<RealtimeService>();

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  RealtimeChannel? _notificationChannel;

  @override
  void onInit() {
    super.onInit();
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      loadNotifications();
      _subscribeToNotifications(userId);
    }
  }

  @override
  void onClose() {
    if (_notificationChannel != null) {
      _realtimeService.unsubscribe(_notificationChannel!);
    }
    super.onClose();
  }

  void _subscribeToNotifications(String userId) {
    _notificationChannel = _realtimeService.subscribeToNotifications(
      userId,
      (newNotification) {
        notifications.insert(0, newNotification);
        unreadCount.value++;
      },
    );
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      isLoading.value = true;
      final offset = refresh ? 0 : notifications.length;
      final data = await _notificationRepo.getNotifications(
        limit: 20,
        offset: refresh ? 0 : offset,
      );
      if (refresh) {
        notifications.assignAll(data);
      } else {
        notifications.addAll(data);
      }
      unreadCount.value = await _notificationRepo.getUnreadCount();
    } catch (e) {
      debugPrint('NotificationController: Failed to load notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepo.markAsRead(notificationId);
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index] = {...notifications[index], 'is_read': true};
        notifications.refresh();
        if (unreadCount.value > 0) unreadCount.value--;
      }
    } catch (e) {
      debugPrint('NotificationController: Failed to mark as read: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await _notificationRepo.markAllRead();
      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = {...notifications[i], 'is_read': true};
      }
      notifications.refresh();
      unreadCount.value = 0;
    } catch (e) {
      debugPrint('NotificationController: Failed to mark all read: $e');
    }
  }
}
