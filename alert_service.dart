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
  final StreamController<WeatherAlert> _alertStreamController =
      StreamController<WeatherAlert>.broadcast();

  // In-memory alert store (replaces Firestore)
  final List<WeatherAlert> _alerts = [];

  // Alert generation thresholds
  static const double extremeTempThreshold = 40.0;
  static const double freezingTempThreshold = 0.0;
  static const double highWindThreshold = 50.0;
  static const double heavyRainThreshold = 50.0;
  static const double lowHumidityThreshold = 20.0;

  Stream<WeatherAlert> get alertStream => _alertStreamController.stream;

  AlertService() {
    _initializeAlertService();
  }

  Future<void> _initializeAlertService() async {
    try {
      _startPeriodicWeatherChecks();
      _logger.i('✅ Alert service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize alert service: $e');
    }
  }

  void _startPeriodicWeatherChecks() {
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

  Future<void> _generateWeatherAlerts(
      Weather weather, Position position) async {
    final List<WeatherAlert> alerts = [];

    if (weather.temperature >= extremeTempThreshold) {
      alerts.add(_createAlert(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Extreme Heat Warning',
        description:
            'Temperature has reached ${weather.temperature}°C. Stay hydrated and avoid prolonged sun exposure.',
        type: AlertType.severe,
        priority: AlertPriority.high,
        position: position,
        expiresIn: const Duration(hours: 6),
        metadata: {'temperature': weather.temperature},
      ));
    } else if (weather.temperature <= freezingTempThreshold) {
      alerts.add(_createAlert(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Freezing Temperature Alert',
        description:
            'Temperature has dropped to ${weather.temperature}°C. Protect pipes and sensitive plants.',
        type: AlertType.advisory,
        priority: AlertPriority.medium,
        position: position,
        expiresIn: const Duration(hours: 6),
        metadata: {'temperature': weather.temperature},
      ));
    }

    if (weather.windSpeed >= highWindThreshold) {
      alerts.add(_createAlert(
        id: 'wind_${DateTime.now().millisecondsSinceEpoch}',
        title: 'High Wind Warning',
        description:
            'Wind speeds of ${weather.windSpeed} km/h detected. Secure outdoor objects.',
        type: AlertType.moderate,
        priority: AlertPriority.medium,
        position: position,
        expiresIn: const Duration(hours: 4),
        metadata: {'windSpeed': weather.windSpeed},
      ));
    }

    if (weather.humidity <= lowHumidityThreshold) {
      alerts.add(_createAlert(
        id: 'humidity_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Low Humidity Alert',
        description:
            'Humidity at ${weather.humidity}%. Increase hydration and skin moisturization.',
        type: AlertType.advisory,
        priority: AlertPriority.low,
        position: position,
        expiresIn: const Duration(hours: 8),
        metadata: {'humidity': weather.humidity},
      ));
    }

    _generateWeatherConditionAlerts(weather, position, alerts);

    for (final alert in alerts) {
      _saveAlertLocally(alert);
      _alertStreamController.add(alert);
    }

    if (alerts.isNotEmpty) {
      _logger.i('🚨 Generated ${alerts.length} weather alerts');
    }
  }

  void _generateWeatherConditionAlerts(
      Weather weather, Position position, List<WeatherAlert> alerts) {
    final mainCondition =
        weather.weather.isNotEmpty ? weather.weather.first.main : '';

    switch (mainCondition.toLowerCase()) {
      case 'thunderstorm':
      case 'squall':
      case 'tornado':
        alerts.add(_createAlert(
          id: 'condition_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Severe Storm Warning',
          description:
              'Severe thunderstorm conditions detected. Seek shelter immediately.',
          type: AlertType.severe,
          priority: AlertPriority.critical,
          position: position,
          expiresIn: const Duration(hours: 3),
          metadata: {'condition': mainCondition},
        ));
        break;
      case 'rain':
      case 'drizzle':
        final rainfall = weather.rain?.oneHour ?? 0.0;
        if (rainfall >= heavyRainThreshold) {
          alerts.add(_createAlert(
            id: 'condition_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Heavy Rain Alert',
            description:
                'Heavy rainfall of ${rainfall}mm detected. Avoid flooded areas.',
            type: AlertType.moderate,
            priority: AlertPriority.high,
            position: position,
            expiresIn: const Duration(hours: 3),
            metadata: {'rainfall': rainfall},
          ));
        }
        break;
      case 'snow':
        alerts.add(_createAlert(
          id: 'condition_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Snow Alert',
          description:
              'Snow conditions detected. Drive carefully and dress warmly.',
          type: AlertType.advisory,
          priority: AlertPriority.medium,
          position: position,
          expiresIn: const Duration(hours: 3),
          metadata: {'condition': mainCondition},
        ));
        break;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        alerts.add(_createAlert(
          id: 'condition_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Reduced Visibility Alert',
          description:
              'Poor visibility conditions detected. Use extra caution when driving.',
          type: AlertType.advisory,
          priority: AlertPriority.medium,
          position: position,
          expiresIn: const Duration(hours: 3),
          metadata: {'condition': mainCondition},
        ));
        break;
    }
  }

  WeatherAlert _createAlert({
    required String id,
    required String title,
    required String description,
    required AlertType type,
    required AlertPriority priority,
    required Position position,
    required Duration expiresIn,
    Map<String, dynamic> metadata = const {},
    String? region,
  }) {
    return WeatherAlert(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(expiresIn),
      latitude: position.latitude,
      longitude: position.longitude,
      region: region,
      metadata: metadata,
    );
  }

  // ── In-memory persistence ─────────────────────────────────────────────────

  void _saveAlertLocally(WeatherAlert alert) {
    // Remove any existing alert with the same id
    _alerts.removeWhere((a) => a.id == alert.id);
    _alerts.insert(0, alert);
    // Keep only the last 50 alerts in memory
    if (_alerts.length > 50) _alerts.removeLast();
    _logger.i('✅ Alert saved locally: ${alert.title}');
  }

  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      final alert = _alerts[index];
      _alerts[index] = WeatherAlert(
        id: alert.id,
        title: alert.title,
        description: alert.description,
        type: alert.type,
        priority: alert.priority,
        issuedAt: alert.issuedAt,
        expiresAt: alert.expiresAt,
        latitude: alert.latitude,
        longitude: alert.longitude,
        region: alert.region,
        metadata: alert.metadata,
        isRead: true,
      );
    }
  }

  void deleteAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    _logger.i('✅ Alert deleted: $alertId');
  }

  List<WeatherAlert> getUserAlerts({bool unreadOnly = false}) {
    final active = _alerts.where((a) => !a.isExpired).toList();
    if (unreadOnly) return active.where((a) => !a.isRead).toList();
    return active;
  }

  Future<void> createDamLevelAlert(
    String damName,
    double currentLevel,
    double criticalLevel,
    String region,
  ) async {
    // Needs a dummy position — use 0,0 since dam alerts are region-based
    final alert = WeatherAlert(
      id: 'dam_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Dam Level Alert: $damName',
      description:
          '$damName is at ${currentLevel.toStringAsFixed(1)}% capacity. '
          'Critical level is ${criticalLevel.toStringAsFixed(1)}%.',
      type: currentLevel < criticalLevel ? AlertType.dam : AlertType.info,
      priority:
          currentLevel < criticalLevel ? AlertPriority.high : AlertPriority.low,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      latitude: 0,
      longitude: 0,
      region: region,
      metadata: {
        'damName': damName,
        'currentLevel': currentLevel,
        'criticalLevel': criticalLevel,
      },
    );

    _saveAlertLocally(alert);
    _alertStreamController.add(alert);
  }

  void dispose() {
    _alertCheckTimer?.cancel();
    _alertStreamController.close();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final alertServiceProvider = Provider<AlertService>((ref) {
  final service = AlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

final alertStreamProvider = StreamProvider<WeatherAlert>((ref) {
  return ref.watch(alertServiceProvider).alertStream;
});

final userAlertsProvider = Provider<List<WeatherAlert>>((ref) {
  return ref.watch(alertServiceProvider).getUserAlerts();
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertServiceProvider).getUserAlerts(unreadOnly: true).length;
});
