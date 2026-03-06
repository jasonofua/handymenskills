import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../controllers/location_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_search_bar.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_snackbar.dart';

class FindWorkersScreen extends StatefulWidget {
  const FindWorkersScreen({super.key});

  @override
  State<FindWorkersScreen> createState() => _FindWorkersScreenState();
}

class _FindWorkersScreenState extends State<FindWorkersScreen> {
  final _workerRepo = Get.find<WorkerRepository>();
  final _skillRepo = Get.find<SkillRepository>();

  final RxList<Map<String, dynamic>> _workers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _categories = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _selectedCategoryId = ''.obs;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchWorkers();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _skillRepo.getCategories();
      _categories.assignAll(data);
    } catch (_) {}
  }

  Future<void> _searchWorkers() async {
    try {
      _isLoading.value = true;
      _hasError.value = false;

      // Try to use location for proximity search
      double lat = 6.5244; // Lagos default
      double lng = 3.3792;

      try {
        final locationController = Get.find<LocationController>();
        final position = locationController.currentPosition;
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (_) {
        // Location not available; use defaults
      }

      final data = await _workerRepo.searchWorkersNearby(
        lat,
        lng,
        100,
        skillId: _selectedCategoryId.value.isNotEmpty
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
      appBar: AppBar(
        title: const Text('Find Workers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.sm,
              AppDimensions.screenPadding,
              0,
            ),
            child: AppSearchBar(
              hint: 'Search workers by name or skill...',
              onSearch: (query) {
                _searchQuery = query;
                _searchWorkers();
              },
              onFilterTap: () => _showFilterSheet(context),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          _buildCategoryChips(),
          const SizedBox(height: AppDimensions.sm),
          Expanded(child: _buildWorkerList()),
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
                label: 'All',
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
          subtitle: 'Try adjusting your search or filters.',
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
                    worker['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  context.push('/client/workers/$id');
                }
              },
            );
          },
        ),
      );
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        categories: _categories,
        selectedCategoryId: _selectedCategoryId.value,
        onApply: (categoryId) {
          _selectedCategoryId.value = categoryId ?? '';
          _searchWorkers();
        },
      ),
    );
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
    final headline = worker['headline']?.toString() ??
        worker['bio']?.toString() ?? '';
    final rating = worker['average_rating'] ?? worker['rating'];
    final totalReviews = worker['total_reviews'] ?? worker['review_count'] ?? 0;
    final distance = worker['distance_km'];
    final isVerified = worker['verification_status'] == 'verified' ||
        worker['is_verified'] == true;
    final skills = worker['skills'] as List? ??
        worker['worker_skills'] as List? ?? [];

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: AppDimensions.avatarLg,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text(
                            '${rating is num ? rating.toStringAsFixed(1) : rating}',
                            style: AppTextStyles.labelMedium,
                          ),
                          Text(
                            ' ($totalReviews)',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                  ],
                ),
                if (headline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    headline,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: skills.take(3).map<Widget>((s) {
                      final skillName = s is Map
                          ? (s['skills']?['name'] ?? s['name'] ?? '').toString()
                          : s.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          skillName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (distance != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${distance is num ? distance.toStringAsFixed(1) : distance} km away',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategoryId;
  final void Function(String?) onApply;

  const _FilterSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategoryId.isNotEmpty
        ? widget.selectedCategoryId
        : null;
  }

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
                    setState(() => _selectedCategory = null);
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
                  const Text('Category', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.categories.map((cat) {
                      final id = cat['id']?.toString() ?? '';
                      return AppChip(
                        label: cat['name']?.toString() ?? '',
                        isSelected: _selectedCategory == id,
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == id ? null : id;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedCategory);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                  ),
                  child: const Text('Apply Filters', style: AppTextStyles.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
