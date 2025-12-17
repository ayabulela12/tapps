import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:appmaniazar/utils/logging.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey = 'AIzaSyB8mhR3UIV8vlu2wLpVbNDILNvTA_TjKCw';

  final Dio _dio = Dio();

  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'types': '(cities)',
        },
      );

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        return predictions
            .map((prediction) => PlaceSearchResult.fromJson(prediction))
            .toList();
      } else {
        throw Exception('Failed to search places');
      }
    } catch (e) {
      printError('Error searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry,formatted_address,name',
        },
      );

      if (response.statusCode == 200) {
        return PlaceDetails.fromJson(response.data['result']);
      } else {
        throw Exception('Failed to get place details');
      }
    } catch (e) {
      printError('Error getting place details: $e');
      throw Exception('Failed to get place details: $e');
    }
  }

  /// Reverse geocode using the Google Geocoding API to get a more precise
  /// human-friendly address when native placemarks are not granular enough.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
        },
      );

      // Log Google Geocoding response status for debugging
      try {
        final status = response.data['status'] as String?;
        final errorMessage = response.data['error_message'] as String?;
        printInfo('Google Geocoding status: ${status ?? 'null'} ${errorMessage != null ? '- $errorMessage' : ''}');
      } catch (_) {}

      if (response.statusCode == 200) {
        final results = response.data['results'] as List<dynamic>?;
        printInfo('Google Geocoding results: ${results?.length ?? 0}');
        if (results == null || results.isEmpty) {
          // Try OSM fallback
          printWarning('Google Geocoding returned no results, falling back to Nominatim');
          return await reverseGeocodeNominatim(lat, lng);
        }

        final first = results.first as Map<String, dynamic>;
        final formattedAddress = first['formatted_address'] as String?;
        final components = (first['address_components'] as List<dynamic>?) ?? [];

        String? getComponent(String type) {
          try {
            final comp = components.cast<Map<String, dynamic>>().firstWhere((c) => (c['types'] as List).contains(type), orElse: () => {});
            return (comp['long_name'] ?? comp['short_name']) as String?;
          } catch (_) {
            return null;
          }
        }

        final neighbourhood = getComponent('neighborhood') ?? getComponent('sublocality_level_1') ?? getComponent('sublocality');
        final route = getComponent('route');
        final streetNumber = getComponent('street_number');
        final locality = getComponent('locality') ?? getComponent('administrative_area_level_2') ?? getComponent('administrative_area_level_1');

        // Prefer street address when available
        if (route != null && streetNumber != null && locality != null) {
          return '$route $streetNumber, $locality';
        }

        if (neighbourhood != null && locality != null) {
          return '$neighbourhood, $locality';
        }

        if (formattedAddress != null && formattedAddress.isNotEmpty) return formattedAddress;

        // If Google did not return a useful formatted address, try Nominatim as a secondary fallback
        printWarning('Google Geocoding did not provide a granular address; trying Nominatim fallback');
        return await reverseGeocodeNominatim(lat, lng);
      }

      // Non-200 HTTP response -> try Nominatim
      printWarning('Google Geocoding HTTP ${response.statusCode}; trying Nominatim');
      return await reverseGeocodeNominatim(lat, lng);
    } catch (e) {
      printError('Error in reverseGeocode: $e');
      // On any exception, try Nominatim as a last resort
      return await reverseGeocodeNominatim(lat, lng);
    }
  }

  /// Reverse geocode using OpenStreetMap Nominatim as a free fallback when
  /// Google doesn't return useful data or is not available.
  Future<String?> reverseGeocodeNominatim(double lat, double lng) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse';
      final response = await _dio.get(url, queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': 1,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) return null;

        final address = data['address'] as Map<String, dynamic>?;
        if (address == null) return null;

        // Prefer suburb/neighbourhood/hamlet > town/village > city > county
        final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['hamlet'];
        final town = address['town'] ?? address['village'] ?? address['city'];
        final county = address['county'];
        final road = address['road'];
        final houseNumber = address['house_number'];

        if (road != null && houseNumber != null && town != null) {
          return '$road $houseNumber, $town';
        }

        if (suburb != null && town != null) return '$suburb, $town';
        if (suburb != null) return suburb as String?;
        if (town != null) return town as String?;
        if (county != null) return county as String?;

        // As final fallback, use display_name if present
        final display = data['display_name'] as String?;
        if (display != null && display.isNotEmpty) return display;
      }

      return null;
    } catch (e) {
      printError('Error in reverseGeocodeNominatim: $e');
      return null;
    }
  }

  Future<({double lat, double lon})> getLocationFromAddress(String address) async {
    final locations = await locationFromAddress(address);
    final location = locations.first;
    return (lat: location.latitude, lon: location.longitude);
  }
}

final placesServiceProvider = Provider((ref) => PlacesService());

@immutable
class PlaceSearchResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSearchResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>;
    return PlaceSearchResult(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: structuredFormatting['main_text'] as String,
      secondaryText: structuredFormatting['secondary_text'] as String,
    );
  }
}

@immutable
class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;
  final String name;

  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      lat: location['lat'] as double,
      lng: location['lng'] as double,
      formattedAddress: json['formatted_address'] as String,
      name: json['name'] as String,
    );
  }
}
