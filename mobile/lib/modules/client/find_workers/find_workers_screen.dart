import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../controllers/notification_controller.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_badge.dart';

class FindWorkersScreen extends StatefulWidget {
  const FindWorkersScreen({super.key});

  @override
  State<FindWorkersScreen> createState() => _FindWorkersScreenState();
}

class _FindWorkersScreenState extends State<FindWorkersScreen> {
  final _workerRepo = Get.find<WorkerRepository>();
  final _skillRepo = Get.find<SkillRepository>();
  final _notificationController = Get.find<NotificationController>();

  final RxList<Map<String, dynamic>> _workers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _categories =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _selectedCategoryId = ''.obs;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _searchWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _skillRepo.getCategories();
      _categories.assignAll(data);
    } catch (e) {
      debugPrint('FindWorkersScreen: Failed to load categories: $e');
    }
  }

  Future<void> _searchWorkers() async {
    try {
      _isLoading.value = true;
      _hasError.value = false;

      final data = await _workerRepo.searchWorkersByLocation(
        categoryId: _selectedCategoryId.value.isNotEmpty
            ? _selectedCategoryId.value
            : null,
      );
      _workers.assignAll(data);
    } catch (e) {
      _hasError.value = true;
      AppSnackbar.error('Failed to load workers');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: AppDimensions.sm),
            _buildCategoryChips(),
            const SizedBox(height: AppDimensions.sm),
            _buildSectionTitle(),
            Expanded(child: _buildWorkerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.md,
        AppDimensions.screenPadding,
        AppDimensions.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.construction, color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          Text(
            'HandySkills',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          Obx(() => IconButton(
                onPressed: () => context.push(AppRoutes.notifications),
                icon: AppBadge(
                  count: _notificationController.unreadCount.value,
                  child:
                      const Icon(Icons.notifications_outlined, size: 28),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(AppDimensions.inputRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search,
                      color: AppColors.textHint, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for skills (e.g. plumbing)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.circular(AppDimensions.inputRadius),
            ),
            child: const Icon(Icons.tune, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Obx(() {
      if (_categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          itemCount: _categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            if (index == 0) {
              return AppChip(
                label: 'All Workers',
                isSelected: _selectedCategoryId.value.isEmpty,
                onTap: () {
                  _selectedCategoryId.value = '';
                  _searchWorkers();
                },
              );
            }
            final cat = _categories[index - 1];
            final catId = cat['id']?.toString() ?? '';
            return AppChip(
              label: cat['name']?.toString() ?? '',
              isSelected: _selectedCategoryId.value == catId,
              onTap: () {
                _selectedCategoryId.value =
                    _selectedCategoryId.value == catId ? '' : catId;
                _searchWorkers();
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildSectionTitle() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Recommended', style: AppTextStyles.h4),
              Text(
                '${_workers.length} workers nearby',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildWorkerList() {
    return Obx(() {
      if (_isLoading.value) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: AppShimmer.card(),
          ),
        );
      }

      if (_hasError.value) {
        return AppErrorWidget(
          message: 'Failed to load workers',
          onRetry: _searchWorkers,
        );
      }

      if (_workers.isEmpty) {
        return const AppEmptyState(
          icon: Icons.person_search_outlined,
          title: 'No workers found',
          subtitle: 'Try selecting a different category.',
        );
      }

      return RefreshIndicator(
        onRefresh: _searchWorkers,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          itemCount: _workers.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.sm),
          itemBuilder: (_, index) {
            final worker = _workers[index];
            return _WorkerCard(
              worker: worker,
              onTap: () {
                final id = worker['user_id']?.toString() ??
                    worker['id']?.toString() ??
                    '';
                if (id.isNotEmpty) {
                  context.push(AppRoutes.clientWorkerProfile
                      .replaceFirst(':id', id));
                }
              },
            );
          },
        ),
      );
    });
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final VoidCallback onTap;

  const _WorkerCard({required this.worker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = worker['full_name']?.toString() ?? 'Worker';
    final avatarUrl = worker['avatar_url']?.toString();
    final headline =
        worker['headline']?.toString() ?? worker['bio']?.toString() ?? '';
    final rating = worker['average_rating'] ?? worker['rating'];
    final totalReviews =
        worker['total_reviews'] ?? worker['review_count'] ?? 0;
    final workerState = worker['worker_state']?.toString();
    final workerLga = worker['worker_lga']?.toString();
    final isVerified = worker['verification_status'] == 'verified' ||
        worker['is_verified'] == true;
    final skills =
        worker['skills'] as List? ?? worker['worker_skills'] as List? ?? [];
    final isAvailable = worker['is_available'] == true;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: AppDimensions.avatarLg,
              ),
              if (isAvailable)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified + rating row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text(
                            '${rating is num ? rating.toStringAsFixed(1) : rating}',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Headline
                if (headline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    headline,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Skill chips
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: skills.take(3).map<Widget>((s) {
                      final skillName = s is Map
                          ? (s['skill_name'] ??
                                  s['skills']?['name'] ??
                                  s['name'] ??
                                  '')
                              .toString()
                          : s.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          skillName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Location + reviews
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (workerState != null || workerLga != null) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          [workerLga, workerState]
                              .where(
                                  (s) => s != null && s.isNotEmpty)
                              .join(', '),
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (totalReviews > 0)
                      Text(
                        '($totalReviews reviews)',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
