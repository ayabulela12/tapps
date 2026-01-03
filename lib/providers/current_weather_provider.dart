import 'package:appmaniazar/services/geolocator.dart';
import 'package:appmaniazar/services/weather_service.dart';
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
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    logger.i('📍 Received ${placemarks.length} placemark(s)');
    
    if (placemarks.isNotEmpty) {
      final place = placemarks[0];
      
      // Log all available fields for debugging (using info level so it shows)
      logger.i('📍 Placemark fields - subLocality: "${place.subLocality}", locality: "${place.locality}", '
          'name: "${place.name}", thoroughfare: "${place.thoroughfare}", subThoroughfare: "${place.subThoroughfare}", '
          'administrativeArea: "${place.administrativeArea}", subAdministrativeArea: "${place.subAdministrativeArea}", '
          'street: "${place.street}"');
      
      // Try multiple field combinations to get the best location name
      // Priority: subLocality (suburb) > subAdministrativeArea > locality > name > thoroughfare + administrativeArea
      String? locationName;
      
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
        // Combine street with area if available
        final parts = <String>[];
        if (place.thoroughfare != null) parts.add(place.thoroughfare!);
        if (place.administrativeArea != null) parts.add(place.administrativeArea!);
        locationName = parts.join(', ');
        logger.i('📍 Using thoroughfare + administrativeArea: $locationName');
      } else if (place.street?.isNotEmpty == true) {
        locationName = place.street!;
        logger.i('📍 Using street: $locationName');
      } else if (place.administrativeArea?.isNotEmpty == true) {
        locationName = place.administrativeArea!;
        logger.i('📍 Using administrativeArea: $locationName');
      }
      
      if (locationName != null && locationName.isNotEmpty) {
        logger.i('✅ Location name resolved: $locationName');
        return locationName;
      }
      
      logger.w('⚠️ All placemark fields are empty or null');
    } else {
      logger.w('⚠️ No placemarks returned from reverse geocoding');
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
