import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/job_controller.dart';
import '../../../controllers/payment_controller.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

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
  final _authController = Get.find<AuthController>();
  final _subscriptionController = Get.find<SubscriptionController>();
  final _paymentController = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _workerProfileController.loadWorkerProfile(),
      _bookingController.loadBookings(role: 'worker'),
      _jobController.loadJobs(refresh: true),
      _paymentController.loadWorkerBalance(),
    ]);
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatAmount(double value) {
    if (value >= 1000) {
      final parts = value.toStringAsFixed(0).split('');
      final buffer = StringBuffer();
      for (var i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(parts[i]);
      }
      return buffer.toString();
    }
    return value.toStringAsFixed(0);
  }

  String _formatBookingDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  IconData _getJobIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'carpentry':
        return Icons.carpenter;
      case 'moving':
        return Icons.local_shipping_outlined;
      case 'gardening':
        return Icons.grass;
      default:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Obx(() {
          if (_workerProfileController.isLoading.value &&
              _workerProfileController.workerProfile.isEmpty) {
            return AppShimmer.list(count: 5);
          }

          return ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppDimensions.md,
              left: AppDimensions.screenPadding,
              right: AppDimensions.screenPadding,
              bottom: AppDimensions.xl,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.lg),
              _buildSubscriptionCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildEarningsSummary(),
              const SizedBox(height: AppDimensions.lg),
              _buildStatsRow(),
              const SizedBox(height: AppDimensions.lg),
              _buildRecentBookingsSection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final name = _authController.userName;
      final avatar = _authController.userAvatar;
      final isVerified =
          _workerProfileController.workerProfile['verification_status'] == 'verified';

      return Row(
        children: [
          AppAvatar(
            imageUrl: avatar,
            name: name,
            size: AppDimensions.avatarLg,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${name.isNotEmpty ? name.split(' ').first : 'Worker'}',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppDimensions.xs),
                if (isVerified)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Professional',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Obx(() => AppBadge(
                  count: _notificationController.unreadCount.value,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMd,
                    ),
                  ),
                )),
          ),
        ],
      );
    });
  }

  Widget _buildSubscriptionCard() {
    return Obx(() {
      final subscription = _subscriptionController.currentSubscription.value;
      final isActive = _subscriptionController.isActive;
      final daysRemaining = _subscriptionController.daysRemaining;

      final plan = subscription?['subscription_plans'] as Map<String, dynamic>?;
      final planName = plan?['name'] ?? 'Free';
      final price = (plan?['price'] ?? 0).toDouble();

      return GestureDetector(
        onTap: () => context.push(AppRoutes.workerSubscription),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success.withValues(alpha: 0.12),
                AppColors.primaryLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Plan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    planName,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  if (price > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${AppConstants.currencySymbol}${_formatCompact(price)}/month',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (isActive && daysRemaining > 0) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Icon(
                      Icons.autorenew,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Renews in $daysRemaining days',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEarningsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Wallet card with available balance + withdraw --
        Obx(() {
          final availableBalance = _paymentController.workerAvailableBalance.value;
          final profile = _workerProfileController.workerProfile;
          final totalEarnings = (profile['total_earnings'] ?? 0.0).toDouble();

          return GestureDetector(
            onTap: () => context.push(AppRoutes.workerEarnings),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Balance',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          'View Earnings',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    '${AppConstants.currencySymbol}${_formatAmount(availableBalance)}',
                    style: AppTextStyles.priceHero.copyWith(
                      color: AppColors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Lifetime: ${AppConstants.currencySymbol}${_formatAmount(totalEarnings)}',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: availableBalance >= AppConstants.minWithdrawal
                          ? () => context.push(AppRoutes.workerEarnings)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.white.withValues(alpha: 0.3),
                        disabledForegroundColor:
                            AppColors.white.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        availableBalance >= AppConstants.minWithdrawal
                            ? 'Withdraw'
                            : 'Min ${AppConstants.currencySymbol}${AppConstants.minWithdrawal.toStringAsFixed(0)} to withdraw',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final profile = _workerProfileController.workerProfile;
      final allBookings = _bookingController.bookings;
      // Count completed jobs from bookings data (more accurate than profile stats)
      final completedCount = allBookings.where((b) {
        final s = b['status']?.toString() ?? '';
        return s == 'completed' || s == 'client_confirmed';
      }).length;
      final profileJobsCompleted = profile['total_jobs_completed'] ?? 0;
      final jobsCompleted = completedCount > 0 ? completedCount : profileJobsCompleted;
      final avgRating = (profile['average_rating'] ?? 0.0).toDouble();
      final responseRate = (profile['completion_rate'] ?? 0.0).toDouble();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircularStat(
            label: 'Jobs Done',
            value: jobsCompleted.toString(),
            color: AppColors.primary,
            icon: null,
          ),
          _CircularStat(
            label: 'Avg. Rating',
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '--',
            color: AppColors.ratingStar,
            icon: Icons.star,
          ),
          _CircularStat(
            label: 'Response',
            value: '${responseRate.toStringAsFixed(0)}%',
            color: AppColors.info,
            icon: null,
          ),
        ],
      );
    });
  }

  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT BOOKINGS',
              style: AppTextStyles.sectionHeader,
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.workerBookings),
              child: Text(
                'View All',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textHint,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No recent bookings',
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

          final displayBookings = bookings.take(5).toList();
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayBookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, index) {
              final booking = displayBookings[index];
              return _BookingListCard(
                booking: booking,
                getJobIcon: _getJobIcon,
                formatDate: _formatBookingDate,
                onTap: () {
                  final id = booking['id'] as String;
                  context.push(
                    AppRoutes.workerBookingDetail.replaceFirst(':id', id),
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

class _CircularStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _CircularStat({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2.5,
            ),
          ),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: AppTextStyles.h4.copyWith(color: color),
                      ),
                      const SizedBox(width: 2),
                      Icon(icon, color: color, size: 14),
                    ],
                  )
                : Text(
                    value,
                    style: AppTextStyles.h4.copyWith(color: color),
                  ),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BookingListCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final IconData Function(String?) getJobIcon;
  final String Function(String?) formatDate;

  const _BookingListCard({
    required this.booking,
    required this.onTap,
    required this.getJobIcon,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final jobData = booking['jobs'] as Map<String, dynamic>?;
    final clientData = booking['client'] as Map<String, dynamic>?;
    final jobTitle = jobData?['title'] ?? 'Job';
    final clientName = clientData?['full_name'] ?? 'Client';
    final status = booking['status'] ?? 'pending';
    final price = (booking['agreed_price'] ?? 0.0).toDouble() * (1 - AppConstants.commissionRate);
    final category = jobData?['categories']?['name'] as String?;
    final scheduledAt = booking['scheduled_at'] as String? ??
        booking['created_at'] as String?;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getJobIcon(category),
              color: AppColors.primary,
              size: 22,
            ),
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
                  'Client: $clientName',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(scheduledAt),
                  style: AppTextStyles.caption,
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
              const SizedBox(height: AppDimensions.sm),
              Text(
                '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
                style: AppTextStyles.priceSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
