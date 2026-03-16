import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/job_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final _jobController = Get.find<JobController>();
  final _notificationController = Get.find<NotificationController>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jobController.loadJobs(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_jobController.isLoadingMore.value && _jobController.hasMore.value) {
        _jobController.loadJobs();
      }
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _jobController.clearFilters();
      _jobController.loadJobs(refresh: true);
    } else {
      _jobController.searchJobs(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // -- Header: Logo + Notification bell --
            _buildHeader(),

            // -- Search bar --
            _buildSearchBar(),

            // -- Filter chips row --
            _buildFilterChips(),

            const SizedBox(height: AppDimensions.xs),

            // -- Job cards list --
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _jobController.loadJobs(refresh: true),
                child: Obx(() {
                  final jobs = _jobController.jobs;
                  final isLoading = _jobController.isLoading.value;
                  final isLoadingMore = _jobController.isLoadingMore.value;

                  if (isLoading && jobs.isEmpty) {
                    return AppShimmer.list(count: 6);
                  }

                  if (!isLoading && jobs.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No jobs found',
                      subtitle: 'Try adjusting your search or filters',
                      buttonText: 'Clear Filters',
                      onButtonPressed: () {
                        _jobController.clearFilters();
                        _jobController.loadJobs(refresh: true);
                      },
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding,
                    ),
                    itemCount: jobs.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == jobs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppDimensions.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final job = jobs[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppDimensions.md),
                        child: _JobFeedCard(
                          job: job,
                          onTap: () {
                            final id = job['id'] as String;
                            context.push(
                              AppRoutes.workerJobDetail
                                  .replaceFirst(':id', id),
                            );
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          // Logo: construction icon + "HandySkills"
          Icon(
            Icons.construction,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(
            'HandySkills',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Notification bell with badge
          Obx(() {
            final unread = _notificationController.unreadCount.value;
            return AppBadge(
              count: unread,
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.sm,
      ),
      child: GestureDetector(
        onTap: () {
          // Could navigate to a dedicated search screen if needed
        },
        child: Container(
          height: AppDimensions.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppDimensions.md),
              const Icon(Icons.search, color: AppColors.textHint, size: 22),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _onSearch(value.trim());
                  },
                  decoration: const InputDecoration(
                    hintText:
                        'Search for jobs (e.g. plumber, electrician)',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Category', 'Urgency', 'Budget', 'Distance'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          return _FilterChip(label: filters[index]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip (visual-only dropdown style)
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Job Feed Card
// ---------------------------------------------------------------------------

class _JobFeedCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobFeedCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'Untitled Job';
    final description = job['description'] ?? '';
    final category = job['category']?['name'] ?? '';
    final budgetMin = (job['budget_min'] ?? 0.0).toDouble();
    final budgetMax = (job['budget_max'] ?? 0.0).toDouble();
    final urgency = job['urgency'] ?? 'normal';
    final location = job['location_text'] ?? '';
    final createdAt = job['created_at'] as String?;
    final applicantCount = job['application_count'] ?? job['applicant_count'] ?? 0;

    // Client info
    final client = job['client'] as Map<String, dynamic>?;
    final clientName = client?['full_name'] ?? client?['name'] ?? 'Client';
    final clientAvatar = client?['avatar_url'] as String?;
    final clientVerified = client?['is_verified'] ?? false;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Client row + urgency badge --
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: clientAvatar,
                name: clientName,
                size: AppDimensions.avatarSm,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: AppTextStyles.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clientVerified == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'VERIFIED CLIENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              AppStatusBadge.urgency(urgency),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // -- Job title --
          Text(
            title,
            style: AppTextStyles.h4,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // -- Description preview (2 lines max) --
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              description,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppDimensions.md),

          // -- Category chip + budget range --
          Row(
            children: [
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (category.isNotEmpty)
                const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  '${AppConstants.currencySymbol}${budgetMin.toStringAsFixed(0)} - ${AppConstants.currencySymbol}${budgetMax.toStringAsFixed(0)}',
                  style: AppTextStyles.priceSmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // -- Bottom row: applicants + location + time + Apply Now button --
          Row(
            children: [
              // Applicant count
              Icon(Icons.people_outline,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(
                '$applicantCount applicant${(applicantCount as num) == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),

              if (location.isNotEmpty) ...[
                const SizedBox(width: AppDimensions.md),
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    location,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (createdAt != null) ...[
                const SizedBox(width: AppDimensions.md),
                Icon(Icons.access_time,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  _timeAgo(DateTime.tryParse(createdAt)),
                  style: AppTextStyles.caption,
                ),
              ],

              const Spacer(),

              // Apply Now button
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ---------------------------------------------------------------------------
// Filter Bottom Sheet (preserved from original)
