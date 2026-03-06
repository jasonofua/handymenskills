import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/booking_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class WorkerBookingsScreen extends StatefulWidget {
  const WorkerBookingsScreen({super.key});

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _bookingController = Get.find<BookingController>();
  late final TabController _tabController;

  final _tabs = const [
    Tab(text: 'Active'),
    Tab(text: 'Upcoming'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ];

  // Maps tab index to status filter for the API
  final _statusFilters = const [
    'in_progress',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final status = _statusFilters[_tabController.index];
    await _bookingController.loadBookings(role: 'worker', status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (tabIndex) {
          return RefreshIndicator(
            onRefresh: _loadBookings,
            child: Obx(() {
              final bookings = _bookingController.bookings;
              final isLoading = _bookingController.isLoading.value;

              if (isLoading && bookings.isEmpty) {
                return AppShimmer.list(count: 5);
              }

              if (!isLoading && bookings.isEmpty) {
                return AppEmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No ${_tabs[tabIndex].text!.toLowerCase()} bookings',
                  subtitle: _getEmptySubtitle(tabIndex),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: _BookingListCard(
                      booking: booking,
                      onTap: () {
                        final id = booking['id'] as String;
                        context.push(
                          AppRoutes.workerBookingDetail
                              .replaceFirst(':id', id),
                        );
                      },
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
      case 0:
        return 'No active jobs at the moment';
      case 1:
        return 'No upcoming bookings scheduled';
      case 2:
        return 'Completed jobs will appear here';
      case 3:
        return 'No cancelled bookings';
      default:
        return '';
    }
  }
}

class _BookingListCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingListCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final jobTitle = booking['job']?['title'] ?? 'Job';
    final clientName = booking['client']?['full_name'] ?? 'Client';
    final status = booking['status'] ?? 'pending';
    final agreedPrice = (booking['agreed_price'] ?? 0.0).toDouble();
    final scheduledDate = DateTime.tryParse(booking['scheduled_date'] ?? '');

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
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Text(
                '${AppConstants.currencySymbol}${agreedPrice.toStringAsFixed(0)}',
                style: AppTextStyles.priceSmall,
              ),
              const Spacer(),
              if (scheduledDate != null) ...[
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _formatDate(scheduledDate),
                  style: AppTextStyles.caption,
                ),
              ],
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
