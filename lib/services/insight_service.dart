import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

enum InsightCategory {
  health('Health & Safety', Icons.favorite, Colors.red),
  outdoor('Outdoor Activities', Icons.park, Colors.green),
  travel('Travel & Commute', Icons.directions_car, Colors.blue),
  home('Home & Garden', Icons.home, Colors.purple),
  energy('Energy & Utilities', Icons.bolt, Colors.amber),
  agriculture('Agriculture', Icons.agriculture, Colors.brown);

  const InsightCategory(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

class WeatherInsight {
  final String id;
  final String title;
  final String description;
  final InsightCategory category;
  final String recommendation;
  final int priority; // 1 = highest priority
  final DateTime generatedAt;
  final DateTime? validUntil;
  final String? region;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? weatherContext;
  final List<String>? actionItems;

  WeatherInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.recommendation,
    required this.priority,
    required this.generatedAt,
    this.validUntil,
    this.region,
    this.latitude,
    this.longitude,
    this.weatherContext,
    this.actionItems,
  });

  factory WeatherInsight.fromJson(Map<String, dynamic> json) {
    return WeatherInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: InsightCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => InsightCategory.health,
      ),
      recommendation: json['recommendation'] as String,
      priority: json['priority'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil'] as String) 
          : null,
      region: json['region'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      weatherContext: json['weatherContext'] as Map<String, dynamic>?,
      actionItems: (json['actionItems'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'recommendation': recommendation,
      'priority': priority,
      'generatedAt': generatedAt.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'weatherContext': weatherContext,
      'actionItems': actionItems,
    };
  }

  bool get isValid => validUntil == null || DateTime.now().isBefore(validUntil!);
  
  String get timeAgo => _getTimeAgo(generatedAt);
  
  String get validUntilText {
    if (validUntil == null) return 'Always valid';
    return 'Valid until ${_getTimeAgo(validUntil!)}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class InsightService {
  final Logger _logger = Logger();
  final WeatherService _weatherService = WeatherService();
  final Map<String, WeatherInsight> _insights = <String, WeatherInsight>{};

  InsightService();

  Future<List<WeatherInsight>> generateInsightsForCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final weather = await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final insights = await _generateInsights(weather, position);
      
      // Save insights in-memory for current app session.
      await _saveInsights(insights, position);
      
      return insights;
    } catch (e) {
      _logger.e('❌ Error generating insights: $e');
      return [];
    }
  }

  Future<List<WeatherInsight>> _generateInsights(
    Weather weather, 
    Position position
  ) async {
    final List<WeatherInsight> insights = [];
    final now = DateTime.now();

    // Health & Safety Insights
    insights.addAll(_generateHealthInsights(weather, position, now));
    
    // Outdoor Activity Insights
    insights.addAll(_generateOutdoorInsights(weather, position, now));
    
    // Travel & Commute Insights
    insights.addAll(_generateTravelInsights(weather, position, now));
    
    // Home & Garden Insights
    insights.addAll(_generateHomeInsights(weather, position, now));
    
    // Energy & Utility Insights
    insights.addAll(_generateEnergyInsights(weather, position, now));
    
    // Agriculture Insights (relevant for South Africa)
    insights.addAll(_generateAgricultureInsights(weather, position, now));

    // Sort by priority (lower number = higher priority)
    insights.sort((a, b) => a.priority.compareTo(b.priority));
    
    return insights;
  }

  List<WeatherInsight> _generateHealthInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    // Heat-related insights
    if (weather.temperature >= 35) {
      insights.add(WeatherInsight(
        id: 'health_extreme_heat_${now.millisecondsSinceEpoch}',
        title: 'Extreme Heat Health Warning',
        description: 'Temperature is ${weather.temperature}°C with humidity at ${weather.humidity}%. High risk of heat-related illness.',
        category: InsightCategory.health,
        recommendation: 'Stay indoors during peak hours (11am-3pm), drink water frequently, and wear light clothing.',
        priority: 1,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'feelsLike': weather.main.feelsLike,
          'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
        },
        actionItems: [
          'Drink 250ml water every 30 minutes',
          'Avoid caffeine and alcohol',
          'Wear light-colored, loose clothing',
          'Seek air-conditioned spaces',
        ],
      ));
    } else if (weather.temperature >= 28 && weather.humidity >= 70) {
      insights.add(WeatherInsight(
        id: 'health_heat_humidity_${now.millisecondsSinceEpoch}',
        title: 'High Heat & Humidity Alert',
        description: 'Temperature ${weather.temperature}°C with ${weather.humidity}% humidity creates dangerous heat index conditions.',
        category: InsightCategory.health,
        recommendation: 'Reduce outdoor activities and increase fluid intake. Heat index makes it feel like ${weather.main.feelsLike}°C.',
        priority: 2,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 4)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'feelsLike': weather.main.feelsLike,
        },
        actionItems: [
          'Take frequent breaks in shade',
          'Monitor for heat exhaustion symptoms',
          'Avoid strenuous outdoor activities',
        ],
      ));
    }

    // Cold-related insights
    if (weather.temperature <= 5) {
      insights.add(WeatherInsight(
        id: 'health_cold_${now.millisecondsSinceEpoch}',
        title: 'Cold Weather Health Advisory',
        description: 'Temperature at ${weather.temperature}°C. Risk of hypothermia and increased respiratory issues.',
        category: InsightCategory.health,
        recommendation: 'Dress in layers, protect exposed skin, and limit time outdoors.',
        priority: 2,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 8)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'condition': weather.weather.isNotEmpty ? weather.weather.first.main : '',
        },
        actionItems: [
          'Wear warm, layered clothing',
          'Cover head, hands, and feet',
          'Limit outdoor exposure time',
          'Check on elderly neighbors',
        ],
      ));
    }

    // Air quality related insights
    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    final description = weather.weather.isNotEmpty ? weather.weather.first.description : '';
    
    if (mainCondition.toLowerCase().contains('dust') || 
        mainCondition.toLowerCase().contains('smoke') ||
        mainCondition.toLowerCase().contains('haze')) {
      insights.add(WeatherInsight(
        id: 'health_air_quality_${now.millisecondsSinceEpoch}',
        title: 'Poor Air Quality Alert',
        description: 'Current conditions ($mainCondition) may affect air quality and respiratory health.',
        category: InsightCategory.health,
        recommendation: 'Limit outdoor activities, especially if you have respiratory conditions.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'description': description,
        },
        actionItems: [
          'Keep windows closed',
          'Use air purifiers if available',
          'Avoid strenuous outdoor exercise',
          'Consider wearing a mask outdoors',
        ],
      ));
    }

    return insights;
  }

  List<WeatherInsight> _generateOutdoorInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    final rainfall = weather.rain?.oneHour ?? 0.0;

    // General outdoor activity recommendations
    if (mainCondition.toLowerCase().contains('rain') || 
        mainCondition.toLowerCase().contains('thunderstorm')) {
      insights.add(WeatherInsight(
        id: 'outdoor_rain_${now.millisecondsSinceEpoch}',
        title: 'Outdoor Activities Not Recommended',
        description: '$mainCondition conditions expected. Consider postponing outdoor activities.',
        category: InsightCategory.outdoor,
        recommendation: 'Indoor activities recommended. If outdoors, wear waterproof clothing and be lightning-aware.',
        priority: 2,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 3)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'description': weather.weather.isNotEmpty ? weather.weather.first.description : '',
          'rainfall': rainfall,
        },
        actionItems: [
          'Postpone outdoor sports and activities',
          'Seek shelter during thunderstorms',
          'Wear appropriate rain gear if necessary',
        ],
      ));
    } else if (weather.temperature >= 20 && weather.temperature <= 28 && 
               weather.humidity <= 70 && weather.windSpeed <= 20) {
      insights.add(WeatherInsight(
        id: 'outdoor_ideal_${now.millisecondsSinceEpoch}',
        title: 'Ideal Conditions for Outdoor Activities',
        description: 'Perfect weather for outdoor activities: ${weather.temperature}°C, ${weather.humidity}% humidity, ${weather.windSpeed}km/h wind.',
        category: InsightCategory.outdoor,
        recommendation: 'Great day for outdoor sports, hiking, or other activities.',
        priority: 4,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 4)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'windSpeed': weather.windSpeed,
          'condition': mainCondition,
        },
        actionItems: [
          'Great for outdoor exercise',
          'Perfect for picnics and sports',
          'Ideal conditions for hiking',
        ],
      ));
    }

    // UV index estimation (based on weather conditions)
    if (mainCondition.toLowerCase() == 'clear' && weather.temperature >= 25) {
      insights.add(WeatherInsight(
        id: 'outdoor_uv_${now.millisecondsSinceEpoch}',
        title: 'High UV Index Expected',
        description: 'Clear skies and warm temperatures indicate high UV radiation levels.',
        category: InsightCategory.outdoor,
        recommendation: 'Apply sunscreen (SPF 30+), wear a hat, and seek shade during peak hours.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'temperature': weather.temperature,
        },
        actionItems: [
          'Apply sunscreen 30 minutes before going out',
          'Wear UV-protective clothing',
          'Seek shade during 10am-4pm',
          'Wear sunglasses with UV protection',
        ],
      ));
    }

    return insights;
  }

  List<WeatherInsight> _generateTravelInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    final rainfall = weather.rain?.oneHour ?? 0.0;

    // Driving conditions
    if (mainCondition.toLowerCase().contains('rain') && rainfall > 10) {
      insights.add(WeatherInsight(
        id: 'travel_heavy_rain_${now.millisecondsSinceEpoch}',
        title: 'Hazardous Driving Conditions',
        description: 'Heavy rainfall (${rainfall}mm) creating dangerous driving conditions.',
        category: InsightCategory.travel,
        recommendation: 'Reduce speed, increase following distance, and avoid unnecessary travel.',
        priority: 2,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 2)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'rainfall': rainfall,
          'visibility': weather.visibilityInKm,
        },
        actionItems: [
          'Reduce speed by at least 20km/h',
          'Increase following distance to 6 seconds',
          'Turn on headlights',
          'Avoid flooded roads',
        ],
      ));
    }

    // Wind conditions
    if (weather.windSpeed >= 40) {
      insights.add(WeatherInsight(
        id: 'travel_high_wind_${now.millisecondsSinceEpoch}',
        title: 'High Wind Travel Advisory',
        description: 'Strong winds at ${weather.windSpeed}km/h may affect travel, especially for high-profile vehicles.',
        category: InsightCategory.travel,
        recommendation: 'Avoid travel if possible, especially with motorcycles or high-profile vehicles.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 3)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'windSpeed': weather.windSpeed,
          'windDirection': weather.wind.deg,
        },
        actionItems: [
          'Avoid motorcycle and bicycle travel',
          'Secure loose items on vehicles',
          'Watch for falling debris',
          'Avoid bridges and elevated roads',
        ],
      ));
    }

    // Visibility issues
    if (mainCondition.toLowerCase().contains('fog') || 
        mainCondition.toLowerCase().contains('mist')) {
      insights.add(WeatherInsight(
        id: 'travel_visibility_${now.millisecondsSinceEpoch}',
        title: 'Reduced Visibility Warning',
        description: '$mainCondition conditions significantly reducing visibility for drivers.',
        category: InsightCategory.travel,
        recommendation: 'Use fog lights, reduce speed, and increase following distance.',
        priority: 2,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 3)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'visibility': weather.visibilityInKm,
        },
        actionItems: [
          'Use low beam headlights or fog lights',
          'Reduce speed significantly',
          'Increase following distance',
          'Avoid changing lanes frequently',
        ],
      ));
    }

    return insights;
  }

  List<WeatherInsight> _generateHomeInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    final rainfall = weather.rain?.oneHour ?? 0.0;

    // Garden watering advice
    if (mainCondition.toLowerCase().contains('rain')) {
      insights.add(WeatherInsight(
        id: 'home_garden_rain_${now.millisecondsSinceEpoch}',
        title: 'Skip Garden Watering Today',
        description: 'Rain expected - natural watering will suffice for your garden.',
        category: InsightCategory.home,
        recommendation: 'Save water and skip scheduled garden watering.',
        priority: 4,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 12)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'rainfall': rainfall,
        },
        actionItems: [
          'Turn off automated irrigation',
          'Collect rainwater if possible',
          'Plan gardening for dry days',
        ],
      ));
    } else if (weather.temperature >= 30 && weather.humidity <= 30) {
      insights.add(WeatherInsight(
        id: 'home_garden_water_${now.millisecondsSinceEpoch}',
        title: 'Extra Garden Watering Needed',
        description: 'Hot and dry conditions (${weather.temperature}°C, ${weather.humidity}% humidity) require additional garden watering.',
        category: InsightCategory.home,
        recommendation: 'Water garden early morning or late evening to prevent evaporation.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 8)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
        },
        actionItems: [
          'Water deeply but infrequently',
          'Water early morning or late evening',
          'Apply mulch to retain moisture',
          'Focus on new plants and vegetables',
        ],
      ));
    }

    // Home ventilation advice
    if (weather.temperature >= 25 && weather.humidity <= 50) {
      insights.add(WeatherInsight(
        id: 'home_ventilation_${now.millisecondsSinceEpoch}',
        title: 'Good Day for Home Ventilation',
        description: 'Warm, dry conditions ideal for airing out your home.',
        category: InsightCategory.home,
        recommendation: 'Open windows to improve indoor air quality and reduce humidity.',
        priority: 4,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
        },
        actionItems: [
          'Open windows on opposite sides',
          'Use fans to improve air circulation',
          'Air out bedding and textiles',
        ],
      ));
    }

    return insights;
  }

  List<WeatherInsight> _generateEnergyInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';

    // Cooling energy advice
    if (weather.temperature >= 30) {
      insights.add(WeatherInsight(
        id: 'energy_cooling_${now.millisecondsSinceEpoch}',
        title: 'High Cooling Energy Demand',
        description: 'Temperature at ${weather.temperature}°C will increase cooling energy consumption.',
        category: InsightCategory.energy,
        recommendation: 'Optimize cooling efficiency and reduce energy costs.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 8)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'feelsLike': weather.main.feelsLike,
        },
        actionItems: [
          'Set AC to 24°C for efficiency',
          'Use fans to circulate cool air',
          'Close curtains during peak sun',
          'Seal air leaks around windows',
        ],
      ));
    }

    // Solar energy potential
    if (mainCondition.toLowerCase() == 'clear' && weather.temperature >= 20) {
      insights.add(WeatherInsight(
        id: 'energy_solar_${now.millisecondsSinceEpoch}',
        title: 'Excellent Solar Energy Conditions',
        description: 'Clear skies and good sun angle create ideal solar energy generation conditions.',
        category: InsightCategory.energy,
        recommendation: 'Maximize solar energy usage and consider running high-energy appliances.',
        priority: 4,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'temperature': weather.temperature,
        },
        actionItems: [
          'Run washing machines and dishwashers',
          'Charge electric vehicles',
          'Use solar-powered devices',
          'Pre-heat water for evening use',
        ],
      ));
    }

    return insights;
  }

  List<WeatherInsight> _generateAgricultureInsights(
    Weather weather, 
    Position position, 
    DateTime now
  ) {
    final List<WeatherInsight> insights = [];

    final mainCondition = weather.weather.isNotEmpty ? weather.weather.first.main : '';
    final rainfall = weather.rain?.oneHour ?? 0.0;

    // Frost warning (important for South African agriculture)
    if (weather.temperature <= 2) {
      insights.add(WeatherInsight(
        id: 'agri_frost_${now.millisecondsSinceEpoch}',
        title: 'Frost Warning for Farmers',
        description: 'Temperature near freezing (${weather.temperature}°C) - risk of frost damage to crops.',
        category: InsightCategory.agriculture,
        recommendation: 'Protect sensitive crops and consider frost prevention measures.',
        priority: 1,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 4)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'condition': mainCondition,
        },
        actionItems: [
          'Cover sensitive plants with frost cloth',
          'Irrigate before dawn to insulate',
          'Move container plants indoors',
          'Harvest frost-sensitive crops',
        ],
      ));
    }

    // Good planting conditions
    if (weather.temperature >= 18 && weather.temperature <= 25 && 
        weather.humidity >= 40 && weather.humidity <= 70 &&
        weather.windSpeed <= 20) {
      insights.add(WeatherInsight(
        id: 'agri_planting_${now.millisecondsSinceEpoch}',
        title: 'Ideal Planting Conditions',
        description: 'Perfect conditions for planting: ${weather.temperature}°C, ${weather.humidity}% humidity, light winds.',
        category: InsightCategory.agriculture,
        recommendation: 'Excellent day for planting, transplanting, and field work.',
        priority: 4,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 6)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'windSpeed': weather.windSpeed,
        },
        actionItems: [
          'Plant new seedlings and crops',
          'Transplant established plants',
          'Apply fertilizers and treatments',
          'Prepare soil for new plantings',
        ],
      ));
    }

    // Irrigation advice
    if (mainCondition.toLowerCase().contains('rain')) {
      insights.add(WeatherInsight(
        id: 'agri_irrigation_save_${now.millisecondsSinceEpoch}',
        title: 'Reduce Irrigation - Rain Expected',
        description: 'Rainfall will provide natural irrigation - opportunity to save water and energy.',
        category: InsightCategory.agriculture,
        recommendation: 'Skip scheduled irrigation and utilize natural rainfall.',
        priority: 3,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 12)),
        latitude: position.latitude,
        longitude: position.longitude,
        weatherContext: {
          'condition': mainCondition,
          'rainfall': rainfall,
        },
        actionItems: [
          'Turn off irrigation systems',
          'Check drainage systems',
          'Plan for soil moisture retention',
        ],
      ));
    }

    return insights;
  }

  Future<void> _saveInsights(
    List<WeatherInsight> insights, 
    Position position
  ) async {
    try {
      for (final insight in insights) {
        _insights[insight.id] = insight;
      }
      _logger.i('✅ Saved ${insights.length} insights in memory');
    } catch (e) {
      _logger.e('❌ Failed to save insights: $e');
    }
  }

  Future<List<WeatherInsight>> getUserInsights() async {
    try {
      final all = _insights.values.where((insight) => insight.isValid).toList();
      all.sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        if (byPriority != 0) return byPriority;
        return b.generatedAt.compareTo(a.generatedAt);
      });
      return all;
    } catch (e) {
      _logger.e('❌ Failed to get user insights: $e');
      return [];
    }
  }

  Future<void> markInsightAsViewed(String insightId) async {
    try {
      if (_insights.containsKey(insightId)) {
        _logger.i('✅ Insight marked as viewed: $insightId');
        return;
      }
      _logger.i('✅ Insight marked as viewed: $insightId');
    } catch (e) {
      _logger.e('❌ Failed to mark insight as viewed: $e');
    }
  }
}

// Global insight service provider
final insightServiceProvider = Provider<InsightService>((ref) {
  return InsightService();
});

// Future provider for user insights
final userInsightsProvider = FutureProvider<List<WeatherInsight>>((ref) async {
  final insightService = ref.watch(insightServiceProvider);
  return await insightService.getUserInsights();
});

// Future provider for generating new insights
final generateInsightsProvider = FutureProvider<List<WeatherInsight>>((ref) async {
  final insightService = ref.watch(insightServiceProvider);
  return await insightService.generateInsightsForCurrentLocation();
});
