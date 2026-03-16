import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../controllers/notification_controller.dart';

import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final _jobController = Get.find<JobController>();
  final _notificationController = Get.find<NotificationController>();

  static const _tabs = ['all', 'open', 'in_progress', 'completed'];
  static const _tabLabels = ['All', 'Open', 'In Progress', 'Completed'];

  final RxInt _selectedTabIndex = 0.obs;
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jobController.loadMyJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Jobs',
          style: AppTextStyles.h4,
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: Obx(() => AppBadge(
                  count: _notificationController.unreadCount.value,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                )),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.sm,
              AppDimensions.screenPadding,
              AppDimensions.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _searchQuery.value = value.toLowerCase(),
              decoration: InputDecoration(
                hintText: 'Search for specific jobs',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textHint,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm + 4,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputRadius),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ),

          // Filter tabs
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(
              bottom: AppDimensions.md,
            ),
            child: SizedBox(
              height: 38,
              child: Obx(() {
                    final selectedIdx = _selectedTabIndex.value;
                    return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding,
                    ),
                    itemCount: _tabLabels.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppDimensions.sm),
                    itemBuilder: (context, index) {
                      final isSelected = selectedIdx == index;
                      return GestureDetector(
                        onTap: () => _selectedTabIndex.value = index,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.md + 4,
                            vertical: AppDimensions.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _tabLabels[index],
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );}),
            ),
          ),

          // Job list
          Expanded(
            child: Obx(() {
              if (_jobController.isLoadingMyJobs.value) {
                return ListView.builder(
                  padding:
                      const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: AppShimmer.card(),
                  ),
                );
              }

              final selectedStatus = _tabs[_selectedTabIndex.value];
              final query = _searchQuery.value;

              final filteredJobs = _jobController.myJobs.where((j) {
                // Filter by tab
                if (selectedStatus != 'all' &&
                    j['status'] != selectedStatus) {
                  return false;
                }
                // Filter by search
                if (query.isNotEmpty) {
                  final title =
                      (j['title']?.toString() ?? '').toLowerCase();
                  final category =
                      (j['categories']?['name']?.toString() ?? '')
                          .toLowerCase();
                  return title.contains(query) ||
                      category.contains(query);
                }
                return true;
              }).toList();

              if (filteredJobs.isEmpty) {
                return AppEmptyState(
                  icon: _iconForStatus(selectedStatus),
                  title: _emptyTitle(selectedStatus),
                  subtitle: _emptySubtitle(selectedStatus),
                  buttonText:
                      selectedStatus == 'all' || selectedStatus == 'open'
                          ? 'Post a Job'
                          : null,
                  onButtonPressed:
                      selectedStatus == 'all' || selectedStatus == 'open'
                          ? () => context.push(AppRoutes.clientPostJob)
                          : null,
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _jobController.loadMyJobs(),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: filteredJobs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.sm + 4),
                  itemBuilder: (_, index) {
                    final job = filteredJobs[index];
                    return _JobCard(
                      job: job,
                      onTap: () {
                        final id = job['id']?.toString() ?? '';
                        context.push(AppRoutes.clientJobDetail
                            .replaceFirst(':id', id));
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.clientPostJob),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: AppColors.white,
          size: 28,
        ),
      ),
    );
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'all':
        return Icons.work_outline;
      case 'open':
        return Icons.work_outline;
      case 'in_progress':
        return Icons.engineering_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.work_outline;
    }
  }

  String _emptyTitle(String status) {
    switch (status) {
      case 'all':
        return 'No jobs yet';
      case 'open':
        return 'No open jobs';
      case 'in_progress':
        return 'No jobs in progress';
      case 'completed':
        return 'No completed jobs';
      default:
        return 'No jobs';
    }
  }

  String _emptySubtitle(String status) {
    switch (status) {
      case 'all':
        return 'Post a job to find skilled workers.';
      case 'open':
        return 'Post a job to find skilled workers.';
      case 'in_progress':
        return 'Jobs being worked on will appear here.';
      case 'completed':
        return 'Completed jobs will appear here.';
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
    final budgetMin = job['budget_min'];
    final budgetMax = job['budget_max'];
    final applicationCount = (job['applications'] as List?)?.length ??
        job['application_count'] ??
        0;
    final category = job['categories']?['name']?.toString() ?? '';
    final createdAt = job['created_at']?.toString() ?? '';
    final assignedWorker = job['assigned_worker']?['full_name']?.toString() ??
        job['assigned_worker_name']?.toString();
    final rating = job['rating'];
    final completedAt = job['completed_at']?.toString();

    String budget = '';
    if (budgetMin != null && budgetMax != null) {
      budget =
          '${AppConstants.currencySymbol}${_fmtNumber(budgetMin)} - ${AppConstants.currencySymbol}${_fmtNumber(budgetMax)}';
    } else if (budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_fmtNumber(budgetMax)}';
    } else if (budgetMin != null) {
      budget = '${AppConstants.currencySymbol}${_fmtNumber(budgetMin)}';
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status badge + budget
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusBadge.job(status),
              const Spacer(),
              if (budget.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      budget,
                      style: AppTextStyles.priceSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'BUDGET',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.sm + 4),

          // Job title
          Text(
            title,
            style: AppTextStyles.h4.copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Category
          if (category.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              category,
              style: AppTextStyles.bodySmall,
            ),
          ],

          const SizedBox(height: AppDimensions.md),

          // Bottom row: context info based on status
          _buildBottomRow(
            status: status,
            applicationCount: applicationCount,
            createdAt: createdAt,
            assignedWorker: assignedWorker,
            rating: rating,
            completedAt: completedAt,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow({
    required String status,
    required int applicationCount,
    required String createdAt,
    String? assignedWorker,
    dynamic rating,
    String? completedAt,
  }) {
    switch (status) {
      case 'in_progress':
        return Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 16,
              color: AppColors.statusInProgress,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                assignedWorker != null
                    ? 'Assigned: $assignedWorker'
                    : 'Worker assigned',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.statusInProgress,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.sm),
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                'Posted ${_timeAgo(createdAt)}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        );

      case 'completed':
        return Row(
          children: [
            if (rating != null) ...[
              const Icon(
                Icons.star,
                size: 16,
                color: AppColors.ratingStar,
              ),
              const SizedBox(width: 4),
              Text(
                _parseRating(rating),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.star_border,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                'Not rated',
                style: AppTextStyles.caption,
              ),
            ],
            const Spacer(),
            const Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              completedAt != null
                  ? _formatDate(completedAt)
                  : (createdAt.isNotEmpty ? _formatDate(createdAt) : ''),
              style: AppTextStyles.caption,
            ),
          ],
        );

      default: // 'open', 'assigned', and others
        return Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              '$applicationCount Application${applicationCount == 1 ? '' : 's'}',
              style: AppTextStyles.bodySmall,
            ),
            const Spacer(),
            if (createdAt.isNotEmpty) ...[
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                'Posted ${_timeAgo(createdAt)}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        );
    }
  }

  String _fmtNumber(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final thousands = n / 1000;
      if (n % 1000 == 0) {
        return '${thousands.toStringAsFixed(0)},000';
      }
      return n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
    }
    return n.toStringAsFixed(0);
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
      if (diff.inDays > 0) {
        return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
      }
      if (diff.inHours > 0) {
        return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
      }
      if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      }
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _parseRating(dynamic rating) {
    if (rating is num) return rating.toStringAsFixed(1);
    final parsed = double.tryParse(rating.toString());
    if (parsed != null) return parsed.toStringAsFixed(1);
    return '0.0';
  }
}
