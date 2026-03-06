import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/map_controller.dart';
import '../../../controllers/location_controller.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = Get.find<MapController>();
  final _locationController = Get.find<LocationController>();
  final _workerProfileController = Get.find<WorkerProfileController>();
  GoogleMapController? _googleMapController;

  @override
  void initState() {
    super.initState();
    _mapController.loadNearbyWorkers();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Workers'),
        actions: [
          Obx(() => _mapController.selectedSkillId.value != null
              ? IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: _mapController.clearFilter,
                  tooltip: 'Clear filter',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (_mapController.isLoading.value &&
            _mapController.nearbyWorkers.isEmpty) {
          return AppShimmer.list(count: 3);
        }

        final position = _locationController.currentPosition.value;
        final workers = _mapController.nearbyWorkers;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position != null
                    ? LatLng(position.latitude, position.longitude)
                    : const LatLng(9.0820, 8.6753), // Nigeria center
                zoom: 13,
              ),
              markers: _buildMarkers(workers),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _googleMapController = controller;
              },
            ),
            // Category filter chips at top
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _buildCategoryFilter(),
            ),
            // Worker count badge
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildWorkerCountBadge(workers.length),
            ),
          ],
        );
      }),
    );
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> workers) {
    return workers.where((w) {
      // The search_workers_nearby RPC should return location data
      return w['latitude'] != null && w['longitude'] != null;
    }).map((worker) {
      final lat = (worker['latitude'] as num).toDouble();
      final lng = (worker['longitude'] as num).toDouble();
      final name = worker['full_name'] ?? 'Worker';
      final rating =
          (worker['average_rating'] ?? 0.0).toDouble();
      final headline = worker['headline'] ?? '';

      return Marker(
        markerId: MarkerId(worker['user_id'] ?? worker['id'] ?? ''),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: name as String,
          snippet:
              '${rating.toStringAsFixed(1)} stars${headline.toString().isNotEmpty ? ' - $headline' : ''}',
          onTap: () => _onWorkerTap(worker),
        ),
      );
    }).toSet();
  }

  void _onWorkerTap(Map<String, dynamic> worker) {
    final userId = worker['user_id'] ?? worker['id'];
    if (userId != null) {
      context.push('/client/workers/$userId');
    }
  }

  Widget _buildCategoryFilter() {
    return Obx(() {
      final categories = _workerProfileController.categories;

      if (categories.isEmpty) return const SizedBox.shrink();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              isSelected: _mapController.selectedSkillId.value == null,
              onTap: () => _mapController.clearFilter(),
            ),
            ...categories.map((cat) {
              return _buildFilterChip(
                label: cat['name'] as String? ?? '',
                isSelected: false,
                onTap: () {
                  // For simplicity, filter by the first skill of the category
                  // A more complete implementation would show a sub-menu of skills
                },
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCountBadge(int count) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '$count worker${count == 1 ? '' : 's'} nearby',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
