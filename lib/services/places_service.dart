import 'dart:math' as math;

import 'package:appmaniazar/utils/logging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey = 'AIzaSyB8mhR3UIV8vlu2wLpVbNDILNvTA_TjKCw';

  // NOTE: Nominatim requires a valid User-Agent; without it requests can be rejected.
  final Dio _dio = Dio(
    BaseOptions(
      headers: const {
        'User-Agent': 'AppManiazarWeatherApp/1.0',
        'Accept': 'application/json',
      },
    ),
  );

  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          // Restrict suggestions to South Africa and include both cities
          // and higher-level regions (provinces, metro areas).
          // This makes searches like "Gqeberha" and "Eastern Cape"
          // return results reliably within ZA.
          'types': '(regions)',        // localities + admin areas
          'components': 'country:za',  // only South Africa
          'language': 'en',            // consistent labels
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
          final nom = await reverseGeocodeNominatim(lat, lng);
          if (nom != null) return nom['name'] as String?;
          return null;
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

        // Build a suburb-level label like "Triangle Farm, Bellville" when possible.
        // In many SA areas:
        // - neighborhood: Triangle Farm
        // - sublocality_level_1: Bellville
        // - locality: Cape Town (too broad)
        final neighborhood = getComponent('neighborhood');
        final sublocality1 =
            getComponent('sublocality_level_1') ?? getComponent('sublocality');
        final postalTown = getComponent('postal_town');
        final locality = getComponent('locality');
        final admin2 = getComponent('administrative_area_level_2');
        final admin1 = getComponent('administrative_area_level_1');

        final second =
            sublocality1 ?? postalTown ?? locality ?? admin2 ?? admin1;

        if (neighborhood != null &&
            second != null &&
            neighborhood.isNotEmpty &&
            second.isNotEmpty &&
            neighborhood.toLowerCase() != second.toLowerCase()) {
          return '$neighborhood, $second';
        }

        if (sublocality1 != null &&
            locality != null &&
            sublocality1.isNotEmpty &&
            locality.isNotEmpty &&
            sublocality1.toLowerCase() != locality.toLowerCase()) {
          return '$sublocality1, $locality';
        }

        if (neighborhood != null && neighborhood.isNotEmpty) return neighborhood;
        if (sublocality1 != null && sublocality1.isNotEmpty) return sublocality1;
        if (locality != null && locality.isNotEmpty) return locality;

        // As a last resort, use Google's formatted_address (may be long).
        if (formattedAddress != null && formattedAddress.isNotEmpty) {
          return formattedAddress;
        }

        // If Google did not return a useful formatted address, try Nominatim as a secondary fallback
        printWarning('Google Geocoding did not provide a granular address; trying Nominatim fallback');
        final nom = await reverseGeocodeNominatim(lat, lng);
        // Prefer Nominatim's suburb/town name when available;
        // only fall back to Overpass if Nominatim returns nothing.
        final overpass = await reverseGeocodeOverpass(lat, lng);
        if (nom != null) {
          return nom['name'] as String?;
        }
        if (overpass != null) {
          return overpass['name'] as String?;
        }
        return null;
      }

      // Non-200 HTTP response -> try Nominatim
      printWarning('Google Geocoding HTTP ${response.statusCode}; trying Nominatim');
      final nomFallback = await reverseGeocodeNominatim(lat, lng);
      final overpassFallback = await reverseGeocodeOverpass(lat, lng);
      // Prefer Nominatim when both are available; Overpass is a backup only.
      if (nomFallback != null) return nomFallback['name'] as String?;
      if (overpassFallback != null) return overpassFallback['name'] as String?;

      return null;
    } catch (e) {
      printError('Error in reverseGeocode: $e');
      // On any exception, try Nominatim as a last resort
      final nomLast = await reverseGeocodeNominatim(lat, lng);
      final overLast = await reverseGeocodeOverpass(lat, lng);
      // Same rule: Nominatim first, then Overpass as backup.
      if (nomLast != null) return nomLast['name'] as String?;
      if (overLast != null) return overLast['name'] as String?;

      return null;
    }
  }

  /// Reverse geocode using OpenStreetMap Nominatim as a free fallback when
  /// Google doesn't return useful data or is not available.
  /// Nominatim reverse geocode: returns a Map with name and coords when found.
  Future<Map<String, dynamic>?> reverseGeocodeNominatim(double lat, double lng) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse';
      final response = await _dio.get(
        url,
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'addressdetails': 1,
        },
        options: Options(
          headers: const {
            // Nominatim policy: identify your application via User-Agent.
            'User-Agent': 'AppManiazarWeatherApp/1.0',
            'Accept': 'application/json',
          },
        ),
      );

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

        String? name;
        if (road != null && houseNumber != null && town != null) {
          name = '$road $houseNumber, $town';
        } else if (suburb != null && town != null) {
          name = '$suburb, $town';
        } else if (suburb != null) {
          name = suburb as String?;
        } else if (town != null) {
          name = town as String?;
        } else if (county != null) {
          name = county as String?;
        } else {
          final display = data['display_name'] as String?;
          if (display != null && display.isNotEmpty) name = display;
        }

        if (name == null || name.isEmpty) return null;

        // Extract lat/lon returned by Nominatim for the matched record
        final resLat = (data['lat'] != null) ? double.tryParse(data['lat'].toString()) : null;
        final resLon = (data['lon'] != null) ? double.tryParse(data['lon'].toString()) : null;

        return {
          'name': name,
          'lat': resLat,
          'lon': resLon,
        };
      }

      return null;
    } catch (e) {
      printError('Error in reverseGeocodeNominatim: $e');
      return null;
    }
  }

  /// Query Overpass API for nearest 'place' (suburb/town/village/locality) within radius meters
  Future<Map<String, dynamic>?> reverseGeocodeOverpass(double lat, double lon, {int radius = 5000}) async {
    try {
      final query = '''[out:json][timeout:25];
(
  node(around:$radius,$lat,$lon)[place];
  way(around:$radius,$lat,$lon)[place];
  relation(around:$radius,$lat,$lon)[place];
);
out center;''';

      final url = 'https://overpass-api.de/api/interpreter';
      final response = await _dio.post(
        url,
        data: query,
        options: Options(
          headers: const {
            'Content-Type': 'text/plain',
            'User-Agent': 'AppManiazarWeatherApp/1.0',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final elements = response.data['elements'] as List<dynamic>?;
        if (elements == null || elements.isEmpty) return null;

        Map<String, dynamic>? best;
        double bestDist = double.infinity;

        for (final el in elements.cast<Map<String, dynamic>>()) {
          final tags = el['tags'] as Map<String, dynamic>?;
          if (tags == null) continue;
          final name = tags['name'] as String?;
          if (name == null || name.isEmpty) continue;

          double? elLat;
          double? elLon;
          if (el.containsKey('lat') && el.containsKey('lon')) {
            elLat = (el['lat'] as num).toDouble();
            elLon = (el['lon'] as num).toDouble();
          } else if (el.containsKey('center')) {
            final center = el['center'] as Map<String, dynamic>?;
            if (center != null) {
              elLat = (center['lat'] as num).toDouble();
              elLon = (center['lon'] as num).toDouble();
            }
          }

          if (elLat == null || elLon == null) continue;

          final dist = _haversineDistanceMeters(lat, lon, elLat, elLon);
          if (dist < bestDist) {
            bestDist = dist;
            best = {
              'name': name,
              'lat': elLat,
              'lon': elLon,
              'distance': dist,
            };
          }
        }

        return best;
      }

      return null;
    } catch (e) {
      printError('Error in reverseGeocodeOverpass: $e');
      return null;
    }
  }

  double _haversineDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // metres
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final dphi = (lat2 - lat1) * math.pi / 180.0;
    final dlambda = (lon2 - lon1) * math.pi / 180.0;

    final a = math.sin(dphi/2) * math.sin(dphi/2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2) * math.sin(dlambda/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));

    return R * c;
  }

  Future<({double lat, double lon})> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return (lat: location.latitude, lon: location.longitude);
      }
      // Return fallback coordinates if no location found
      return (lat: -26.2041, lon: 28.0473); // Johannesburg fallback
    } catch (e) {
      // Return fallback coordinates on error
      return (lat: -26.2041, lon: 28.0473); // Johannesburg fallback
    }
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
