import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/dispute_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_status_badge.dart';

class DisputesListScreen extends StatefulWidget {
  const DisputesListScreen({super.key});

  @override
  State<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends State<DisputesListScreen> {
  final _disputeController = Get.find<DisputeController>();
  int _selectedFilter = 0; // 0 = Ongoing, 1 = Resolved
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disputeController.loadMyDisputes();
    });
  }

  List<Map<String, dynamic>> get _filteredDisputes {
    final disputes = _disputeController.disputes;
    var result = <Map<String, dynamic>>[];
    if (_selectedFilter == 0) {
      result = disputes.where((d) {
        final status = d['status'] ?? '';
        return status == 'open' || status == 'under_review';
      }).toList();
    } else {
      result = disputes.where((d) {
        final status = d['status'] ?? '';
        return status.contains('resolved') || status == 'closed';
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((d) {
        final reason = d['reason']?.toString().toLowerCase() ?? '';
        final category = d['category']?.toString().toLowerCase() ?? '';
        final jobTitle = ((d['bookings'] as Map<String, dynamic>?)?['jobs'] as Map<String, dynamic>?)?['title']?.toString().toLowerCase() ?? '';
        return reason.contains(_searchQuery) || category.contains(_searchQuery) || jobTitle.contains(_searchQuery);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Disputes', style: AppTextStyles.h4),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pill tab filters
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              0,
              AppDimensions.screenPadding,
              AppDimensions.md,
            ),
            child: Row(
              children: [
                _buildPillTab('Ongoing', 0),
                const SizedBox(width: AppDimensions.sm),
                _buildPillTab('Resolved', 1),
              ],
            ),
          ),

          // Search bar
          if (_showSearch)
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.md,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search disputes...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _showSearch = false;
                      });
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
            ),

          // Dispute list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _disputeController.loadMyDisputes,
              color: AppColors.primary,
              child: Obx(() {
                if (_disputeController.isLoading.value &&
                    _disputeController.disputes.isEmpty) {
                  return AppShimmer.list(count: 5);
                }

                final disputes = _filteredDisputes;

                if (_disputeController.disputes.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      AppEmptyState(
                        icon: Icons.gavel_outlined,
                        title: 'No disputes',
                        subtitle: 'You have not opened any disputes',
                      ),
                    ],
                  );
                }

                if (disputes.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      AppEmptyState(
                        icon: _selectedFilter == 0
                            ? Icons.check_circle_outline
                            : Icons.gavel_outlined,
                        title: _selectedFilter == 0
                            ? 'No ongoing disputes'
                            : 'No resolved disputes',
                        subtitle: _selectedFilter == 0
                            ? 'All your disputes have been resolved'
                            : 'No disputes have been resolved yet',
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: disputes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.md),
                  itemBuilder: (context, index) {
                    return _DisputeCard(
                      dispute: disputes[index],
                      onTap: () {
                        final id = disputes[index]['id'] as String;
                        context.push(
                            AppRoutes.disputeDetail.replaceFirst(':id', id));
                      },
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

  Widget _buildPillTab(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final VoidCallback onTap;

  const _DisputeCard({
    required this.dispute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = dispute['status'] ?? 'open';
    final reason = dispute['reason'] ?? '';
    final createdAt = DateTime.tryParse(dispute['created_at'] ?? '');
    final booking =
        dispute['bookings'] as Map<String, dynamic>? ?? {};
    final job = booking['jobs'] as Map<String, dynamic>? ?? {};
    final jobTitle = job['title'] ?? 'Booking Dispute';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge + date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(status as String),
              if (createdAt != null)
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Dispute title/reason
          Text(
            jobTitle as String,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            reason as String,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppDimensions.md),
          Divider(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.md),

          // View details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Related info
              if (booking['booking_number'] != null)
                Row(
                  children: [
                    Icon(Icons.receipt_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Booking #${booking['booking_number']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),

              // View details button
              Row(
                children: [
                  Text(
                    'View Details',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = AppColors.warning;
        break;
      case 'under_review':
        color = AppColors.info;
        break;
      case 'resolved_client_favor':
      case 'resolved_worker_favor':
      case 'resolved_mutual':
        color = AppColors.success;
        break;
      case 'closed':
        color = AppColors.textHint;
        break;
      default:
        color = AppColors.textHint;
    }

    final label = status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

    return AppStatusBadge(label: label, color: color);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
