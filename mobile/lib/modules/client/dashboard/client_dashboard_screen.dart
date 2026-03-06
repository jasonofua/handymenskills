import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final _jobController = Get.find<JobController>();
  final _bookingController = Get.find<BookingController>();
  final _notificationController = Get.find<NotificationController>();
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _jobController.loadMyJobs(),
      _bookingController.loadBookings(role: 'client'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          'Hello, ${_authController.userName.isNotEmpty ? _authController.userName.split(' ').first : 'there'}',
        )),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostJobCta(),
              const SizedBox(height: AppDimensions.lg),
              _buildStatsRow(),
              const SizedBox(height: AppDimensions.lg),
              _buildActiveJobsSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildRecentBookingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostJobCta() {
    return AppCard(
      color: AppColors.primary,
      onTap: () => context.push(AppRoutes.clientPostJob),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need something done?',
                  style: AppTextStyles.h4.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Post a job and find skilled artisans near you.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Post a Job',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: const Icon(
              Icons.work_outline,
              size: 48,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final jobs = _jobController.myJobs;
      final bookings = _bookingController.bookings;

      final activeJobs = jobs.where((j) =>
        j['status'] == 'open' ||
        j['status'] == 'assigned' ||
        j['status'] == 'in_progress'
      ).length;

      final totalBookings = bookings.length;

      final totalSpent = bookings
          .where((b) => b['status'] == 'client_confirmed' || b['status'] == 'completed')
          .fold<double>(0.0, (sum, b) {
            final price = b['agreed_price'] ?? b['jobs']?['budget_max'] ?? 0;
            return sum + (price is num ? price.toDouble() : 0.0);
          });

      return Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Active Jobs',
              value: activeJobs.toString(),
              icon: Icons.work_outline,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCard(
              label: 'Bookings',
              value: totalBookings.toString(),
              icon: Icons.calendar_today_outlined,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCard(
              label: 'Spent',
              value: '${AppConstants.currencySymbol}${_formatAmount(totalSpent)}',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    });
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildActiveJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Jobs', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push(AppRoutes.clientMyJobs),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          if (_jobController.isLoadingMyJobs.value) {
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.sm),
                itemBuilder: (_, __) => AppShimmer(
                  width: 260,
                  height: 160,
                  borderRadius: AppDimensions.cardRadius,
                ),
              ),
            );
          }

          final activeJobs = _jobController.myJobs.where((j) =>
            j['status'] == 'open' ||
            j['status'] == 'assigned' ||
            j['status'] == 'in_progress'
          ).toList();

          if (activeJobs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.work_off_outlined,
              title: 'No active jobs',
              subtitle: 'Post a job to get started',
            );
          }

          return SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeJobs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimensions.sm),
              itemBuilder: (_, index) {
                final job = activeJobs[index];
                return _ActiveJobCard(
                  job: job,
                  onTap: () {
                    final id = job['id']?.toString() ?? '';
                    context.push('/client/my-jobs/$id');
                  },
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Bookings', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push(AppRoutes.clientBookings),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          if (_bookingController.isLoading.value) {
            return Column(
              children: List.generate(3, (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: AppShimmer.card(),
              )),
            );
          }

          final bookings = _bookingController.bookings.take(5).toList();

          if (bookings.isEmpty) {
            return const AppEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No bookings yet',
              subtitle: 'Your bookings will appear here',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (_, index) {
              final booking = bookings[index];
              return _RecentBookingCard(
                booking: booking,
                onTap: () {
                  final id = booking['id']?.toString() ?? '';
                  context.push('/client/bookings/$id');
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
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _ActiveJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = job['status']?.toString() ?? 'open';
    final title = job['title']?.toString() ?? 'Untitled Job';
    final budgetMin = job['budget_min'];
    final budgetMax = job['budget_max'];
    final applicationCount = (job['applications'] as List?)?.length ??
        job['application_count'] ?? 0;
    final urgency = job['urgency']?.toString() ?? 'normal';
    final category = job['categories']?['name']?.toString() ?? '';

    String budget = '';
    if (budgetMin != null && budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_formatNum(budgetMin)} - ${AppConstants.currencySymbol}${_formatNum(budgetMax)}';
    } else if (budgetMax != null) {
      budget = '${AppConstants.currencySymbol}${_formatNum(budgetMax)}';
    }

    return SizedBox(
      width: 280,
      child: AppCard(
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
                const SizedBox(width: 8),
                AppStatusBadge.job(status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            if (category.isNotEmpty)
              Text(category, style: AppTextStyles.bodySmall),
            const Spacer(),
            if (budget.isNotEmpty)
              Text(
                budget,
                style: AppTextStyles.priceSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$applicationCount applications',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                AppStatusBadge.urgency(urgency),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(dynamic value) {
    if (value == null) return '0';
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}

class _RecentBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _RecentBookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString() ?? 'pending';
    final workerProfile = booking['profiles!bookings_worker_id_fkey'] as Map<String, dynamic>?;
    final workerName = workerProfile?['full_name']?.toString() ?? 'Worker';
    final jobData = booking['jobs'] as Map<String, dynamic>?;
    final jobTitle = jobData?['title']?.toString() ?? 'Job';
    final agreedPrice = booking['agreed_price'];

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(Icons.handyman, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobTitle,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  workerName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppStatusBadge.booking(status),
              if (agreedPrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.currencySymbol}${agreedPrice is num ? agreedPrice.toStringAsFixed(0) : agreedPrice}',
                  style: AppTextStyles.priceSmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
