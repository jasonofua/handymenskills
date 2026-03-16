import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/application_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final _applicationController = Get.find<ApplicationController>();
  final _selectedTab = 0.obs;

  final _tabLabels = const ['All', 'Pending', 'Accepted', 'Rejected'];
  final _statusFilters = const [null, 'pending', 'accepted', 'rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  void _onTabChanged(int index) {
    _selectedTab.value = index;
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final status = _statusFilters[_selectedTab.value];
    await _applicationController.loadMyApplications(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // -- Filter tabs as pill buttons --
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: AppDimensions.sm,
            ),
            child: Obx(() => Row(
                  children: List.generate(_tabLabels.length, (index) {
                    final isSelected = _selectedTab.value == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabChanged(index),
                        child: Container(
                          margin: EdgeInsets.only(
                            right:
                                index < _tabLabels.length - 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _tabLabels[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                )),
          ),

          const SizedBox(height: AppDimensions.xs),

          // -- Application list --
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadApplications,
              child: Obx(() {
                final applications = _applicationController.myApplications;
                final isLoading = _applicationController.isLoading.value;
                final tabIndex = _selectedTab.value;

                if (isLoading && applications.isEmpty) {
                  return AppShimmer.list(count: 5);
                }

                if (!isLoading && applications.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No applications',
                    subtitle: _getEmptySubtitle(tabIndex),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.md),
                      child: _ApplicationCard(
                        application: application,
                        onTap: () {
                          final jobId = application['job_id'] as String?;
                          if (jobId != null) {
                            context.push(
                              AppRoutes.workerJobDetail
                                  .replaceFirst(':id', jobId),
                            );
                          }
                        },
                        onWithdraw: application['status'] == 'pending'
                            ? () => _showWithdrawDialog(application)
                            : null,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptySubtitle(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'No pending applications';
      case 2:
        return 'No accepted applications yet';
      case 3:
        return 'No rejected applications';
      default:
        return 'Start applying to jobs to see your applications here';
    }
  }

  void _showWithdrawDialog(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text(
          'Are you sure you want to withdraw this application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applicationController.withdrawApplication(
                application['id'] as String,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onTap;
  final VoidCallback? onWithdraw;

  const _ApplicationCard({
    required this.application,
    required this.onTap,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final jobTitle = application['job']?['title'] ?? 'Job';
    final jobCategory = application['job']?['category']?['name'] as String?;
    final proposedPrice = (application['proposed_price'] ?? 0.0).toDouble();
    final status = application['status'] ?? 'pending';
    final createdAt = DateTime.tryParse(application['created_at'] ?? '');
    final estimatedDuration = application['estimated_duration'] as String?;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Title row with status badge --
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: AppTextStyles.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              AppStatusBadge.application(status),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // -- Category chip --
          if (jobCategory != null && jobCategory.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                jobCategory,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],

          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimensions.sm),

          // -- Price + Duration + Date row --
          Row(
            children: [
              // Proposed price
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                '${AppConstants.currencySymbol}${proposedPrice.toStringAsFixed(0)}',
                style: AppTextStyles.priceSmall,
              ),
              if (estimatedDuration != null &&
                  estimatedDuration.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.md),
                Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(estimatedDuration, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // -- Date applied + Withdraw --
          Row(
            children: [
              if (createdAt != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Applied ${_formatDate(createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
              const Spacer(),
              if (onWithdraw != null)
                GestureDetector(
                  onTap: onWithdraw,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      'Withdraw',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
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
