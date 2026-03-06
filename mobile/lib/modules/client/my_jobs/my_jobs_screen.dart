import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  final _jobController = Get.find<JobController>();
  late final TabController _tabController;

  static const _tabs = ['open', 'assigned', 'in_progress', 'completed', 'cancelled'];
  static const _tabLabels = ['Open', 'Assigned', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _jobController.loadMyJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.clientPostJob),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((status) => _JobListTab(status: status)).toList(),
      ),
    );
  }
}

class _JobListTab extends StatelessWidget {
  final String status;

  const _JobListTab({required this.status});

  @override
  Widget build(BuildContext context) {
    final jobController = Get.find<JobController>();

    return Obx(() {
      if (jobController.isLoadingMyJobs.value) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: AppShimmer.card(),
          ),
        );
      }

      final filteredJobs = jobController.myJobs
          .where((j) => j['status'] == status)
          .toList();

      if (filteredJobs.isEmpty) {
        return AppEmptyState(
          icon: _iconForStatus(status),
          title: _emptyTitle(status),
          subtitle: _emptySubtitle(status),
          buttonText: status == 'open' ? 'Post a Job' : null,
          onButtonPressed: status == 'open'
              ? () => context.push(AppRoutes.clientPostJob)
              : null,
        );
      }

      return RefreshIndicator(
        onRefresh: () => jobController.loadMyJobs(),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: filteredJobs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.sm),
          itemBuilder: (_, index) {
            final job = filteredJobs[index];
            return _JobCard(
              job: job,
              onTap: () {
                final id = job['id']?.toString() ?? '';
                context.push('/client/my-jobs/$id');
              },
            );
          },
        ),
      );
    });
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'open':
        return Icons.work_outline;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'in_progress':
        return Icons.engineering_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.work_outline;
    }
  }

  String _emptyTitle(String status) {
    switch (status) {
      case 'open':
        return 'No open jobs';
      case 'assigned':
        return 'No assigned jobs';
      case 'in_progress':
        return 'No jobs in progress';
      case 'completed':
        return 'No completed jobs';
      case 'cancelled':
        return 'No cancelled jobs';
      default:
        return 'No jobs';
    }
  }

  String _emptySubtitle(String status) {
    switch (status) {
      case 'open':
        return 'Post a job to find skilled workers.';
      case 'assigned':
        return 'Jobs assigned to workers will appear here.';
      case 'in_progress':
        return 'Jobs being worked on will appear here.';
      case 'completed':
        return 'Completed jobs will appear here.';
      case 'cancelled':
        return 'Cancelled jobs will appear here.';
      default:
        return '';
    }
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job['title']?.toString() ?? 'Untitled Job';
    final status = job['status']?.toString() ?? 'open';
    final urgency = job['urgency']?.toString() ?? 'normal';
    final budgetMin = job['budget_min'];
    final budgetMax = job['budget_max'];
    final applicationCount = (job['applications'] as List?)?.length ??
        job['application_count'] ?? 0;
    final category = job['categories']?['name']?.toString() ?? '';
    final createdAt = job['created_at']?.toString() ?? '';

    String budget = '';
    if (budgetMin != null && budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_fmt(budgetMin)} - ${AppConstants.currencySymbol}${_fmt(budgetMax)}';
    } else if (budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_fmt(budgetMax)}';
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge.job(status),
            ],
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(category, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppDimensions.sm),
          if (budget.isNotEmpty)
            Text(budget, style: AppTextStyles.priceSmall),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '$applicationCount application${applicationCount == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              AppStatusBadge.urgency(urgency),
              const SizedBox(width: 8),
              if (createdAt.isNotEmpty)
                Text(
                  _timeAgo(createdAt),
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
