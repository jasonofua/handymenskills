import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/notification_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _controller =
      Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _controller.loadNotifications(refresh: true);
  }

  Future<void> _onRefresh() async {
    await _controller.loadNotifications(refresh: true);
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    final id = notification['id'] as String?;
    if (id != null && notification['is_read'] != true) {
      _controller.markAsRead(id);
    }

    // Navigate based on type and reference
    final type = notification['type'] as String? ?? '';
    final referenceId = notification['reference_id'] as String?;

    if (referenceId == null) return;

    switch (type) {
      case 'booking_request':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_completed':
        context.push(
          AppRoutes.clientBookingDetail.replaceFirst(':id', referenceId),
        );
        break;
      case 'new_message':
        context.push(
          AppRoutes.chatConversation.replaceFirst(':id', referenceId),
        );
        break;
      case 'new_application':
        context.push(
          AppRoutes.clientJobApplications.replaceFirst(':id', referenceId),
        );
        break;
      case 'job_posted':
      case 'job_match':
        context.push(
          AppRoutes.workerJobDetail.replaceFirst(':id', referenceId),
        );
        break;
      case 'new_review':
        context.push(
          AppRoutes.reviews.replaceFirst(':userId', referenceId),
        );
        break;
      case 'payment_received':
      case 'payout_completed':
        context.push(AppRoutes.workerEarnings);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (_controller.unreadCount.value == 0) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: _controller.markAllRead,
              child: const Text('Mark all read'),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value &&
            _controller.notifications.isEmpty) {
          return _buildShimmerList();
        }

        if (_controller.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  subtitle:
                      'You will see updates about bookings, messages, and more here.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm,
            ),
            itemCount: _controller.notifications.length,
            separatorBuilder: (_, __) => const Divider(
              height: AppDimensions.dividerThickness,
              indent: AppDimensions.screenPadding,
              endIndent: AppDimensions.screenPadding,
            ),
            itemBuilder: (context, index) {
              final notification = _controller.notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _onNotificationTap(notification),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      itemCount: 10,
      itemBuilder: (_, __) => AppShimmer.listItem(),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = notification['title'] ?? '';
    final String body = notification['body'] ?? '';
    final String type = notification['type'] ?? '';
    final bool isRead = notification['is_read'] == true;
    final DateTime? createdAt =
        DateTime.tryParse(notification['created_at'] ?? '');

    final iconData = _getNotificationIcon(type);
    final iconColor = _getNotificationColor(type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.listItemPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isRead
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    createdAt != null
                        ? timeago.format(createdAt)
                        : '',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: AppDimensions.sm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today;
      case 'booking_confirmed':
        return Icons.check_circle_outline;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'booking_completed':
        return Icons.task_alt;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'new_application':
        return Icons.person_add_outlined;
      case 'job_posted':
      case 'job_match':
        return Icons.work_outline;
      case 'new_review':
        return Icons.star_outline;
      case 'payment_received':
      case 'payout_completed':
        return Icons.payment;
      case 'verification_approved':
        return Icons.verified_outlined;
      case 'verification_rejected':
        return Icons.gpp_bad_outlined;
      case 'subscription':
        return Icons.card_membership;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_request':
        return AppColors.statusPending;
      case 'booking_confirmed':
        return AppColors.statusConfirmed;
      case 'booking_cancelled':
        return AppColors.statusCancelled;
      case 'booking_completed':
        return AppColors.statusCompleted;
      case 'new_message':
        return AppColors.info;
      case 'new_application':
        return AppColors.primary;
      case 'job_posted':
      case 'job_match':
        return AppColors.secondary;
      case 'new_review':
        return AppColors.ratingStar;
      case 'payment_received':
      case 'payout_completed':
        return AppColors.success;
      case 'verification_approved':
        return AppColors.success;
      case 'verification_rejected':
        return AppColors.error;
      case 'subscription':
        return AppColors.statusEnRoute;
      default:
        return AppColors.textSecondary;
    }
  }
}
