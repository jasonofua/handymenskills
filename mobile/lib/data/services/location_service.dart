import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for obtaining the device's GPS position and performing geocoding.
///
/// All methods handle permission checks gracefully and return `null` (or an
/// empty list) when the operation cannot be completed rather than throwing.
class LocationService {
  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Checks whether location services are enabled and the app has permission.
  ///
  /// If the permission has not yet been determined, this method will trigger
  /// the system permission dialog. Returns `true` when the permission is
  /// [LocationPermission.always] or [LocationPermission.whileInUse].
  Future<bool> checkPermission() async {
    // Ensure the location service itself is turned on.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // The user previously denied the permission permanently. The only
      // recourse is to direct them to the app settings.
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Current position
  // ---------------------------------------------------------------------------

  /// Returns the device's current GPS position with high accuracy.
  ///
  /// Returns `null` if location permissions are not granted or if the
  /// underlying platform call fails.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Reverse geocoding
  // ---------------------------------------------------------------------------

  /// Reverse-geocodes the given coordinates into a human-readable address.
  ///
  /// Returns a single-line address string, or `null` if geocoding fails.
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[
        if (place.street != null && place.street!.isNotEmpty) place.street!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality!,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality!,
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
        if (place.country != null && place.country!.isNotEmpty) place.country!,
      ];

      return parts.isNotEmpty ? parts.join(', ') : null;
    } catch (e) {
      return null;
    }
  }

  /// Reverse-geocodes the given coordinates into a structured address map.
  ///
  /// The returned map contains:
  /// - `address` -- the full street address line
  /// - `city`    -- the locality / city
  /// - `state`   -- the administrative area / state
  /// - `country` -- the country name
  ///
  /// Returns `null` if geocoding fails.
  Future<Map<String, String>?> getDetailedAddress(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      final streetParts = <String>[
        if (place.street != null && place.street!.isNotEmpty) place.street!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality!,
      ];

      return {
        'address': streetParts.isNotEmpty ? streetParts.join(', ') : '',
        'city': place.locality ?? '',
        'state': place.administrativeArea ?? '',
        'country': place.country ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Forward geocoding
  // ---------------------------------------------------------------------------

  /// Forward-geocodes a free-text [query] into a list of [Location] results.
  ///
  /// Returns an empty list if the query yields no results or an error occurs.
  Future<List<Location>> searchLocation(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final locations = await locationFromAddress(query);
      return locations;
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Distance calculation
  // ---------------------------------------------------------------------------

  /// Calculates the straight-line distance in **kilometres** between two
  /// geographic coordinates.
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Geolocator.distanceBetween returns metres.
    final distanceInMetres = Geolocator.distanceBetween(
      lat1,
      lng1,
      lat2,
      lng2,
    );
    return distanceInMetres / 1000.0;
  }
}
