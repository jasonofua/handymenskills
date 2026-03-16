import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/dispute_controller.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({
    super.key,
    required this.disputeId,
  });

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final _disputeController = Get.find<DisputeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disputeController.loadDisputeDetail(widget.disputeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dispute Details', style: AppTextStyles.h4),
      ),
      body: Obx(() {
        if (_disputeController.isLoading.value &&
            _disputeController.currentDispute.isEmpty) {
          return AppShimmer.list(count: 4);
        }

        final dispute = _disputeController.currentDispute;
        if (dispute.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  'Dispute not found',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              _disputeController.loadDisputeDetail(widget.disputeId),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              // Status banner
              _buildStatusBanner(dispute),
              const SizedBox(height: AppDimensions.md),

              // Dispute ID + date + status
              _buildDisputeHeader(dispute),
              const SizedBox(height: AppDimensions.md),

              // Original Job Info
              _buildBookingCard(dispute),
              const SizedBox(height: AppDimensions.md),

              // Reason for Dispute
              _buildReasonCard(dispute),

              // Evidence images
              if (dispute['evidence'] != null &&
                  (dispute['evidence'] as List).isNotEmpty) ...[
                const SizedBox(height: AppDimensions.md),
                _buildEvidenceSection(dispute),
              ],

              // Resolution
              if (dispute['resolution'] != null) ...[
                const SizedBox(height: AppDimensions.md),
                _buildResolutionCard(dispute),
              ],

              const SizedBox(height: AppDimensions.md),

              // Resolution Progress timeline
              _buildProgressTimeline(dispute),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? 'open';
    final bannerData = _getStatusBannerData(status);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: bannerData.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: bannerData.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bannerData.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              bannerData.icon,
              color: bannerData.color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerData.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: bannerData.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bannerData.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeHeader(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? 'open';
    final createdAt = DateTime.tryParse(dispute['created_at'] ?? '');
    final disputeId = dispute['id'] as String? ?? '';
    final shortId = disputeId.length > 8 ? disputeId.substring(0, 8) : disputeId;

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISPUTE ID',
                    style: AppTextStyles.sectionHeader.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${shortId.toUpperCase()}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              _buildDisputeStatusBadge(status),
            ],
          ),
          if (createdAt != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Divider(color: AppColors.border.withValues(alpha: 0.5)),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filed on ${_formatDate(createdAt)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> dispute) {
    final booking =
        dispute['bookings'] as Map<String, dynamic>? ?? {};
    final job = booking['jobs'] as Map<String, dynamic>? ?? {};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORIGINAL JOB INFO',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: AppDimensions.md),
          if (job['title'] != null)
            _buildInfoRow(
              Icons.work_outline,
              'Job Title',
              job['title'] as String,
            ),
          if (booking['booking_number'] != null) ...[
            const SizedBox(height: AppDimensions.sm),
            _buildInfoRow(
              Icons.confirmation_number_outlined,
              'Booking #',
              booking['booking_number'].toString(),
            ),
          ],
          if (booking['agreed_price'] != null) ...[
            const SizedBox(height: AppDimensions.sm),
            _buildInfoRow(
              Icons.payments_outlined,
              'Price',
              '\u20A6${(booking['agreed_price'] as num).toStringAsFixed(0)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium,
        ),
      ],
    );
  }

  Widget _buildReasonCard(Map<String, dynamic> dispute) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REASON FOR DISPUTE',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              dispute['reason'] ?? 'No reason provided',
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(Map<String, dynamic> dispute) {
    final evidence = List<String>.from(dispute['evidence'] as List);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'EVIDENCE',
            style: AppTextStyles.sectionHeader,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: evidence.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppDimensions.sm),
            itemBuilder: (_, index) {
              return ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                child: Image.network(
                  evidence[index],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textHint),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionCard(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? '';

    String resolutionTitle = 'Resolution';
    if (status.contains('client_favor')) {
      resolutionTitle = 'Resolved in client\'s favor';
    } else if (status.contains('worker_favor')) {
      resolutionTitle = 'Resolved in worker\'s favor';
    } else if (status.contains('mutual')) {
      resolutionTitle = 'Resolved by mutual agreement';
    }

    return AppCard(
      color: AppColors.success.withValues(alpha: 0.04),
      borderColor: AppColors.success.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  resolutionTitle,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          if (dispute['resolution'] != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              dispute['resolution'] as String,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? 'open';
    final createdAt = DateTime.tryParse(dispute['created_at'] ?? '');
    final resolvedAt = DateTime.tryParse(dispute['resolved_at'] ?? '');

    // Determine which steps are completed
    final isOpen = true; // Always at least filed
    final isUnderReview =
        status == 'under_review' || status.contains('resolved') || status == 'closed';
    final isResolved = status.contains('resolved') || status == 'closed';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESOLUTION PROGRESS',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Step 1: Filed
          _TimelineStep(
            title: 'Dispute Filed',
            subtitle: createdAt != null ? _formatDate(createdAt) : null,
            isCompleted: isOpen,
            isActive: !isUnderReview && !isResolved,
            isLast: false,
          ),

          // Step 2: Under Review
          _TimelineStep(
            title: 'Under Review',
            subtitle: isUnderReview ? 'Being reviewed by our team' : 'Pending',
            isCompleted: isUnderReview,
            isActive: isUnderReview && !isResolved,
            isLast: false,
          ),

          // Step 3: Resolution
          _TimelineStep(
            title: 'Resolution',
            subtitle: resolvedAt != null
                ? 'Resolved on ${_formatDate(resolvedAt)}'
                : isResolved
                    ? 'Dispute resolved'
                    : 'Awaiting resolution',
            isCompleted: isResolved,
            isActive: isResolved,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = AppColors.warning;
        break;
      case 'under_review':
        color = AppColors.info;
        break;
      case 'resolved_client_favor':
      case 'resolved_worker_favor':
      case 'resolved_mutual':
        color = AppColors.success;
        break;
      case 'closed':
        color = AppColors.textHint;
        break;
      default:
        color = AppColors.textHint;
    }

    return AppStatusBadge(
      label: _formatStatus(status),
      color: color,
    );
  }

  _StatusBannerData _getStatusBannerData(String status) {
    switch (status) {
      case 'open':
        return _StatusBannerData(
          icon: Icons.pending_outlined,
          title: 'Dispute Pending',
          subtitle: 'Your dispute has been filed and is awaiting review.',
          color: AppColors.warning,
        );
      case 'under_review':
        return _StatusBannerData(
          icon: Icons.policy_outlined,
          title: 'Under Review',
          subtitle: 'Our team is actively reviewing your dispute.',
          color: AppColors.info,
        );
      case 'resolved_client_favor':
      case 'resolved_worker_favor':
      case 'resolved_mutual':
        return _StatusBannerData(
          icon: Icons.check_circle_outline,
          title: 'Dispute Resolved',
          subtitle: 'This dispute has been resolved.',
          color: AppColors.success,
        );
      case 'closed':
        return _StatusBannerData(
          icon: Icons.cancel_outlined,
          title: 'Dispute Closed',
          subtitle: 'This dispute has been closed.',
          color: AppColors.textHint,
        );
      default:
        return _StatusBannerData(
          icon: Icons.help_outline,
          title: 'Status Unknown',
          subtitle: 'Please contact support for more information.',
          color: AppColors.textHint,
        );
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatusBannerData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StatusBannerData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isCompleted
        ? AppColors.primary
        : AppColors.textHint.withValues(alpha: 0.3);
    final lineColor = isCompleted
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.textHint.withValues(alpha: 0.15);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: isActive ? 20 : 16,
                  height: isActive ? 20 : 16,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? dotColor
                        : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: isActive ? 3 : 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: isCompleted && !isActive
                      ? const Icon(
                          Icons.check,
                          size: 10,
                          color: AppColors.white,
                        )
                      : null,
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppDimensions.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
