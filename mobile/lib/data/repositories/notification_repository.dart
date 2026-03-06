import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class NotificationRepository {
  /// Fetches paginated notifications for the current user.
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw Exception(
          'Failed to mark notification $notificationId as read: $e');
    }
  }

  /// Marks all unread notifications as read for the current user.
  Future<void> markAllRead() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Returns the count of unread notifications for the current user.
  Future<int> getUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }
}
