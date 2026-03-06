import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/booking_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_snackbar.dart';

class ClientBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const ClientBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<ClientBookingDetailScreen> createState() =>
      _ClientBookingDetailScreenState();
}

class _ClientBookingDetailScreenState extends State<ClientBookingDetailScreen> {
  final _bookingController = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    _bookingController.loadBookingDetail(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Obx(() {
        if (_bookingController.isLoading.value) {
          return _buildLoadingState();
        }

        final booking = _bookingController.currentBooking;
        if (booking.isEmpty) {
          return const AppEmptyState(
            icon: Icons.error_outline,
            title: 'Booking not found',
            subtitle: 'This booking may have been removed.',
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              _bookingController.loadBookingDetail(widget.bookingId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTimeline(booking),
                const SizedBox(height: AppDimensions.md),
                _buildWorkerInfoCard(booking),
                const SizedBox(height: AppDimensions.md),
                _buildJobInfoSection(booking),
                const SizedBox(height: AppDimensions.md),
                _buildBookingDetails(booking),
                const SizedBox(height: AppDimensions.md),
                _buildActionButtons(booking),
                const SizedBox(height: AppDimensions.lg),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        children: [
          AppShimmer(height: 200, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 120, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 150, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 80, borderRadius: AppDimensions.cardRadius),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';

    final allStatuses = [
      _TimelineStep('Pending', 'pending', Icons.hourglass_empty),
      _TimelineStep('Confirmed', 'confirmed', Icons.check_circle_outline),
      _TimelineStep('Worker En Route', 'worker_en_route', Icons.directions_car),
      _TimelineStep('In Progress', 'in_progress', Icons.engineering),
      _TimelineStep('Completed', 'completed', Icons.done_all),
      _TimelineStep('Confirmed & Paid', 'client_confirmed', Icons.payment),
    ];

    final statusOrder = [
      'pending', 'confirmed', 'worker_en_route',
      'in_progress', 'completed', 'client_confirmed',
    ];

    final currentIndex = statusOrder.indexOf(status);
    final isCancelledOrDisputed = status == 'cancelled' || status == 'disputed';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status', style: AppTextStyles.labelLarge),
              AppStatusBadge.booking(status),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          if (isCancelledOrDisputed)
            _buildCancelledState(status)
          else
            ...allStatuses.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == allStatuses.length - 1;

              return _buildTimelineItem(
                step: step,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: isLast,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCancelledState(String status) {
    final isCancelled = status == 'cancelled';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isCancelled ? AppColors.error : AppColors.warning)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled ? Icons.cancel : Icons.gavel,
            color: isCancelled ? AppColors.error : AppColors.warning,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCancelled ? 'Booking Cancelled' : 'Under Dispute',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isCancelled ? AppColors.error : AppColors.warning,
                ),
              ),
              Text(
                isCancelled
                    ? 'This booking has been cancelled.'
                    : 'This booking is under dispute resolution.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required _TimelineStep step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isCompleted ? AppColors.primary : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: Icon(
                step.icon,
                size: 14,
                color: isCompleted ? AppColors.white : AppColors.textHint,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.md),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            step.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerInfoCard(Map<String, dynamic> booking) {
    final workerProfile = booking['profiles!bookings_worker_id_fkey']
        as Map<String, dynamic>?;
    final name = workerProfile?['full_name']?.toString() ?? 'Worker';
    final avatarUrl = workerProfile?['avatar_url']?.toString();
    final phone = workerProfile?['phone']?.toString();
    final workerId = booking['worker_id']?.toString() ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Worker', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          InkWell(
            onTap: () {
              if (workerId.isNotEmpty) {
                context.push('/client/workers/$workerId');
              }
            },
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  size: AppDimensions.avatarLg,
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.labelLarge),
                      if (phone != null) ...[
                        const SizedBox(height: 2),
                        Text(phone, style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoSection(Map<String, dynamic> booking) {
    final jobData = booking['jobs'] as Map<String, dynamic>?;
    if (jobData == null) return const SizedBox.shrink();

    final title = jobData['title']?.toString() ?? 'Job';
    final description = jobData['description']?.toString() ?? '';
    final category = jobData['categories']?['name']?.toString() ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Job Details', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Text(title, style: AppTextStyles.h4),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(category, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingDetails(Map<String, dynamic> booking) {
    final agreedPrice = booking['agreed_price'];
    final scheduledDate = booking['scheduled_date']?.toString();
    final createdAt = booking['created_at']?.toString() ?? '';
    final completedAt = booking['completed_at']?.toString();
    final notes = booking['notes']?.toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Info', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          if (agreedPrice != null)
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Agreed Price',
              value: '${AppConstants.currencySymbol}${agreedPrice is num ? agreedPrice.toStringAsFixed(0) : agreedPrice}',
              valueStyle: AppTextStyles.priceSmall,
            ),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Created',
            value: _formatDateTime(createdAt),
          ),
          if (scheduledDate != null)
            _InfoRow(
              icon: Icons.event,
              label: 'Scheduled',
              value: _formatDateTime(scheduledDate),
            ),
          if (completedAt != null)
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              value: _formatDateTime(completedAt),
            ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            const Text('Notes', style: AppTextStyles.labelMedium),
            const SizedBox(height: 4),
            Text(notes, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final bookingId = widget.bookingId;
    final workerId = booking['worker_id']?.toString() ?? '';
    final hasReview = (booking['reviews'] as List?)?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action based on status
        if (status == 'completed')
          Obx(() => SizedBox(
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _bookingController.isProcessing.value
                  ? null
                  : () => _confirmAndPay(bookingId),
              icon: _bookingController.isProcessing.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    )
                  : const Icon(Icons.payment),
              label: const Text('Confirm & Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
            ),
          )),

        if (status == 'client_confirmed' && !hasReview)
          SizedBox(
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/reviews/write/$bookingId');
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Write Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
            ),
          ),

        // Chat with worker - always available unless cancelled
        if (status != 'cancelled' && status != 'disputed') ...[
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: AppDimensions.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.chat),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Chat with Worker'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
            ),
          ),
        ],

        // Cancel booking - only for pending and confirmed
        if (status == 'pending' || status == 'confirmed') ...[
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: AppDimensions.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(bookingId),
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
            ),
          ),
        ],

        // Dispute - for completed or in_progress
        if (status == 'completed' || status == 'in_progress') ...[
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: AppDimensions.buttonSmallHeight,
            child: TextButton.icon(
              onPressed: () {
                context.push('/dispute/create/$bookingId');
              },
              icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
              label: const Text(
                'Report a Problem',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmAndPay(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm & Pay'),
        content: const Text(
          'By confirming, you acknowledge that the work has been '
          'completed satisfactorily. Payment will be released to the worker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm & Pay', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _bookingController.processAction(
        'client_confirm',
        bookingId,
      );
      if (success && mounted) {
        AppSnackbar.success('Payment confirmed successfully');
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'This action may not be reversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Booking', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookingController.processAction('cancel', bookingId);
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
    } catch (_) {
      return dateStr;
    }
  }
}

class _TimelineStep {
  final String label;
  final String status;
  final IconData icon;

  const _TimelineStep(this.label, this.status, this.icon);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodySmall),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? AppTextStyles.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
