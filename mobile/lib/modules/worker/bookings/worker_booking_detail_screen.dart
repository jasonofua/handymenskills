import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/booking_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_text_field.dart';

class WorkerBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const WorkerBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<WorkerBookingDetailScreen> createState() =>
      _WorkerBookingDetailScreenState();
}

class _WorkerBookingDetailScreenState extends State<WorkerBookingDetailScreen> {
  final _bookingController = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookingController.loadBookingDetail(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Obx(() {
        if (_bookingController.isLoading.value &&
            _bookingController.currentBooking.isEmpty) {
          return AppShimmer.list(count: 6);
        }

        final booking = _bookingController.currentBooking;

        if (booking.isEmpty) {
          return AppErrorWidget(
            message: 'Booking not found',
            onRetry: () =>
                _bookingController.loadBookingDetail(widget.bookingId),
          );
        }

        return _buildContent(booking);
      }),
      bottomNavigationBar: Obx(() {
        final booking = _bookingController.currentBooking;
        if (booking.isEmpty) return const SizedBox.shrink();
        return _buildBottomActions(booking);
      }),
    );
  }

  Widget _buildContent(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final job = booking['job'] as Map<String, dynamic>?;
    final client = booking['client'] as Map<String, dynamic>?;
    final agreedPrice = (booking['agreed_price'] ?? 0.0).toDouble();
    final scheduledDate = DateTime.tryParse(booking['scheduled_date'] ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status timeline
          _buildTimeline(status),
          const SizedBox(height: AppDimensions.lg),

          // Job info
          if (job != null) ...[
            const Text('Job Information', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] ?? 'Job',
                    style: AppTextStyles.labelLarge,
                  ),
                  if (job['description'] != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      job['description'],
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.sm),
                  const Divider(),
                  const SizedBox(height: AppDimensions.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Agreed Price', style: AppTextStyles.bodySmall),
                      Text(
                        '${AppConstants.currencySymbol}${agreedPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                  if (scheduledDate != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scheduled Date',
                            style: AppTextStyles.bodySmall),
                        Text(
                          _formatDate(scheduledDate),
                          style: AppTextStyles.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Client info
          if (client != null) ...[
            const Text('Client', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.sm),
            AppCard(
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: client['avatar_url'],
                    name: client['full_name'],
                    size: AppDimensions.avatarLg,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['full_name'] ?? 'Client',
                          style: AppTextStyles.labelLarge,
                        ),
                        if (client['phone'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            client['phone'],
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate to chat with client
                      final clientId = client['id'] as String?;
                      if (clientId != null) {
                        context.push(
                          AppRoutes.chatConversation
                              .replaceFirst(':id', clientId),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_outlined,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],

          // Extra space for bottom actions
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      _TimelineStep(
        label: 'Pending',
        status: 'pending',
        icon: Icons.hourglass_empty,
      ),
      _TimelineStep(
        label: 'Confirmed',
        status: 'confirmed',
        icon: Icons.check_circle_outline,
      ),
      _TimelineStep(
        label: 'En Route',
        status: 'worker_en_route',
        icon: Icons.directions_car_outlined,
      ),
      _TimelineStep(
        label: 'In Progress',
        status: 'in_progress',
        icon: Icons.construction,
      ),
      _TimelineStep(
        label: 'Completed',
        status: 'completed',
        icon: Icons.done_all,
      ),
    ];

    final currentIndex =
        steps.indexWhere((s) => s.status == currentStatus);
    final isCancelled = currentStatus == 'cancelled';
    final isDisputed = currentStatus == 'disputed';

    if (isCancelled || isDisputed) {
      return AppCard(
        color: (isCancelled ? AppColors.error : AppColors.warning)
            .withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(
              isCancelled ? Icons.cancel_outlined : Icons.gavel,
              color: isCancelled ? AppColors.error : AppColors.warning,
              size: 32,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCancelled ? 'Booking Cancelled' : 'Booking Disputed',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isCancelled ? AppColors.error : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCancelled
                        ? 'This booking has been cancelled'
                        : 'A dispute has been raised for this booking',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Status', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: 18,
                        color: isCompleted
                            ? AppColors.white
                            : AppColors.textHint,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 24,
                        color: index < currentIndex
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: AppDimensions.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    step.label,
                    style: isCurrent
                        ? AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          )
                        : isCompleted
                            ? AppTextStyles.labelMedium
                            : AppTextStyles.bodySmall,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> booking) {
    final status = booking['status'] ?? '';

    // Determine which action buttons to show
    Widget? primaryButton;
    bool showCancelButton = false;

    switch (status) {
      case 'confirmed':
        primaryButton = _buildActionButton(
          label: 'On My Way',
          icon: Icons.directions_car_outlined,
          color: AppColors.statusEnRoute,
          onPressed: () => _processAction('start', 'worker_en_route'),
        );
        showCancelButton = true;
        break;
      case 'worker_en_route':
        primaryButton = _buildActionButton(
          label: 'Start Job',
          icon: Icons.play_arrow,
          color: AppColors.statusInProgress,
          onPressed: () => _processAction('start', 'in_progress'),
        );
        showCancelButton = true;
        break;
      case 'in_progress':
        primaryButton = _buildActionButton(
          label: 'Mark Complete',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          onPressed: () => _processAction('complete', 'completed'),
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.md,
        top: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: _bookingController.isProcessing.value
                    ? const Center(child: CircularProgressIndicator())
                    : primaryButton,
              )),
          if (showCancelButton) ...[
            const SizedBox(height: AppDimensions.sm),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonSmallHeight,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
      ),
    );
  }

  Future<void> _processAction(String action, String targetStatus) async {
    // For 'worker_en_route' and 'in_progress' transitions, use 'start' action
    // For 'completed' transition, use 'complete' action
    await _bookingController.processAction(action, widget.bookingId);
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking? Please provide a reason:',
            ),
            const SizedBox(height: AppDimensions.md),
            AppTextField(
              hint: 'Reason for cancellation',
              controller: reasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _bookingController.processAction(
                'cancel',
                widget.bookingId,
                extraData: {
                  'cancellation_reason': reasonController.text.trim(),
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TimelineStep {
  final String label;
  final String status;
  final IconData icon;

  const _TimelineStep({
    required this.label,
    required this.status,
    required this.icon,
  });
}
