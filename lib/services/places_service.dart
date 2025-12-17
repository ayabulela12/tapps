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
