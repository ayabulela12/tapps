import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

// Fallback coordinates (Johannesburg, South Africa) in case permission is denied.
const double fallbackLatitude = -26.2041;
const double fallbackLongitude = 28.0473;

/// Gets the current device location with best possible accuracy for navigation.
/// Uses FusedLocationProvider on Android with bestForNavigation accuracy.
/// Forces a fresh location update and logs the coordinates for debugging.
Future<Position> getLocation({bool forceRefresh = true}) async {
  final logger = Logger();

  try {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services disabled; using fallback coordinates');
      return Position(
        latitude: fallbackLatitude,
        longitude: fallbackLongitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    // Check location permissions (requesting is intentionally done from UI
    // after explaining to the user). If permission is not granted, fall back.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      logger.w('Location permission not granted; using fallback coordinates');
      return Position(
        latitude: fallbackLatitude,
        longitude: fallbackLongitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    // Get current position with best for navigation accuracy
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      forceAndroidLocationManager: false,
      timeLimit: const Duration(seconds: 30),
    );

    logger.i('✅ High-accuracy location obtained: Lat=${position.latitude}, Lon=${position.longitude}, Accuracy=${position.accuracy}m');
    return position;
  } catch (e, stack) {
    logger.e('Error getting location; using fallback', error: e, stackTrace: stack);
    
    // Try to get last known position as fallback before using default
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        logger.w('Using last known position: lat=${lastPosition.latitude}, lon=${lastPosition.longitude}, accuracy=${lastPosition.accuracy}m');
        return lastPosition;
      }
    } catch (_) {
      // Ignore error getting last known position
    }

    return Position(
      latitude: fallbackLatitude,
      longitude: fallbackLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}