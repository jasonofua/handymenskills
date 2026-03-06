import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/dispute_controller.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class DisputesListScreen extends StatefulWidget {
  const DisputesListScreen({super.key});

  @override
  State<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends State<DisputesListScreen> {
  final _disputeController = Get.find<DisputeController>();

  @override
  void initState() {
    super.initState();
    _disputeController.loadMyDisputes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Disputes'),
      ),
      body: RefreshIndicator(
        onRefresh: _disputeController.loadMyDisputes,
        child: Obx(() {
          if (_disputeController.isLoading.value &&
              _disputeController.disputes.isEmpty) {
            return AppShimmer.list(count: 5);
          }

          final disputes = _disputeController.disputes;

          if (disputes.isEmpty) {
            return const AppEmptyState(
              icon: Icons.gavel_outlined,
              title: 'No disputes',
              subtitle: 'You have not opened any disputes',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            itemCount: disputes.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, index) {
              return _DisputeCard(
                dispute: disputes[index],
                onTap: () {
                  final id = disputes[index]['id'] as String;
                  context.push('/dispute/$id');
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final VoidCallback onTap;

  const _DisputeCard({
    required this.dispute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = dispute['status'] ?? 'open';
    final reason = dispute['reason'] ?? '';
    final createdAt = DateTime.tryParse(dispute['created_at'] ?? '');
    final booking =
        dispute['bookings'] as Map<String, dynamic>? ?? {};
    final job = booking['jobs'] as Map<String, dynamic>? ?? {};
    final jobTitle = job['title'] ?? 'Booking Dispute';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jobTitle as String,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _buildStatusBadge(status as String),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            reason as String,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (createdAt != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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

    final label = status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

    return AppStatusBadge(label: label, color: color);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
