import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:appmaniazar/utils/logging.dart';
import 'dart:math' as math;

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
        final nom = await reverseGeocodeNominatim(lat, lng);
        // If Overpass can find a closer named place, prefer it
        final overpass = await reverseGeocodeOverpass(lat, lng);
        if (overpass != null) {
          final overName = overpass['name'] as String;
          final overDist = overpass['distance'] as double;
          final nomLat = nom?['lat'] as double?;
          final nomLon = nom?['lon'] as double?;
          double nomDist = double.infinity;
          if (nomLat != null && nomLon != null) {
            nomDist = _haversineDistanceMeters(lat, lng, nomLat, nomLon);
          }
          printInfo('Nominatim dist: ${nomDist == double.infinity ? 'unknown' : nomDist.toStringAsFixed(0)} m, Overpass dist: ${overDist.toStringAsFixed(0)} m');

          // If Overpass found a nearer place, prefer it
          if (overDist < nomDist) {
            printSuccess('Overpass returned nearer place: $overName (${overDist.toStringAsFixed(0)} m)');
            return overName;
          }
        }

        if (nom != null) return nom['name'] as String?;
        return null;
      }

      // Non-200 HTTP response -> try Nominatim
      printWarning('Google Geocoding HTTP ${response.statusCode}; trying Nominatim');
      final nomFallback = await reverseGeocodeNominatim(lat, lng);
      final overpassFallback = await reverseGeocodeOverpass(lat, lng);
      if (overpassFallback != null && nomFallback != null) {
        final nomLat = nomFallback['lat'] as double?;
        final nomLon = nomFallback['lon'] as double?;
        double nomDist = double.infinity;
        if (nomLat != null && nomLon != null) {
          nomDist = _haversineDistanceMeters(lat, lng, nomLat, nomLon);
        }
        final overDist = overpassFallback['distance'] as double;
        if (overDist < nomDist) {
          printSuccess('Overpass returned nearer place (HTTP non-200 path): ${overpassFallback['name']} (${overDist.toStringAsFixed(0)} m)');
          return overpassFallback['name'] as String?;
        }
      }

      if (nomFallback != null) return nomFallback['name'] as String?;
      if (overpassFallback != null) return overpassFallback['name'] as String?;

      return null;
    } catch (e) {
      printError('Error in reverseGeocode: $e');
      // On any exception, try Nominatim as a last resort
      final nomLast = await reverseGeocodeNominatim(lat, lng);
      final overLast = await reverseGeocodeOverpass(lat, lng);
      if (overLast != null && nomLast != null) {
        final nomLat = nomLast['lat'] as double?;
        final nomLon = nomLast['lon'] as double?;
        double nomDist = double.infinity;
        if (nomLat != null && nomLon != null) {
          nomDist = _haversineDistanceMeters(lat, lng, nomLat, nomLon);
        }
        final overDist = overLast['distance'] as double;
        if (overDist < nomDist) {
          printSuccess('Overpass returned nearer place (exception path): ${overLast['name']} (${overDist.toStringAsFixed(0)} m)');
          return overLast['name'] as String?;
        }
      }

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
      final response = await _dio.post(url, data: query, options: Options(headers: {'Content-Type': 'text/plain'}));

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
