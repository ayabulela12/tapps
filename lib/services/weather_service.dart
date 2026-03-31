import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:logger/logger.dart';

final weatherServiceProvider = Provider((ref) => WeatherService());

class WeatherService {
  final dio = Dio();
  final String apiKey = 'd12a09f4569b47071241f919e50ab404';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  final logger = Logger();

  Future<Weather> getCurrentWeather(
      {required double latitude, required double longitude}) async {
    try {
      logger.d('Fetching weather for lat: $latitude, lon: $longitude');

      final response = await dio.get(
        '$baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      logger.d('Weather API response: ${response.data}');

      return Weather.fromJson(response.data);
    } catch (e, stackTrace) {
      logger.e('Error fetching weather', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      logger.d('Searching locations for query: $query');

      final response = await dio.get(
        'https://api.openweathermap.org/geo/1.0/direct',
        queryParameters: {
          'q': query,
          'limit': 5,
          'appid': apiKey,
        },
      );

      logger.d('Location search response: ${response.data}');

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      logger.e('Error searching locations', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
