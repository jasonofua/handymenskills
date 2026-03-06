import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/job_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_cached_image.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _workerProfileController = Get.find<WorkerProfileController>();
  final _notificationController = Get.find<NotificationController>();
  final _bookingController = Get.find<BookingController>();
  final _jobController = Get.find<JobController>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _workerProfileController.loadWorkerProfile(),
      _bookingController.loadBookings(role: 'worker', status: 'confirmed'),
      _jobController.loadJobs(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Obx(() => IconButton(
                onPressed: () => context.push(AppRoutes.notifications),
                icon: AppBadge(
                  count: _notificationController.unreadCount.value,
                  child: const Icon(Icons.notifications_outlined),
                ),
              )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Obx(() {
          if (_workerProfileController.isLoading.value &&
              _workerProfileController.workerProfile.isEmpty) {
            return AppShimmer.list(count: 5);
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildAvailabilityToggle(),
              const SizedBox(height: AppDimensions.lg),
              _buildStatsRow(),
              const SizedBox(height: AppDimensions.lg),
              _buildActiveBookingsSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildRecommendedJobsSection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Obx(() {
      final isAvailable = _workerProfileController.isAvailable.value;
      return AppCard(
        color: isAvailable
            ? AppColors.success.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.success : AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? 'Available for Work' : 'Unavailable',
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(
                    isAvailable
                        ? 'Clients can find and book you'
                        : 'You won\'t appear in search results',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: isAvailable,
              onChanged: (_) => _workerProfileController.toggleAvailability(),
              activeColor: AppColors.success,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final profile = _workerProfileController.workerProfile;
      final jobsCompleted = profile['jobs_completed'] ?? 0;
      final avgRating = (profile['avg_rating'] ?? 0.0).toDouble();
      final totalEarnings = (profile['total_earnings'] ?? 0.0).toDouble();

      return Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Jobs Completed',
              value: jobsCompleted.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCard(
              title: 'Avg Rating',
              value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '--',
              icon: Icons.star_outline,
              color: AppColors.ratingStar,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCard(
              title: 'Earnings',
              value:
                  '${AppConstants.currencySymbol}${_formatCompact(totalEarnings)}',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    });
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildActiveBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Bookings', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push(AppRoutes.workerBookings),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          final bookings = _bookingController.bookings;

          if (_bookingController.isLoading.value && bookings.isEmpty) {
            return const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (bookings.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: AppColors.textHint, size: 40),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No active bookings',
                              style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text('Apply to jobs to get started',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bookings.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimensions.sm),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingCard(
                  booking: booking,
                  onTap: () {
                    final id = booking['id'] as String;
                    context.push(
                      AppRoutes.workerBookingDetail.replaceFirst(':id', id),
                    );
                  },
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendedJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recommended Jobs', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push(AppRoutes.workerJobFeed),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          final jobs = _jobController.jobs;

          if (_jobController.isLoading.value && jobs.isEmpty) {
            return AppShimmer.list(count: 3);
          }

          if (jobs.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  children: [
                    Icon(Icons.work_outline,
                        color: AppColors.textHint, size: 40),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No jobs available',
                              style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text('Check back later for new opportunities',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final displayJobs = jobs.take(5).toList();
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayJobs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, index) {
              final job = displayJobs[index];
              return _RecommendedJobCard(
                job: job,
                onTap: () {
                  final id = job['id'] as String;
                  context.push(
                    AppRoutes.workerJobDetail.replaceFirst(':id', id),
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.sm),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconLg),
          const SizedBox(height: AppDimensions.xs),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final jobTitle = booking['job']?['title'] ?? 'Job';
    final clientName = booking['client']?['full_name'] ?? 'Client';
    final status = booking['status'] ?? 'pending';
    final price = (booking['agreed_price'] ?? 0.0).toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppStatusBadge.booking(status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    clientName,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
              style: AppTextStyles.priceSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _RecommendedJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'Untitled Job';
    final category = job['category']?['name'] ?? '';
    final budgetMin = (job['budget_min'] ?? 0.0).toDouble();
    final budgetMax = (job['budget_max'] ?? 0.0).toDouble();
    final urgency = job['urgency'] ?? 'normal';
    final location = job['location_text'] ?? '';

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppStatusBadge.urgency(urgency),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          if (category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(category, style: AppTextStyles.bodySmall),
            ),
          Row(
            children: [
              Text(
                '${AppConstants.currencySymbol}${budgetMin.toStringAsFixed(0)} - ${AppConstants.currencySymbol}${budgetMax.toStringAsFixed(0)}',
                style: AppTextStyles.priceSmall,
              ),
              const Spacer(),
              if (location.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined,
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
            ],
          ),
        ],
      ),
    );
  }
}
