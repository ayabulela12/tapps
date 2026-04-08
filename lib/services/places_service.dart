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
      printInfo('🔍 PlacesService.searchPlaces called with query: "$query"');
      
      // Clean and normalize the query for better South African results
      String normalizedQuery = query.trim();
      
      // Add common South African place suffixes if query is short
      if (normalizedQuery.length <= 3) {
        // Don't modify short queries to avoid confusion
      } else if (!normalizedQuery.contains(' ') && 
                 !normalizedQuery.toLowerCase().contains(RegExp(r'(town|city|berg|dam|river|bay|port|park|estate|farm|kraal)'))) {
        // For single-word queries, try to enhance with common SA place patterns
        // But don't modify if it already contains place indicators
      }

      final requestUrl = '$_baseUrl/autocomplete/json';
      final queryParams = {
        'input': normalizedQuery,
        'key': _apiKey,
        // Include all place types but filter out geographical features
        'types': '(regions)',        // towns, cities, suburbs, provinces, regions
        'components': 'country:za',  // Restrict to South Africa only
        'language': 'en',            // English results
        'strictbounds': 'true',      // Enforce country restriction
        // Add location bias towards major South African population centers
        'location': '-28.4793,24.6777', // Center of South Africa
        'radius': '1000000',         // 1000km radius to cover entire country
      };
      
      printInfo('🔍 Making request to: $requestUrl');
      printInfo('🔍 Query params: ${queryParams.keys.map((k) => '$k=${queryParams[k]}').join('&')}');

      final response = await _dio.get(
        requestUrl,
        queryParameters: queryParams,
      );

      printInfo('🔍 Response status: ${response.statusCode}');
      printInfo('🔍 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        printInfo('🔍 Raw predictions count: ${predictions.length}');
        
        // Filter and prioritize results for better South African experience
        List<PlaceSearchResult> results = predictions
            .map((prediction) => PlaceSearchResult.fromJson(prediction))
            .where((result) => _isRelevantSouthAfricanPlace(result))
            .toList();
            
        printInfo('🔍 Filtered results count: ${results.length}');
        
        // Sort results by relevance: suburbs > towns > provinces
        results.sort((a, b) => _comparePlaceRelevance(a, b));
        
        // Limit to top 10 most relevant results
        final finalResults = results.take(10).toList();
        printInfo('🔍 Final results: ${finalResults.map((r) => r.mainText).toList()}');
        
        return finalResults;
      } else {
        throw Exception('Failed to search places: Status ${response.statusCode}');
      }
    } catch (e) {
      printError('Error searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  /// Filter out geographical features but keep all populated places
  bool _isRelevantSouthAfricanPlace(PlaceSearchResult place) {
    final description = place.description.toLowerCase();
    final mainText = place.mainText.toLowerCase();
    
    // Filter out generic or non-SA specific results
    if (description.contains('generic') || 
        description.contains('worldwide') ||
        mainText.length < 2) {
      return false;
    }
    
    // Filter out geographical features (dams, rivers, bays, etc.)
    // But keep towns, cities, suburbs, provinces, regions
    final geographicalFeatures = [
      'dam', 'river', 'bay', 'port', 'mountain', 'mount', 'peak',
      'park', 'nature reserve', 'forest', 'lake', 'pan', 'drif',
      'waterfall', 'spring', 'vallei', 'vlei', 'hoek', 'nek'
    ];
    
    // Check if this is a geographical feature we want to exclude
    bool isGeographicalFeature = geographicalFeatures.any((feature) => 
        mainText.contains(feature) && 
        !mainText.contains('town') && 
        !mainText.contains('city') &&
        !mainText.contains('suburb'));
    
    if (isGeographicalFeature) {
      return false;
    }
    
    // Allow all populated places: towns, cities, suburbs, provinces, regions
    // Also allow places that have town/city/suburb indicators
    final populatedPlaceIndicators = [
      'town', 'city', 'suburb', 'neighborhood', 'area',
      'estate', 'farm', 'kraal', 'dal', 'fontein'
    ];
    
    bool hasPopulatedIndicator = populatedPlaceIndicators.any((indicator) => 
        mainText.contains(indicator) || description.contains(indicator));
    
    // Include if it has populated place indicators or is a well-known place
    return hasPopulatedIndicator || 
           mainText.length > 3 || // Longer names are likely real places
           description.contains('south africa');
  }

  /// Compare place relevance: suburbs > towns > cities > provinces > regions
  int _comparePlaceRelevance(PlaceSearchResult a, PlaceSearchResult b) {
    // Priority order: suburbs > towns > cities > provinces > regions
    final aTypes = a.description.toLowerCase();
    final bTypes = b.description.toLowerCase();
    
    // Check for suburbs/neighborhoods (most specific)
    bool aIsSuburb = aTypes.contains('suburb') || aTypes.contains('neighborhood');
    bool bIsSuburb = bTypes.contains('suburb') || bTypes.contains('neighborhood');
    if (aIsSuburb != bIsSuburb) return aIsSuburb ? -1 : 1;
    
    // Check for towns
    bool aIsTown = aTypes.contains('town');
    bool bIsTown = bTypes.contains('town');
    if (aIsTown != bIsTown) return aIsTown ? -1 : 1;
    
    // Check for cities
    bool aIsCity = aTypes.contains('city');
    bool bIsCity = bTypes.contains('city');
    if (aIsCity != bIsCity) return aIsCity ? -1 : 1;
    
    // Check for provinces (less specific but still relevant)
    bool aIsProvince = aTypes.contains('province') || 
                       aTypes.contains('eastern cape') ||
                       aTypes.contains('western cape') ||
                       aTypes.contains('northern cape') ||
                       aTypes.contains('free state') ||
                       aTypes.contains('kwazulu-natal') ||
                       aTypes.contains('mpumalanga') ||
                       aTypes.contains('limpopo') ||
                       aTypes.contains('north west') ||
                       aTypes.contains('gauteng');
    
    bool bIsProvince = bTypes.contains('province') || 
                       bTypes.contains('eastern cape') ||
                       bTypes.contains('western cape') ||
                       bTypes.contains('northern cape') ||
                       bTypes.contains('free state') ||
                       bTypes.contains('kwazulu-natal') ||
                       bTypes.contains('mpumalanga') ||
                       bTypes.contains('limpopo') ||
                       bTypes.contains('north west') ||
                       bTypes.contains('gauteng');
    
    if (aIsProvince != bIsProvince) return aIsProvince ? 1 : -1;
    
    // If same type, prefer shorter, more specific names
    return a.mainText.length.compareTo(b.mainText.length);
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
        // - administrative_area_level_2: often shows "Ward X" - avoid this
        final neighborhood = getComponent('neighborhood');
        final sublocality1 =
            getComponent('sublocality_level_1') ?? getComponent('sublocality');
        final sublocality2 = getComponent('sublocality_level_2');
        final postalTown = getComponent('postal_town');
        final locality = getComponent('locality');
        final admin2 = getComponent('administrative_area_level_2');

        // Prioritize the most specific location available
        // For Triangle Farm, we want: neighborhood > sublocality > postal_town > locality
        String? mostSpecific;
        
        if (neighborhood != null && neighborhood.isNotEmpty) {
          mostSpecific = neighborhood;
        } else if (sublocality1 != null && sublocality1.isNotEmpty) {
          mostSpecific = sublocality1;
        } else if (sublocality2 != null && sublocality2.isNotEmpty) {
          mostSpecific = sublocality2;
        } else if (postalTown != null && postalTown.isNotEmpty) {
          mostSpecific = postalTown;
        } else if (locality != null && locality.isNotEmpty) {
          mostSpecific = locality;
        }

        // Filter out ward-like names from admin2
        String? filterWardNames(String? name) {
          if (name == null) return null;
          // Filter out "Ward X", "Ward XX", etc.
          if (name.toLowerCase().startsWith('ward ') && 
              name.split(' ').length == 2) {
            return null;
          }
          return name;
        }

        final filteredAdmin2 = filterWardNames(admin2);

        // If we have a most specific location, try to pair it with a broader one
        if (mostSpecific != null) {
          // Don't duplicate if it's the same as the broader location
          if (sublocality1 != null && sublocality1.isNotEmpty && 
              sublocality1.toLowerCase() != mostSpecific.toLowerCase()) {
            return '$mostSpecific, $sublocality1';
          }
          if (postalTown != null && postalTown.isNotEmpty && 
              postalTown.toLowerCase() != mostSpecific.toLowerCase()) {
            return '$mostSpecific, $postalTown';
          }
          if (locality != null && locality.isNotEmpty && 
              locality.toLowerCase() != mostSpecific.toLowerCase()) {
            return '$mostSpecific, $locality';
          }
          // Return just the most specific if no broader location available
          return mostSpecific;
        }

        // Fallback to broader locations
        if (sublocality1 != null && sublocality1.isNotEmpty) return sublocality1;
        if (postalTown != null && postalTown.isNotEmpty) return postalTown;
        if (locality != null && locality.isNotEmpty) return locality;
        
        // Only use filtered admin2 as last resort
        if (filteredAdmin2 != null && filteredAdmin2.isNotEmpty) return filteredAdmin2;

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
        // Filter out ward-like names from administrative divisions
        String? filterWardNames(String? name) {
          if (name == null) return null;
          // Filter out "Ward X", "Ward XX", etc.
          if (name.toLowerCase().startsWith('ward ') && 
              name.split(' ').length == 2) {
            return null;
          }
          return name;
        }

        final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['hamlet'];
        final town = address['town'] ?? address['village'] ?? address['city'];
        final county = filterWardNames(address['county'] as String?);
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
          name = county;
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
