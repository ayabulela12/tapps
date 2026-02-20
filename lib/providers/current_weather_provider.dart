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
    
    // Use reverse geocoding to get the exact suburb/town name
    logger.i('📍 Calling placemarkFromCoordinates...');
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    logger.i('📍 Received ${placemarks.length} placemark(s)');
    
    String? locationName;
    bool hasSuburbLevelNative = false;

    if (placemarks.isNotEmpty) {
      final place = placemarks[0];
      
      // Log all available fields for debugging (using info level so it shows)
      logger.i('📍 Placemark fields - subLocality: "${place.subLocality}", locality: "${place.locality}", '
          'name: "${place.name}", thoroughfare: "${place.thoroughfare}", subThoroughfare: "${place.subThoroughfare}", '
          'administrativeArea: "${place.administrativeArea}", subAdministrativeArea: "${place.subAdministrativeArea}", '
          'street: "${place.street}"');
      
      bool isGenericName(String name) {
        final lower = name.toLowerCase().trim();
        return lower.isEmpty ||
            lower.startsWith('city of ') ||
            lower.contains('metro') ||
            lower.contains('metropolitan') ||
            lower.contains('municipality') ||
            lower.contains('district') ||
            lower.contains('county') ||
            lower.contains('province') ||
            lower.contains('region');
      }

      // Track whether the OS gave us real suburb-level info.
      // Only `subLocality` counts here – admin areas like
      // "City of Cape Town Metropolitan Municipality" should NOT
      // block us from asking PlacesService for a better suburb name.
      hasSuburbLevelNative =
          (place.subLocality?.trim().isNotEmpty ?? false);

      // Try multiple field combinations to get the best location name.
      // Priority: subLocality (suburb) > locality > name > street-ish > admin.
      // IMPORTANT: Avoid generic admin labels (e.g. "City of Cape Town Metropolitan Municipality")
      // when we have a more human-friendly alternative.
      final candidates = <String?>[
        place.subLocality,
        place.locality,
        place.name,
        place.thoroughfare,
        place.street,
        place.subAdministrativeArea,
        place.administrativeArea,
      ];

      final nonEmptyCandidates = candidates
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toList();

      if (nonEmptyCandidates.isNotEmpty) {
        locationName = nonEmptyCandidates
            .firstWhere((c) => !isGenericName(c), orElse: () => nonEmptyCandidates.first)
            .trim();
      } else {
        locationName = null;
      }

      logger.i('📍 Native candidate selected: "$locationName"');
      
      if (locationName == null || locationName.isEmpty) {
        logger.w('⚠️ All placemark fields are empty or null');
      }
    } else {
      logger.w('⚠️ No placemarks returned from reverse geocoding');
    }

    // If the native placemark name is missing or too generic, try the more
    // advanced PlacesService reverse geocoding for a nicer suburb-level name.
    bool isGenericName(String name) {
      final lower = name.toLowerCase().trim();
      return lower.isEmpty ||
          lower.startsWith('city of ') ||
          lower.contains('metro') ||
          lower.contains('metropolitan') ||
          lower.contains('municipality') ||
          lower.contains('district') ||
          lower.contains('county') ||
          lower.contains('province') ||
          lower.contains('region');
    }

    // If we don't have suburb-level native info (common on iOS/Android),
    // try PlacesService to get a more precise label like "Triangle Farm, Bellville".
    if (locationName == null ||
        locationName.isEmpty ||
        isGenericName(locationName) ||
        !hasSuburbLevelNative) {
      logger.i(
        '📍 Native placemark is missing/too broad (name="$locationName", hasSuburbLevelNative=$hasSuburbLevelNative). '
        'Trying PlacesService.reverseGeocode...',
      );
      final placesService = ref.read(placesServiceProvider);
      final placesName =
          await placesService.reverseGeocode(position.latitude, position.longitude);
      if (placesName != null && placesName.trim().isNotEmpty && !isGenericName(placesName)) {
        logger.i('✅ PlacesService location name resolved: $placesName');
        return placesName;
      }
    }
    
    if (locationName != null && locationName.isNotEmpty && !isGenericName(locationName)) {
      logger.i('✅ Location name resolved: $locationName');
      return locationName;
    }
    if (locationName != null && locationName.isNotEmpty && isGenericName(locationName)) {
      logger.w('⚠️ Native location name remained generic ("$locationName"); returning Unknown Location');
      return 'Unknown Location';
    }
    
    logger.w('⚠️ Returning "Unknown Location"');
    return 'Unknown Location';
  } catch (e, stackTrace) {
    logger.e('❌ Error getting location name', error: e, stackTrace: stackTrace);
    return 'Unknown Location';
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
