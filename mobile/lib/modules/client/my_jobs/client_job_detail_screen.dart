import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../controllers/application_controller.dart';
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

class ClientJobDetailScreen extends StatefulWidget {
  final String jobId;

  const ClientJobDetailScreen({super.key, required this.jobId});

  @override
  State<ClientJobDetailScreen> createState() => _ClientJobDetailScreenState();
}

class _ClientJobDetailScreenState extends State<ClientJobDetailScreen> {
  final _jobController = Get.find<JobController>();
  final _applicationController = Get.find<ApplicationController>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _jobController.loadJobDetail(widget.jobId),
      _applicationController.loadJobApplications(widget.jobId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          Obx(() {
            final job = _jobController.currentJob;
            final status = job['status']?.toString();
            if (status == 'open' || status == 'draft') {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Job'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete Job', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (_jobController.isLoadingDetail.value) {
          return _buildLoadingState();
        }

        final job = _jobController.currentJob;
        if (job.isEmpty) {
          return const AppEmptyState(
            icon: Icons.error_outline,
            title: 'Job not found',
            subtitle: 'This job may have been deleted.',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobHeader(job),
                const SizedBox(height: AppDimensions.md),
                _buildJobDescription(job),
                const SizedBox(height: AppDimensions.md),
                _buildJobDetails(job),
                const SizedBox(height: AppDimensions.md),
                _buildLocationSection(job),
                const SizedBox(height: AppDimensions.lg),
                _buildApplicationsSection(),
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
          AppShimmer(height: 100, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 150, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 100, borderRadius: AppDimensions.cardRadius),
          const SizedBox(height: AppDimensions.md),
          AppShimmer(height: 200, borderRadius: AppDimensions.cardRadius),
        ],
      ),
    );
  }

  Widget _buildJobHeader(Map<String, dynamic> job) {
    final title = job['title']?.toString() ?? 'Untitled Job';
    final status = job['status']?.toString() ?? 'open';
    final urgency = job['urgency']?.toString() ?? 'normal';
    final category = job['categories']?['name']?.toString() ?? '';
    final budgetMin = job['budget_min'];
    final budgetMax = job['budget_max'];
    final budgetType = job['budget_type']?.toString() ?? 'fixed';

    String budget = '';
    if (budgetMin != null && budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_formatNum(budgetMin)} - ${AppConstants.currencySymbol}${_formatNum(budgetMax)}';
    } else if (budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_formatNum(budgetMax)}';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatusBadge.job(status),
              const SizedBox(width: 8),
              AppStatusBadge.urgency(urgency),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(title, style: AppTextStyles.h3),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(category, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.md),
          if (budget.isNotEmpty)
            Row(
              children: [
                Text(budget, style: AppTextStyles.price),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    budgetType[0].toUpperCase() + budgetType.substring(1),
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildJobDescription(Map<String, dynamic> job) {
    final description = job['description']?.toString() ?? '';
    final skills = job['required_skills'] as List? ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Text(description, style: AppTextStyles.bodyMedium),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            const Text('Required Skills', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map<Widget>((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  s.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobDetails(Map<String, dynamic> job) {
    final createdAt = job['created_at']?.toString() ?? '';
    final startDate = job['start_date']?.toString();
    final endDate = job['end_date']?.toString();
    final isRemote = job['is_remote'] == true;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Posted',
            value: _formatDateTime(createdAt),
          ),
          if (startDate != null)
            _DetailRow(
              icon: Icons.play_arrow,
              label: 'Start',
              value: _formatDateTime(startDate),
            ),
          if (endDate != null)
            _DetailRow(
              icon: Icons.stop,
              label: 'End',
              value: _formatDateTime(endDate),
            ),
          _DetailRow(
            icon: isRemote ? Icons.cloud_outlined : Icons.location_on_outlined,
            label: 'Type',
            value: isRemote ? 'Remote' : 'On-site',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Map<String, dynamic> job) {
    final isRemote = job['is_remote'] == true;
    if (isRemote) return const SizedBox.shrink();

    final address = job['address']?.toString() ?? '';
    final city = job['city']?.toString() ?? '';
    final state = job['state']?.toString() ?? '';

    final location = [address, city, state].where((s) => s.isNotEmpty).join(', ');
    if (location.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Location', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(location, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final count = _applicationController.jobApplications.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applications ($count)',
                style: AppTextStyles.h4,
              ),
            ],
          );
        }),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          if (_applicationController.isLoading.value) {
            return Column(
              children: List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: AppShimmer.listItem(),
              )),
            );
          }

          final applications = _applicationController.jobApplications;

          if (applications.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'No applications yet',
              subtitle: 'Workers will apply to your job soon.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: applications.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (_, index) {
              final application = applications[index];
              return _ApplicationCard(
                application: application,
                onAccept: () => _handleAccept(application),
                onReject: () => _handleReject(application),
                onViewProfile: () {
                  final workerId = application['worker_id']?.toString() ??
                      application['profiles']?['id']?.toString() ?? '';
                  if (workerId.isNotEmpty) {
                    context.push('/client/workers/$workerId');
                  }
                },
              );
            },
          );
        }),
      ],
    );
  }

  Future<void> _handleAccept(Map<String, dynamic> application) async {
    final applicationId = application['id']?.toString() ?? '';
    if (applicationId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Application'),
        content: const Text(
          'Are you sure you want to accept this application? '
          'A booking will be created with this worker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Accept', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _applicationController.acceptApplication(applicationId);
      await _loadData();
    }
  }

  Future<void> _handleReject(Map<String, dynamic> application) async {
    final applicationId = application['id']?.toString() ?? '';
    if (applicationId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text('Are you sure you want to reject this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _applicationController.rejectApplication(applicationId);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        AppSnackbar.info('Edit job coming soon');
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text(
          'Are you sure you want to delete this job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _jobController.deleteJob(widget.jobId);
      if (mounted) context.pop();
    }
  }

  String _formatNum(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
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
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _ApplicationCard({
    required this.application,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final status = application['status']?.toString() ?? 'pending';
    final profile = application['profiles'] as Map<String, dynamic>?;
    final workerProfile = application['worker_profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name']?.toString() ?? 'Worker';
    final avatarUrl = profile?['avatar_url']?.toString();
    final rating = workerProfile?['average_rating'];
    final proposedPrice = application['proposed_price'];
    final coverLetter = application['cover_letter']?.toString() ?? '';
    final estimatedDuration = application['estimated_duration']?.toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onViewProfile,
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  size: AppDimensions.avatarMd,
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppStatusBadge.application(status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.ratingStar),
                            const SizedBox(width: 2),
                            Text(
                              (rating is num ? rating.toStringAsFixed(1) : rating.toString()),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              if (proposedPrice != null) ...[
                Text(
                  '${AppConstants.currencySymbol}${proposedPrice is num ? proposedPrice.toStringAsFixed(0) : proposedPrice}',
                  style: AppTextStyles.priceSmall,
                ),
                const SizedBox(width: AppDimensions.md),
              ],
              if (estimatedDuration != null)
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(estimatedDuration, style: AppTextStyles.bodySmall),
                  ],
                ),
            ],
          ),
          if (coverLetter.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              coverLetter,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
