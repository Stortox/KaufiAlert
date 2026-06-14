import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] for a single, consistent location flow.
class LocationService {
  const LocationService._();

  /// Returns the device's current position, or `null` when location services
  /// are off, permission is denied, or the fix fails.
  ///
  /// Replaces the three slightly different permission flows that used to be
  /// copy-pasted across the store screens.
  static Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) return null;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
