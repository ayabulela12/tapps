import 'package:appmaniazar/services/geolocator.dart';
import 'package:appmaniazar/services/weather_service.dart';
import 'package:appmaniazar/services/places_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:geocoding/geocoding.dart';

/// Provider that gets the exact location name from reverse geocoding
final currentLocationNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final logger = Logger();
  
  logger.i('🔄 Starting reverse geocoding...');
  
  try {
    // Force a fresh location fetch
    final position = await getLocation(forceRefresh: true);
    
    logger.i('📍 Getting location name for: lat=${position.latitude}, lon=${position.longitude}');
    
    // Use reverse geocoding to get the exact suburb/town name
    logger.i('📍 Calling placemarkFromCoordinates...');

    // Attempt native placemark lookup but make it resilient to unexpected nulls/exceptions.
    List<Placemark> placemarks = [];
    try {
      placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      logger.w('⚠️ placemarkFromCoordinates failed: $e');

      // Try Google fallback immediately if placemark lookup errored
      try {
        final placesService = ref.read(placesServiceProvider);
        logger.i('📍 Trying Google reverse geocode as fallback (placemark error)...');
        final googleName = await placesService.reverseGeocode(position.latitude, position.longitude);
        if (googleName != null && googleName.isNotEmpty) {
          logger.i('✅ Google reverseGeocode returned (on placemark failure): $googleName');

          // If location accuracy is low, prefer the locality part of the Google response
          final accuracy = position.accuracy ?? double.infinity;
          const preciseThreshold = 75.0; // meters
          if (accuracy > preciseThreshold && googleName.contains(',')) {
            final parts = googleName.split(',');
            final fallbackName = parts.last.trim();
            logger.i('⚠️ Location accuracy $accuracy m > $preciseThreshold, using locality part: $fallbackName');
            return fallbackName;
          }

          return googleName;
        } else {
          logger.w('⚠️ Google reverseGeocode returned no useful data');
        }
      } catch (e) {
        logger.w('⚠️ Google reverseGeocode failed: $e');
      }
    }

    logger.i('📍 Received ${placemarks.length} placemark(s)');

    if (placemarks.isNotEmpty) {
      final place = placemarks[0];
      
      // Log all available fields for debugging (using info level so it shows)
      logger.i('📍 Placemark fields - subLocality: "${place.subLocality}", locality: "${place.locality}", '
          'name: "${place.name}", thoroughfare: "${place.thoroughfare}", subThoroughfare: "${place.subThoroughfare}", '
          'administrativeArea: "${place.administrativeArea}", subAdministrativeArea: "${place.subAdministrativeArea}", '
          'street: "${place.street}"');
      
      // Try multiple field combinations to get the best location name
      // Priority: subLocality (suburb) > subAdministrativeArea > locality > name > thoroughfare + locality > street + locality
      String? locationName;
      final accuracy = position.accuracy ?? double.infinity;
      const preciseThreshold = 75.0; // meters
      
      if (place.subLocality?.isNotEmpty == true) {
        locationName = place.subLocality!;
        logger.i('📍 Using subLocality: $locationName');
      } else if (place.subAdministrativeArea?.isNotEmpty == true) {
        locationName = place.subAdministrativeArea!;
        logger.i('📍 Using subAdministrativeArea: $locationName');
      } else if (place.locality?.isNotEmpty == true) {
        locationName = place.locality!;
        logger.i('📍 Using locality: $locationName');
      } else if (place.name?.isNotEmpty == true) {
        locationName = place.name!;
        logger.i('📍 Using name: $locationName');
      } else if (place.thoroughfare?.isNotEmpty == true) {
        // Only use street-level info if accuracy is good enough
        if (accuracy <= preciseThreshold) {
          final parts = <String>[];
          if (place.thoroughfare != null) parts.add(place.thoroughfare!);
          if (place.locality != null) parts.add(place.locality!);
          locationName = parts.join(', ');
          logger.i('📍 Using thoroughfare + locality: $locationName');
        } else {
          logger.w('⚠️ Location accuracy $accuracy m too low for street-level name; skipping thoroughfare');
        }
      } else if (place.street?.isNotEmpty == true) {
        if (accuracy <= preciseThreshold) {
          final parts = <String>[];
          if (place.street != null) parts.add(place.street!);
          if (place.locality != null) parts.add(place.locality!);
          locationName = parts.join(', ');
          logger.i('📍 Using street + locality: $locationName');
        } else {
          logger.w('⚠️ Location accuracy $accuracy m too low for street-level name; skipping street');
        }
      } else if (place.administrativeArea?.isNotEmpty == true) {
        locationName = place.administrativeArea!;
        logger.i('📍 Using administrativeArea: $locationName');
      }
      
      if (locationName != null && locationName.isNotEmpty) {
        logger.i('✅ Location name resolved: $locationName');
        return locationName;
      }
      
      logger.w('⚠️ All placemark fields are empty or null');

      // Fallback: try Google Geocoding API's reverse geocode for a more precise formatted address
      try {
        final placesService = ref.read(placesServiceProvider);
        logger.i('📍 Trying Google reverse geocode as fallback...');
        final googleName = await placesService.reverseGeocode(position.latitude, position.longitude);
        if (googleName != null && googleName.isNotEmpty) {
          // If accuracy is low prefer locality portion of the google response
          if (accuracy > preciseThreshold && googleName.contains(',')) {
            final parts = googleName.split(',');
            final fallbackName = parts.last.trim();
            logger.i('⚠️ Location accuracy $accuracy m > $preciseThreshold, using locality part from Google: $fallbackName');
            return fallbackName;
          }

          logger.i('✅ Google reverseGeocode returned: $googleName');
          return googleName;
        } else {
          logger.w('⚠️ Google reverseGeocode returned no useful data');
        }
      } catch (e) {
        logger.w('⚠️ Google reverseGeocode failed: $e');
      }
    }

    logger.w('⚠️ Returning "Unknown Location"');
    return 'Unknown Location';
  } catch (e, stackTrace) {
    logger.e('❌ Error getting location name', error: e, stackTrace: stackTrace);
    return 'Unknown Location';
  }
});

final currentWeatherProvider = FutureProvider.autoDispose((ref) async {
  final logger = Logger();
  final weatherService = ref.read(weatherServiceProvider);
  
  // Force a fresh location fetch
  final position = await getLocation(forceRefresh: true);
  
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
