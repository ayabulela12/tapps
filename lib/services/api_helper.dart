import 'package:appmaniazar/constants/constants.dart';
import 'package:appmaniazar/models/hourly_weather.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/models/weekly_weather.dart';
import 'package:appmaniazar/services/geolocator.dart';
import 'package:appmaniazar/utils/logging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

@immutable
class ApiHelper {
  static const baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const weeklyWeatherUrl =
      'https://api.open-meteo.com/v1/forecast?current=&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto';
  static Position? _currentPosition;
  static bool _locationFetched = false;

  static final dio = Dio();
  static final logger = Logger();
  static Weather? _cachedWeather;
  static DateTime? _lastWeatherFetch;
  static const _cacheValidityDuration = Duration(minutes: 5); // Reduced cache time

  static Future<void> fetchLocation() async {
    if (!_locationFetched || _currentPosition == null) {
      _currentPosition = await getLocation();
      _locationFetched = true;
    }
  }

  //Current Weather
  static Future<Weather> getCurrentweather() async {
    final now = DateTime.now();
    
    // Return cached weather if it's still valid
    if (_cachedWeather != null && 
        _lastWeatherFetch != null &&
        now.difference(_lastWeatherFetch!) < _cacheValidityDuration) {
      return _cachedWeather!;
    }

    await fetchLocation();
    final url = _construcWeatherUrl();
    final response = await _fetchData(url);
    _cachedWeather = Weather.fromJson(response);
    _lastWeatherFetch = now;
    return _cachedWeather!;
  }

  static Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    final url = '$baseUrl/weather?lat=$lat&lon=$lon&appid=${Constants.apiKey}&units=metric';
    final response = await _fetchData(url);
    return Weather.fromJson(response);
  }

  //Hourly Weather
  static Future<HourlyWeather> getHourlyForecast() async {
    await fetchLocation();
    if (_currentPosition == null) {
      throw Exception('Location not available');
    }
    
    final url = '$baseUrl/forecast?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=${Constants.apiKey}&units=metric';
    
    try {
      final response = await _fetchData(url);
      logger.d('Hourly Forecast Raw Response: $response');
      
      if (!response.containsKey('list')) {
        logger.w('Response keys available: ${response.keys.toList()}');
        throw const FormatException('Missing list key in response');
      }
      
      final hourlyWeather = HourlyWeather.fromJson(response);
      logger.i('Successfully parsed HourlyWeather with ${hourlyWeather.list.length} entries');
      return hourlyWeather;
      
    } catch (e, stackTrace) {
      logger.e('Error in getHourlyForecast', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _fetchData(String url) async {
    try {
      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw const FormatException('Invalid response format');
        }
        return response.data;
      } else {
        printWarning('Failed to load data: ${response.statusCode}');
        throw Exception('Failed to load data');
      }
    } catch (e) {
      printWarning('Error fetching data from $url: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  //Weekly Forecast
  static Future<WeeklyWeather> getWeeklyForecast() async {
    await fetchLocation();
    final url = _construcWeeklyForecastUrl();
    final response = await _fetchData(url);
    return WeeklyWeather.fromJson(response);
  }

  //Weather by city
  static Future<Weather> getWeatherByCityName(String cityName) async {
    final logger = ApiHelper.logger;

    // Normalise query and default to ZA to stay inside South Africa.
    final trimmed = cityName.trim();
    final query = trimmed.contains(',') ? trimmed : '$trimmed,ZA';

    // 1) Prefer OpenWeather's direct geocoding API to resolve the name
    //    to coordinates (more robust for renamed cities like "Gqeberha").
    final geoUrl =
        'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=1&appid=${Constants.apiKey}';

    try {
      logger.i('🌍 Resolving city name via geocoding: "$query"');
      final geoResponse = await dio.get(geoUrl);

      if (geoResponse.statusCode == 200 && geoResponse.data is List) {
        final list = geoResponse.data as List;
        if (list.isNotEmpty) {
          final loc = list.first as Map<String, dynamic>;
          final lat = (loc['lat'] as num).toDouble();
          final lon = (loc['lon'] as num).toDouble();
          logger.i(
              '📍 Geocoding resolved "$query" to lat=$lat, lon=$lon. Fetching weather by coordinates.');
          return getWeatherByCoordinates(lat, lon);
        } else {
          logger.w(
              '⚠️ Geocoding returned empty list for "$query". Falling back to /weather?q=…');
        }
      } else {
        logger.w(
            '⚠️ Geocoding HTTP ${geoResponse.statusCode} for "$query". Falling back to /weather?q=…');
      }
    } catch (e, stackTrace) {
      logger.w(
        '⚠️ Error during geocoding for "$query", falling back to /weather',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // 2) Fallback: old behaviour using /weather?q=…
    final url = _construcWeatherByCityUrl(cityName);
    final response = await _fetchData(url);
    return Weather.fromJson(response);
  }

  //Url Building
  static String _construcWeatherUrl() {
    if (_currentPosition == null) {
      throw Exception('Location not available');
    }
    return '$baseUrl/weather?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=${Constants.apiKey}&units=metric';
  }

  static String _construcWeatherByCityUrl(String cityName) {
    // If no country is specified, default to South Africa ("ZA") to avoid
    // resolving to the wrong city in another country (e.g. Bellville, US).
    final trimmed = cityName.trim();
    final query =
        trimmed.contains(',') ? trimmed : '$trimmed,ZA'; // ZA-specific app
    return '$baseUrl/weather?q=$query&appid=${Constants.apiKey}&units=metric';
  }

  static String _construcWeeklyForecastUrl() {
    if (_currentPosition == null) {
      throw Exception('Location not available');
    }
    return '$weeklyWeatherUrl&latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}';
  }

  // static Future<Map<String, dynamic>> _fetchData(String url) async {
  //   try {
  //     final response = await dio.get(url);
  //     if (response.statusCode == 200 && response.data != null) {
  //       if (response.data is! Map<String, dynamic>) {
  //         throw FormatException('Invalid response format');
  //       }
  //       return response.data;
  //     } else {
  //       printWarning('Failed to load data: ${response.statusCode}');
  //       throw Exception('Failed to load data');
  //     }
  //   } catch (e) {
  //     printWarning('Error fetching data from $url: $e');
  //     throw Exception('Error fetching data: $e');
  //   }
  // }
  
  // Remove the duplicate _fetchData method at the bottom
}
