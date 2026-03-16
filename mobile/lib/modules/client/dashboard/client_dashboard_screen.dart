import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/job_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/payment_controller.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_badge.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  final _paymentController = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _paymentController.loadWalletBalance();
    });
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.lg),
                _buildStatsRow(),
                const SizedBox(height: AppDimensions.lg),
                _buildQuickActions(),
                const SizedBox(height: AppDimensions.lg),
                _buildWalletCard(),
                const SizedBox(height: AppDimensions.lg),
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() => Row(
          children: [
            AppAvatar(
              imageUrl: _authController.userAvatar,
              name: _authController.userName,
              size: AppDimensions.avatarMd,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Hello, ${_authController.userName.isNotEmpty ? _authController.userName.split(' ').first : 'there'}',
                    style: AppTextStyles.h3,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: AppBadge(
                count: _notificationController.unreadCount.value,
                child: const Icon(Icons.notifications_outlined, size: 28),
              ),
            ),
          ],
        ));
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final jobs = _jobController.myJobs;
      final bookings = _bookingController.bookings;

      final activeJobs = jobs
          .where((j) =>
              j['status'] == 'open' ||
              j['status'] == 'assigned' ||
              j['status'] == 'in_progress')
          .length;

      final pendingBookings =
          bookings.where((b) => b['status'] == 'pending').length;

      final completedJobs =
          jobs.where((j) => j['status'] == 'completed').length;

      return Row(
        children: [
          Expanded(
            child: _StatCircle(
              label: 'Active Jobs',
              value: activeJobs.toString(),
              icon: Icons.work_outline,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCircle(
              label: 'Pending',
              value: pendingBookings.toString(),
              icon: Icons.schedule_outlined,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: _StatCircle(
              label: 'Completed',
              value: completedJobs.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.clientPostJob),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.add, color: AppColors.white),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      const Text(
                        'Post a Job',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.clientFindWorkers),
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.groups_outlined,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      const Text(
                        'Find Workers',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WALLET BALANCE',
                  style: AppTextStyles.sectionHeader.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Obx(() => Text(
                  '${AppConstants.currencySymbol}${_paymentController.walletBalance.value.toStringAsFixed(2)}',
                  style: AppTextStyles.priceHero.copyWith(
                    color: AppColors.white,
                  ),
                )),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showTopUpDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
            child: const Text('Top Up',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            hintText: 'Enter amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount <= 0) {
                AppSnackbar.error('Please enter a valid amount');
                return;
              }
              Navigator.pop(ctx);
              final success = await _paymentController.processPayment(
                context: context,
                amountInNaira: amount,
                paymentType: 'wallet_topup',
              );
              if (success) {
                AppSnackbar.success('Wallet topped up successfully');
                await _paymentController.loadWalletBalance();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Top Up', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => context.push(AppRoutes.notifications),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          if (_jobController.isLoadingMyJobs.value) {
            return AppShimmer.list(count: 3);
          }

          final jobs = _jobController.myJobs;
          final bookings = _bookingController.bookings;
          final balance = _paymentController.walletBalance.value;

          // Build activity items from recent jobs, bookings, and payments
          final activities = <Map<String, dynamic>>[];

          // Show recently posted jobs
          for (final job in jobs.take(3)) {
            final title = job['title'] ?? 'Job';
            final status = job['status']?.toString() ?? '';
            final jobTime = _formatTime(job['created_at']);
            final appCount =
                (job['applications'] as List?)?.length ??
                    job['application_count'] ??
                    0;
            if (appCount > 0) {
              activities.add({
                'icon': Icons.person_add_outlined,
                'color': AppColors.info,
                'title': 'New application received',
                'description': 'Application for \'$title\'',
                'time': jobTime,
              });
            } else if (status == 'open') {
              activities.add({
                'icon': Icons.work_outline,
                'color': AppColors.primary,
                'title': 'Job posted',
                'description': '\'$title\' is live and accepting applications',
                'time': jobTime,
              });
            }
          }

          // Show wallet top-up if balance > 0
          if (balance > 0) {
            activities.add({
              'icon': Icons.account_balance_wallet_outlined,
              'color': AppColors.success,
              'title': 'Wallet funded',
              'description':
                  'Balance: ${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}',
              'time': _formatTime(_paymentController.lastTopUpTime.value),
            });
          }

          for (final booking in bookings.take(3)) {
            final status = booking['status']?.toString() ?? '';
            final bookingTime = _formatTime(booking['created_at']);
            if (status == 'confirmed') {
              activities.add({
                'icon': Icons.check_circle_outline,
                'color': AppColors.success,
                'title': 'Booking confirmed',
                'description':
                    'Your booking has been confirmed',
                'time': bookingTime,
              });
            } else if (status == 'completed') {
              activities.add({
                'icon': Icons.payments_outlined,
                'color': AppColors.primary,
                'title': 'Payment Successful',
                'description':
                    'Payment for service completed',
                'time': bookingTime,
              });
            } else if (status == 'pending') {
              activities.add({
                'icon': Icons.schedule_outlined,
                'color': AppColors.secondary,
                'title': 'Booking pending',
                'description': 'Waiting for worker confirmation',
                'time': bookingTime,
              });
            }
          }

          if (activities.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  children: [
                    Icon(Icons.history,
                        color: AppColors.textHint, size: 40),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No recent activity',
                              style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text('Your activity will appear here',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: activities.take(5).map((activity) {
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (activity['color'] as Color)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['description'] as String,
                              style: AppTextStyles.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return timeago.format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _StatCircle extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCircle({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.md, horizontal: AppDimensions.sm),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
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
