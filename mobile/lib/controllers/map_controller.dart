import 'package:get/get.dart';
import '../data/repositories/worker_repository.dart';
import '../widgets/common/app_snackbar.dart';
import 'location_controller.dart';

class MapController extends GetxController {
  final _workerRepo = Get.find<WorkerRepository>();
  final _locationController = Get.find<LocationController>();

  final RxList<Map<String, dynamic>> nearbyWorkers =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedSkillId = Rx<String?>(null);
  final RxInt radiusKm = 25.obs;

  Future<void> loadNearbyWorkers() async {
    try {
      isLoading.value = true;
      await _locationController.getCurrentLocation();
      final lat = _locationController.latitude;
      final lng = _locationController.longitude;

      if (lat == null || lng == null) {
        AppSnackbar.warning('Unable to get your location');
        return;
      }

      final data = await _workerRepo.searchWorkersNearby(
        lat,
        lng,
        radiusKm.value,
        skillId: selectedSkillId.value,
      );
      nearbyWorkers.assignAll(data);
    } catch (e) {
      AppSnackbar.error('Failed to load nearby workers');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter({String? skillId, int? radius}) {
    if (skillId != null) selectedSkillId.value = skillId;
    if (radius != null) radiusKm.value = radius;
    loadNearbyWorkers();
  }

  void clearFilter() {
    selectedSkillId.value = null;
    loadNearbyWorkers();
  }
}
