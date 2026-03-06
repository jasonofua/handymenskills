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

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final _applicationController = Get.find<ApplicationController>();
  late final TabController _tabController;

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Pending'),
    Tab(text: 'Accepted'),
    Tab(text: 'Rejected'),
  ];

  final _statusFilters = const [null, 'pending', 'accepted', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final status = _statusFilters[_tabController.index];
    await _applicationController.loadMyApplications(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (tabIndex) {
          return RefreshIndicator(
            onRefresh: _loadApplications,
            child: Obx(() {
              final applications = _applicationController.myApplications;
              final isLoading = _applicationController.isLoading.value;

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
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.sm),
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
          );
        }),
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
    final proposedPrice = (application['proposed_price'] ?? 0.0).toDouble();
    final status = application['status'] ?? 'pending';
    final createdAt = DateTime.tryParse(application['created_at'] ?? '');
    final estimatedDuration = application['estimated_duration'] as String?;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: AppTextStyles.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              AppStatusBadge.application(status),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.attach_money,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${AppConstants.currencySymbol}${proposedPrice.toStringAsFixed(0)}',
                style: AppTextStyles.priceSmall,
              ),
              if (estimatedDuration != null && estimatedDuration.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.md),
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(estimatedDuration, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              if (createdAt != null) ...[
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Applied ${_formatDate(createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
              const Spacer(),
              if (onWithdraw != null)
                TextButton(
                  onPressed: onWithdraw,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Withdraw'),
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
