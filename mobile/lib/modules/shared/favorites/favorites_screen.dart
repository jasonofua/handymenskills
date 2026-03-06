import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_snackbar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteRepository _favoriteRepo = Get.find<FavoriteRepository>();

  List<Map<String, dynamic>> _savedWorkers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workers = await _favoriteRepo.getSavedWorkers();
      if (mounted) {
        setState(() {
          _savedWorkers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load saved workers';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unsaveWorker(String workerId, int index) async {
    // Optimistically remove from list
    final removedWorker = _savedWorkers[index];
    setState(() {
      _savedWorkers.removeAt(index);
    });

    try {
      await _favoriteRepo.unsaveWorker(workerId);
      if (mounted) {
        AppSnackbar.success('Worker removed from saved');
      }
    } catch (e) {
      // Restore on failure
      if (mounted) {
        setState(() {
          _savedWorkers.insert(index, removedWorker);
        });
        AppSnackbar.error('Failed to remove worker');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Workers'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.md),
            OutlinedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_savedWorkers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFavorites,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            AppEmptyState(
              icon: Icons.favorite_border,
              title: 'No saved workers',
              subtitle:
                  'Save workers you like to quickly find them later.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppDimensions.md,
          crossAxisSpacing: AppDimensions.md,
          childAspectRatio: 0.78,
        ),
        itemCount: _savedWorkers.length,
        itemBuilder: (context, index) {
          final savedEntry = _savedWorkers[index];
          return _SavedWorkerCard(
            savedEntry: savedEntry,
            onTap: () {
              final profile =
                  savedEntry['profiles'] as Map<String, dynamic>? ?? {};
              final workerId = profile['id'] as String? ??
                  savedEntry['worker_id'] as String? ??
                  '';
              if (workerId.isNotEmpty) {
                context.push(
                  AppRoutes.clientWorkerProfile
                      .replaceFirst(':id', workerId),
                );
              }
            },
            onUnsave: () {
              final workerId = savedEntry['worker_id'] as String? ?? '';
              if (workerId.isNotEmpty) {
                _unsaveWorker(workerId, index);
              }
            },
          );
        },
      ),
    );
  }
}

class _SavedWorkerCard extends StatelessWidget {
  final Map<String, dynamic> savedEntry;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedWorkerCard({
    required this.savedEntry,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final profile =
        savedEntry['profiles'] as Map<String, dynamic>? ?? {};
    final workerProfile =
        profile['worker_profiles'] as Map<String, dynamic>? ?? {};

    final String name = profile['full_name'] ?? 'Unknown';
    final String? avatarUrl = profile['avatar_url'];
    final String headline = workerProfile['headline'] ?? '';
    final double rating =
        (workerProfile['average_rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount =
        (workerProfile['review_count'] as num?)?.toInt() ?? 0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Unsave button at top right
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onUnsave,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ),
          ),

          AppAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: AppDimensions.avatarLg,
          ),
          const SizedBox(height: AppDimensions.sm),

          Text(
            name,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          if (headline.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              headline,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppDimensions.sm),

          // Rating row
          if (rating > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  size: 16,
                  color: AppColors.ratingStar,
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (reviewCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($reviewCount)',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            )
          else
            Text(
              'No ratings yet',
              style: AppTextStyles.caption,
            ),
        ],
      ),
    );
  }
}
