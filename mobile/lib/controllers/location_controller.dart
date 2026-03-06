import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../data/services/location_service.dart';

class LocationController extends GetxController {
  final _locationService = Get.find<LocationService>();

  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentAddress = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasPermission = false.obs;

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      hasPermission.value = await _locationService.checkPermission();
      if (!hasPermission.value) return;

      currentPosition.value = await _locationService.getCurrentPosition();
      if (currentPosition.value != null) {
        final address = await _locationService.getAddressFromCoordinates(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
        );
        currentAddress.value = address ?? '';
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  double? get latitude => currentPosition.value?.latitude;
  double? get longitude => currentPosition.value?.longitude;
}
