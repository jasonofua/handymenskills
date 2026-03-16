import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/booking_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';
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

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  final _bookingController = Get.find<BookingController>();

  static const _tabs = ['active', 'completed', 'cancelled'];
  static const _tabLabels = ['Active', 'Completed', 'Cancelled'];

  // Active includes: pending, confirmed, worker_en_route, in_progress
  static const _activeStatuses = [
    'pending',
    'confirmed',
    'worker_en_route',
    'in_progress',
  ];

  final RxInt _selectedTabIndex = 0.obs;
  final RxBool _showSearch = false.obs;
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookingController.loadBookings(role: 'client');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => _showSearch.value = !_showSearch.value,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab pills
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.sm,
              AppDimensions.screenPadding,
              AppDimensions.md,
            ),
            child: SizedBox(
              height: 38,
              child: Obx(() {
                    final selectedIdx = _selectedTabIndex.value;
                    return ListView.separated(
                    scrollDirection: Axis.horizontal,
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

          // Search bar
          Obx(() => _showSearch.value
              ? Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.md,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => _searchQuery.value = v.toLowerCase(),
                    decoration: InputDecoration(
                      hintText: 'Search bookings...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery.value = '';
                          _showSearch.value = false;
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          // Booking list
          Expanded(
            child: Obx(() {
              if (_bookingController.isLoading.value) {
                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: AppShimmer.card(),
                  ),
                );
              }

              final tabStatus = _tabs[_selectedTabIndex.value];
              final filtered = _bookingController.bookings.where((b) {
                final status = b['status']?.toString() ?? '';
                switch (tabStatus) {
                  case 'active':
                    return _activeStatuses.contains(status);
                  case 'completed':
                    return status == 'completed' ||
                        status == 'client_confirmed';
                  case 'cancelled':
                    return status == 'cancelled' || status == 'disputed';
                  default:
                    return false;
                }
              }).toList();

              final searchFiltered = _searchQuery.value.isEmpty
                  ? filtered
                  : filtered.where((b) {
                      final jobTitle = (b['jobs'] as Map<String, dynamic>?)?['title']?.toString().toLowerCase() ?? '';
                      final workerName = (b['profiles!bookings_worker_id_fkey'] as Map<String, dynamic>?)?['full_name']?.toString().toLowerCase() ?? '';
                      final query = _searchQuery.value;
                      return jobTitle.contains(query) || workerName.contains(query);
                    }).toList();

              if (searchFiltered.isEmpty) {
                return AppEmptyState(
                  icon: _iconForTab(tabStatus),
                  title: _emptyTitle(tabStatus),
                  subtitle: _emptySubtitle(tabStatus),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    _bookingController.loadBookings(role: 'client'),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: searchFiltered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.sm + 4),
                  itemBuilder: (_, index) {
                    final booking = searchFiltered[index];
                    return _BookingCard(
                      booking: booking,
                      onTap: () {
                        final id = booking['id']?.toString() ?? '';
                        context.push(AppRoutes.clientBookingDetail
                            .replaceFirst(':id', id));
                      },
                      onMessage: () => _onMessage(booking),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _onMessage(Map<String, dynamic> booking) async {
    final workerId = booking['worker_id']?.toString() ??
        (booking['profiles!bookings_worker_id_fkey']
                as Map<String, dynamic>?)?['id']
            ?.toString();
    if (workerId == null) return;
    final chatController = Get.find<ChatController>();
    final conversationId = await chatController.startConversation(workerId);
    if (conversationId != null && mounted) {
      context.push(
          AppRoutes.chatConversation.replaceFirst(':id', conversationId));
    }
  }

  IconData _iconForTab(String tab) {
    switch (tab) {
      case 'active':
        return Icons.engineering_outlined;
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
  final VoidCallback onMessage;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString() ?? 'pending';
    final workerProfile =
        booking['profiles!bookings_worker_id_fkey'] as Map<String, dynamic>?;
    final workerName = workerProfile?['full_name']?.toString() ?? 'Worker';
    final workerAvatar = workerProfile?['avatar_url']?.toString();
    final jobData = booking['jobs'] as Map<String, dynamic>?;
    final jobTitle = jobData?['title']?.toString() ?? 'Service';
    final agreedPrice = booking['agreed_price'];
    final scheduledDate = booking['scheduled_date']?.toString();
    final createdAt = booking['created_at']?.toString() ?? '';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker info + status
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
              const SizedBox(width: 8),
              AppStatusBadge.booking(status),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Date + price row
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  scheduledDate != null
                      ? _formatDate(scheduledDate)
                      : _formatDate(createdAt),
                  style: AppTextStyles.caption,
                ),
              ),
              if (agreedPrice != null)
                Text(
                  '${AppConstants.currencySymbol}${agreedPrice is num ? agreedPrice.toStringAsFixed(0) : agreedPrice}',
                  style: AppTextStyles.priceSmall,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
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
