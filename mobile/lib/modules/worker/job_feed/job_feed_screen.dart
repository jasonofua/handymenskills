import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/job_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_search_bar.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final _jobController = Get.find<JobController>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _jobController.loadJobs(refresh: true);
    _scrollController.addListener(_onScroll);
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        jobController: _jobController,
        onApply: () {
          Navigator.pop(context);
          if (_jobController.searchQuery.value.isNotEmpty) {
            _jobController.searchJobs(_jobController.searchQuery.value);
          } else {
            _jobController.loadJobs(refresh: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: AppSearchBar(
              hint: 'Search jobs...',
              onSearch: _onSearch,
              onFilterTap: _showFilterSheet,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                          const EdgeInsets.only(bottom: AppDimensions.sm),
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
    );
  }
}

class _JobFeedCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobFeedCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'Untitled Job';
    final category = job['category']?['name'] ?? '';
    final budgetMin = (job['budget_min'] ?? 0.0).toDouble();
    final budgetMax = (job['budget_max'] ?? 0.0).toDouble();
    final urgency = job['urgency'] ?? 'normal';
    final location = job['location_text'] ?? '';
    final createdAt = job['created_at'] as String?;

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
                  title,
                  style: AppTextStyles.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              AppStatusBadge.urgency(urgency),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          if (category.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                category,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          Text(
            '${AppConstants.currencySymbol}${budgetMin.toStringAsFixed(0)} - ${AppConstants.currencySymbol}${budgetMax.toStringAsFixed(0)}',
            style: AppTextStyles.priceSmall,
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              if (location.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (createdAt != null) ...[
                const Spacer(),
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(
                  _timeAgo(DateTime.tryParse(createdAt)),
                  style: AppTextStyles.caption,
                ),
              ],
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

class _FilterBottomSheet extends StatelessWidget {
  final JobController jobController;
  final VoidCallback onApply;

  const _FilterBottomSheet({
    required this.jobController,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () {
                    jobController.clearFilters();
                    onApply();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Urgency', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.sm),
                  Obx(() => Wrap(
                        spacing: AppDimensions.sm,
                        children: ['low', 'normal', 'urgent', 'emergency']
                            .map((urgency) => ChoiceChip(
                                  label: Text(urgency[0].toUpperCase() +
                                      urgency.substring(1)),
                                  selected:
                                      jobController.selectedUrgency.value ==
                                          urgency,
                                  onSelected: (selected) {
                                    jobController.selectedUrgency.value =
                                        selected ? urgency : '';
                                  },
                                ))
                            .toList(),
                      )),
                  const SizedBox(height: AppDimensions.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: onApply,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
