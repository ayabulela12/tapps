import 'dart:async';
import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/models/weather_alert.dart';
import 'package:appmaniazar/services/weather_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class AlertService {
  final Logger _logger = Logger();
  final WeatherService _weatherService = WeatherService();
  
  Timer? _alertCheckTimer;
  final StreamController<WeatherAlert> _alertStreamController = StreamController<WeatherAlert>.broadcast();
  final List<WeatherAlert> _alerts = <WeatherAlert>[];
  
  // Alert generation thresholds
  static const double extremeTempThreshold = 40.0; // °C
  static const double freezingTempThreshold = 0.0; // °C
  static const double highWindThreshold = 50.0; // km/h
  static const double heavyRainThreshold = 50.0; // mm
  static const double lowHumidityThreshold = 20.0; // %
  static const double severeStormThreshold = 0.9; // probability
  
  Stream<WeatherAlert> get alertStream => _alertStreamController.stream;

  AlertService() {
    _initializeAlertService();
  }

  Future<void> _initializeAlertService() async {
    try {
      // Start periodic alert generation based on weather conditions
      _startPeriodicWeatherChecks();
      
      _logger.i('✅ Alert service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize alert service: $e');
    }
  }

  void _startPeriodicWeatherChecks() {
    // Check weather conditions every 15 minutes
    _alertCheckTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkWeatherConditions();
    });
  }

  Future<void> _checkWeatherConditions() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final weather = await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _generateWeatherAlerts(weather, position);
      
    } catch (e) {
      _logger.e('❌ Error checking weather conditions: $e');
    }
  }

  Future<void> _generateWeatherAlerts(Weather weather, Position position) async {
    final List<WeatherAlert> alerts = [];

    // Temperature alerts
    if (weather.temperature >= extremeTempThreshold) {
      alerts.add(_createTemperatureAlert(
        weather,
        position,
        'Extreme Heat Warning',
        'Temperature has reached ${weather.temperature}°C. Stay hydrated and avoid prolonged sun exposure.',
        AlertType.severe,
        AlertPriority.high,
      ));
    } else if (weather.temperature <= freezingTempThreshold) {
      alerts.add(_createTemperatureAlert(
        weather,
        position,
        'Freezing Temperature Alert',
        'Temperature has dropped to ${weather.temperature}°C. Protect pipes and sensitive plants.',
        AlertType.advisory,
        AlertPriority.medium,
      ));
    }

    // Wind alerts
    if (weather.windSpeed >= highWindThreshold) {
      alerts.add(_createWindAlert(
        weather,
        position,
        'High Wind Warning',
        'Wind speeds of ${weather.windSpeed} km/h detected. Secure outdoor objects.',
        AlertType.moderate,
        AlertPriority.medium,
      ));
    }

    // Humidity alerts
    if (weather.humidity <= lowHumidityThreshold) {
      alerts.add(_createHumidityAlert(
        weather,
        position,
        'Low Humidity Alert',
        'Humidity at ${weather.humidity}%. Increase hydration and skin moisturization.',
        AlertType.advisory,
        AlertPriority.low,
      ));
    }

    // Weather condition alerts
    _generateWeatherConditionAlerts(weather, position, alerts);

    // Save alerts in-memory and notify
    for (final alert in alerts) {
      await _saveAlert(alert);
      _alertStreamController.add(alert);
    }

    if (alerts.isNotEmpty) {
      _logger.i('🚨 Generated ${alerts.length} weather alerts');
    }
  }

  void _generateWeatherConditionAlerts(
    Weather weather, 
    Position position, 
    List<WeatherAlert> alerts
  ) {
    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    
    switch (mainCondition.toLowerCase()) {
      case 'thunderstorm':
      case 'squall':
      case 'tornado':
        alerts.add(_createWeatherConditionAlert(
          weather,
          position,
          'Severe Storm Warning',
          'Severe thunderstorm conditions detected. Seek shelter immediately.',
          AlertType.severe,
          AlertPriority.critical,
        ));
        break;
      case 'rain':
      case 'drizzle':
        final rainfall = weather.rain?.oneHour ?? 0.0;
        if (rainfall >= heavyRainThreshold) {
          alerts.add(_createWeatherConditionAlert(
            weather,
            position,
            'Heavy Rain Alert',
            'Heavy rainfall of ${rainfall}mm detected. Avoid flooded areas.',
            AlertType.moderate,
            AlertPriority.high,
          ));
        }
        break;
      case 'snow':
        alerts.add(_createWeatherConditionAlert(
          weather,
          position,
          'Snow Alert',
          'Snow conditions detected. Drive carefully and dress warmly.',
          AlertType.advisory,
          AlertPriority.medium,
        ));
        break;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        alerts.add(_createWeatherConditionAlert(
          weather,
          position,
          'Reduced Visibility Alert',
          'Poor visibility conditions detected. Use extra caution when driving.',
          AlertType.advisory,
          AlertPriority.medium,
        ));
        break;
    }
  }

  WeatherAlert _createTemperatureAlert(
    Weather weather,
    Position position,
    String title,
    String description,
    AlertType type,
    AlertPriority priority,
  ) {
    return WeatherAlert(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      priority: priority,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 6)),
      latitude: position.latitude,
      longitude: position.longitude,
      metadata: {
        'temperature': weather.temperature,
        'feelsLike': weather.main.feelsLike,
        'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
      },
    );
  }

  WeatherAlert _createWindAlert(
    Weather weather,
    Position position,
    String title,
    String description,
    AlertType type,
    AlertPriority priority,
  ) {
    return WeatherAlert(
      id: 'wind_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      priority: priority,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
      latitude: position.latitude,
      longitude: position.longitude,
      metadata: {
        'windSpeed': weather.windSpeed,
        'windDirection': weather.wind.deg,
        'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
      },
    );
  }

  WeatherAlert _createHumidityAlert(
    Weather weather,
    Position position,
    String title,
    String description,
    AlertType type,
    AlertPriority priority,
  ) {
    return WeatherAlert(
      id: 'humidity_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      priority: priority,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
      latitude: position.latitude,
      longitude: position.longitude,
      metadata: {
        'humidity': weather.humidity,
        'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
      },
    );
  }

  WeatherAlert _createWeatherConditionAlert(
    Weather weather,
    Position position,
    String title,
    String description,
    AlertType type,
    AlertPriority priority,
  ) {
    return WeatherAlert(
      id: 'condition_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      priority: priority,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 3)),
      latitude: position.latitude,
      longitude: position.longitude,
      metadata: {
        'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
        'description': weather.weather.isNotEmpty ? weather.weather.first.description : '',
        'temperature': weather.temperature,
      },
    );
  }

  Future<void> _saveAlert(WeatherAlert alert) async {
    try {
      _alerts.removeWhere((a) => a.id == alert.id);
      _alerts.add(alert);
      _alerts.sort((a, b) {
        final byPriority = a.priority.priority.compareTo(b.priority.priority);
        if (byPriority != 0) return byPriority;
        return b.issuedAt.compareTo(a.issuedAt);
      });
      _logger.i('✅ Alert saved in memory: ${alert.title}');
    } catch (e) {
      _logger.e('❌ Failed to save alert in memory: $e');
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index == -1) return;
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      
      _logger.i('✅ Alert marked as read: $alertId');
    } catch (e) {
      _logger.e('❌ Failed to mark alert as read: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      _alerts.removeWhere((a) => a.id == alertId);
      
      _logger.i('✅ Alert deleted: $alertId');
    } catch (e) {
      _logger.e('❌ Failed to delete alert: $e');
    }
  }

  Future<List<WeatherAlert>> getUserAlerts({bool unreadOnly = false}) async {
    try {
      final active = _alerts.where((alert) => !alert.isExpired).toList();
      if (unreadOnly) {
        return active.where((alert) => !alert.isRead).toList();
      }
      return active;
    } catch (e) {
      _logger.e('❌ Failed to get user alerts: $e');
      return [];
    }
  }

  Future<void> createDamLevelAlert(
    String damName,
    double currentLevel,
    double criticalLevel,
    String region,
  ) async {
    final alert = WeatherAlert(
      id: 'dam_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Dam Level Alert: $damName',
      description: '$damName is at ${currentLevel.toStringAsFixed(1)}% capacity. Critical level is ${criticalLevel.toStringAsFixed(1)}%.',
      type: currentLevel < criticalLevel ? AlertType.dam : AlertType.info,
      priority: currentLevel < criticalLevel ? AlertPriority.high : AlertPriority.low,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      region: region,
      metadata: {
        'damName': damName,
        'currentLevel': currentLevel,
        'criticalLevel': criticalLevel,
        'alertType': 'dam_level',
      },
    );

    await _saveAlert(alert);
    _alertStreamController.add(alert);
  }

  void dispose() {
    _alertCheckTimer?.cancel();
    _alertStreamController.close();
  }
}

// Global alert service instance
final alertServiceProvider = Provider<AlertService>((ref) {
  final service = AlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Stream provider for real-time alerts
final alertStreamProvider = StreamProvider<WeatherAlert>((ref) {
  final alertService = ref.watch(alertServiceProvider);
  return alertService.alertStream;
});

// Future provider for user alerts
final userAlertsProvider = FutureProvider<List<WeatherAlert>>((ref) async {
  final alertService = ref.watch(alertServiceProvider);
  return await alertService.getUserAlerts();
});

// Future provider for unread alerts count
final unreadAlertsCountProvider = Provider<int>((ref) {
  final alertsAsync = ref.watch(userAlertsProvider);
  return alertsAsync.when(
    data: (alerts) => alerts.where((alert) => !alert.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
