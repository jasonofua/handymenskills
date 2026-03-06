import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/booking_controller.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_status_badge.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _bookingController = Get.find<BookingController>();
  late final TabController _tabController;

  static const _tabStatuses = ['active', 'pending', 'completed', 'cancelled'];
  static const _tabLabels = ['Active', 'Pending', 'Completed', 'Cancelled'];

  // Active includes: confirmed, worker_en_route, in_progress
  static const _activeStatuses = ['confirmed', 'worker_en_route', 'in_progress'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
    _bookingController.loadBookings(role: 'client');
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
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabStatuses
            .map((status) => _BookingListTab(
                  tabStatus: status,
                  activeStatuses: _activeStatuses,
                ))
            .toList(),
      ),
    );
  }
}

class _BookingListTab extends StatelessWidget {
  final String tabStatus;
  final List<String> activeStatuses;

  const _BookingListTab({
    required this.tabStatus,
    required this.activeStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final bookingController = Get.find<BookingController>();

    return Obx(() {
      if (bookingController.isLoading.value) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: AppShimmer.card(),
          ),
        );
      }

      final filtered = bookingController.bookings.where((b) {
        final status = b['status']?.toString() ?? '';
        switch (tabStatus) {
          case 'active':
            return activeStatuses.contains(status);
          case 'pending':
            return status == 'pending';
          case 'completed':
            return status == 'completed' || status == 'client_confirmed';
          case 'cancelled':
            return status == 'cancelled' || status == 'disputed';
          default:
            return false;
        }
      }).toList();

      if (filtered.isEmpty) {
        return AppEmptyState(
          icon: _iconForTab(tabStatus),
          title: _emptyTitle(tabStatus),
          subtitle: _emptySubtitle(tabStatus),
        );
      }

      return RefreshIndicator(
        onRefresh: () => bookingController.loadBookings(role: 'client'),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.sm),
          itemBuilder: (_, index) {
            final booking = filtered[index];
            return _BookingCard(
              booking: booking,
              onTap: () {
                final id = booking['id']?.toString() ?? '';
                context.push('/client/bookings/$id');
              },
            );
          },
        ),
      );
    });
  }

  IconData _iconForTab(String tab) {
    switch (tab) {
      case 'active':
        return Icons.engineering_outlined;
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.calendar_today;
    }
  }

  String _emptyTitle(String tab) {
    switch (tab) {
      case 'active':
        return 'No active bookings';
      case 'pending':
        return 'No pending bookings';
      case 'completed':
        return 'No completed bookings';
      case 'cancelled':
        return 'No cancelled bookings';
      default:
        return 'No bookings';
    }
  }

  String _emptySubtitle(String tab) {
    switch (tab) {
      case 'active':
        return 'Active bookings with workers will appear here.';
      case 'pending':
        return 'Bookings awaiting confirmation will appear here.';
      case 'completed':
        return 'Your completed bookings will appear here.';
      case 'cancelled':
        return 'Cancelled bookings will appear here.';
      default:
        return '';
    }
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString() ?? 'pending';
    final workerProfile = booking['profiles!bookings_worker_id_fkey'] as Map<String, dynamic>?;
    final workerName = workerProfile?['full_name']?.toString() ?? 'Worker';
    final workerAvatar = workerProfile?['avatar_url']?.toString();
    final jobData = booking['jobs'] as Map<String, dynamic>?;
    final jobTitle = jobData?['title']?.toString() ?? 'Job';
    final category = jobData?['categories']?['name']?.toString() ?? '';
    final agreedPrice = booking['agreed_price'];
    final scheduledDate = booking['scheduled_date']?.toString();
    final createdAt = booking['created_at']?.toString() ?? '';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: workerAvatar,
                name: workerName,
                size: AppDimensions.avatarMd,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jobTitle,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge.booking(status),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              if (category.isNotEmpty) ...[
                const Icon(Icons.category_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(category, style: AppTextStyles.caption),
                const Spacer(),
              ],
              if (agreedPrice != null)
                Text(
                  '${AppConstants.currencySymbol}${agreedPrice is num ? agreedPrice.toStringAsFixed(0) : agreedPrice}',
                  style: AppTextStyles.priceSmall,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                scheduledDate != null
                    ? _formatDate(scheduledDate)
                    : _formatDate(createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
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
      return dateStr;
    }
  }
}
