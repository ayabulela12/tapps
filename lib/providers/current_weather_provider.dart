import 'package:appmaniazar/services/geolocator.dart';
import 'package:appmaniazar/services/places_service.dart';
import 'package:appmaniazar/services/weather_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

/// Shared provider that fetches the current device position.
/// Using this means both the location name and weather use the same
/// fresh GPS fix each time, and it will naturally refresh when
/// the app is restarted or the provider is explicitly refreshed.
final devicePositionProvider = FutureProvider.autoDispose((ref) async {
  final logger = Logger();
  logger.i('📍 Fetching device position via devicePositionProvider...');
  final position = await getLocation(forceRefresh: true);
  logger.i(
      '📍 Device position: lat=${position.latitude}, lon=${position.longitude}');
  return position;
});

/// Provider that gets the exact location name from reverse geocoding
final currentLocationNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final logger = Logger();

  logger.i('🔄 Starting reverse geocoding...');

  try {
    // Use shared device position so name + weather stay in sync
    final position = await ref.watch(devicePositionProvider.future);

    logger.i('📍 Getting location name for: lat=${position.latitude}, lon=${position.longitude}');

    final placesService = ref.read(placesServiceProvider);
    logger.i('📍 Calling placemarkFromCoordinates...');
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    logger.i('📍 Received ${placemarks.length} placemark(s)');
    
    final Placemark? nativePlacemark =
        placemarks.isNotEmpty ? placemarks.first : null;

    if (nativePlacemark != null) {
      logger.i(
        '📍 Placemark fields - subLocality: "${nativePlacemark.subLocality}", locality: "${nativePlacemark.locality}", '
        'thoroughfare: "${nativePlacemark.thoroughfare}", subThoroughfare: "${nativePlacemark.subThoroughfare}", '
        'administrativeArea: "${nativePlacemark.administrativeArea}", street: "${nativePlacemark.street}"',
      );
    } else {
      logger.w('⚠️ No placemarks returned from native reverse geocoding');
    }

    final resolvedName = await placesService.resolvePreferredLocationLabel(
      position.latitude,
      position.longitude,
      nativePlacemark: nativePlacemark,
    );
    logger.i('✅ Location name resolved: $resolvedName');
    return resolvedName;
  } catch (e, stackTrace) {
    logger.e('❌ Error getting location name', error: e, stackTrace: stackTrace);
    try {
      final position = await ref.watch(devicePositionProvider.future);
      final fallback = ref
          .read(placesServiceProvider)
          .coordinatesLabel(position.latitude, position.longitude);
      logger.w('⚠️ Falling back to coordinates label: $fallback');
      return fallback;
    } catch (_) {
      return 'Current Location';
    }
  }
});

/// Selected manual location name (from search/cards)
final selectedLocationProvider = StateProvider<String?>((ref) => null);

/// Selected manual coordinates; when set, main weather screen uses these
final selectedCoordinatesProvider =
    StateProvider<({double lat, double lon})?>((ref) => null);

final currentWeatherProvider = FutureProvider.autoDispose((ref) async {
  final logger = Logger();
  final weatherService = ref.read(weatherServiceProvider);
  
  // Use shared device position so we stay in sync with the
  // reverse-geocoded name and can easily be refreshed.
  final position = await ref.watch(devicePositionProvider.future);
  
  logger.i('🌤️ Fetching weather for: lat=${position.latitude}, lon=${position.longitude}');
  
  return weatherService.getCurrentWeather(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

final weatherByCoordinatesProvider = FutureProvider.autoDispose.family<dynamic, ({double lat, double lon})>((ref, coords) async {
  final weatherService = ref.read(weatherServiceProvider);
  return weatherService.getCurrentWeather(
    latitude: coords.lat,
    longitude: coords.lon,
  );
});
