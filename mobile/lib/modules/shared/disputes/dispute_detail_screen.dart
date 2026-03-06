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
    _disputeController.loadDisputeDetail(widget.disputeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Details'),
      ),
      body: Obx(() {
        if (_disputeController.isLoading.value &&
            _disputeController.currentDispute.isEmpty) {
          return AppShimmer.list(count: 4);
        }

        final dispute = _disputeController.currentDispute;
        if (dispute.isEmpty) {
          return const Center(child: Text('Dispute not found'));
        }

        return RefreshIndicator(
          onRefresh: () =>
              _disputeController.loadDisputeDetail(widget.disputeId),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildStatusCard(dispute),
              const SizedBox(height: AppDimensions.lg),
              _buildReasonCard(dispute),
              if (dispute['resolution'] != null) ...[
                const SizedBox(height: AppDimensions.lg),
                _buildResolutionCard(dispute),
              ],
              if (dispute['evidence'] != null &&
                  (dispute['evidence'] as List).isNotEmpty) ...[
                const SizedBox(height: AppDimensions.lg),
                _buildEvidenceCard(dispute),
              ],
              const SizedBox(height: AppDimensions.lg),
              _buildBookingCard(dispute),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? 'open';
    final createdAt = DateTime.tryParse(dispute['created_at'] ?? '');
    final resolvedAt = DateTime.tryParse(dispute['resolved_at'] ?? '');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: AppTextStyles.labelLarge),
              _buildDisputeStatusBadge(status),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          if (createdAt != null)
            _buildInfoRow(
                'Opened', _formatDate(createdAt)),
          if (resolvedAt != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow(
                'Resolved', _formatDate(resolvedAt)),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonCard(Map<String, dynamic> dispute) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reason', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.sm),
          Text(
            dispute['reason'] ?? 'No reason provided',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(Map<String, dynamic> dispute) {
    final status = dispute['status'] ?? '';

    return AppCard(
      color: AppColors.success.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 20),
              const SizedBox(width: AppDimensions.sm),
              Text('Resolution', style: AppTextStyles.h4),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          if (status.contains('client_favor'))
            Text('Resolved in client\'s favor',
                style: AppTextStyles.labelMedium)
          else if (status.contains('worker_favor'))
            Text('Resolved in worker\'s favor',
                style: AppTextStyles.labelMedium)
          else if (status.contains('mutual'))
            Text('Resolved by mutual agreement',
                style: AppTextStyles.labelMedium),
          if (dispute['resolution'] != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              dispute['resolution'] as String,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> dispute) {
    final evidence = List<String>.from(dispute['evidence'] as List);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidence', style: AppTextStyles.h4),
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
                    BorderRadius.circular(AppDimensions.radiusSm),
                child: Image.network(
                  evidence[index],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 120,
                    color: AppColors.background,
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

  Widget _buildBookingCard(Map<String, dynamic> dispute) {
    final booking =
        dispute['bookings'] as Map<String, dynamic>? ?? {};
    final job = booking['jobs'] as Map<String, dynamic>? ?? {};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Related Booking', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.md),
          if (job['title'] != null)
            _buildInfoRow('Job', job['title'] as String),
          if (booking['booking_number'] != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow(
                'Booking #', booking['booking_number'].toString()),
          ],
          if (booking['agreed_price'] != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Amount',
                '₦${(booking['agreed_price'] as num).toStringAsFixed(0)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.labelMedium),
      ],
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
