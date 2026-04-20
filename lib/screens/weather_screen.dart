import 'dart:async';

import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/providers/current_weather_provider.dart';
import 'package:appmaniazar/screens/weather_locations_screen.dart';
import 'package:appmaniazar/utils/get_weather_icons.dart';
import 'package:appmaniazar/views/alerts_panel.dart';
import 'package:appmaniazar/views/gradient_container.dart';
import 'package:appmaniazar/views/hourly_forecast.dart';
import 'package:appmaniazar/views/weather_info.dart';
import 'package:appmaniazar/views/weather_skeleton.dart';
import 'package:appmaniazar/views/weather_tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen>
    with WidgetsBindingObserver {
  final logger = Logger();
  bool _locationDenied = false;

  void _openLocationSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WeatherLocationsScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask for location permission with a user-facing explanation
    // when the screen first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAskForLocationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When the app comes back to the foreground, refresh the
    // current-location weather and name if we're in "device mode"
    // (i.e. no manual city card is selected).
    if (state == AppLifecycleState.resumed) {
      final selectedCoords = ref.read(selectedCoordinatesProvider);
      if (selectedCoords == null) {
        logger.i('🔄 App resumed; refreshing current location weather + name');
        ref.invalidate(currentWeatherProvider);
        ref.invalidate(currentLocationNameProvider);
      }
    }
  }

  Future<void> _maybeAskForLocationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAsked =
          prefs.getBool('has_asked_location_permission_v1') ?? false;

      // If we've already asked before, just ensure permission is still OK
      // and log if it isn't.
      if (hasAsked) {
        await _checkLocationPermission();
        return;
      }

      if (!mounted) return;

      // Show an explanatory dialog before the system permission prompt.
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Use your location?'),
            content: const Text(
              'We use your device location to show precise weather for where you are right now. '
              'You can always choose a city manually later.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Allow'),
              ),
            ],
          );
        },
      );

      // Remember that we've shown the dialog, regardless of the choice,
      // so we don't keep nagging on every launch.
      await prefs.setBool('has_asked_location_permission_v1', true);

      if (shouldRequest == true) {
        await _checkLocationPermission();
      }
    } catch (e) {
      logger.e('Error showing location permission prompt: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check if location services are enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.w('Location services are disabled');
        if (mounted) setState(() => _locationDenied = true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final denied = permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
      if (denied) {
        logger.w('Location permission denied by user');
      }
      if (mounted) setState(() => _locationDenied = denied);
    } catch (e) {
      logger.e('Error checking location permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final selectedCoordinates = ref.watch(selectedCoordinatesProvider);

    // Get location name from reverse geocoding (exact suburb/town) - only when not using selected coordinates
    final locationNameAsync = selectedCoordinates == null
        ? ref.watch(currentLocationNameProvider)
        : null;

    final weatherData = selectedCoordinates != null
        ? ref.watch(weatherByCoordinatesProvider(selectedCoordinates))
        : ref.watch(currentWeatherProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: weatherData.when(
        data: (weather) {
          try {
            Widget buildLocationText() {
              // Show GPS/geocoder-derived label (not OpenWeather station name)
              if (selectedLocation != null) {
                return Text(
                  selectedLocation,
                  style: TextStyles.h1,
                  overflow: TextOverflow.ellipsis,
                );
              }

              if (locationNameAsync != null) {
                return locationNameAsync.when(
                  data: (name) => Text(
                    name,
                    style: TextStyles.h1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => Text(
                    'Locating...',
                    style: TextStyles.h1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  error: (_, __) => Text(
                    'Current Location',
                    style: TextStyles.h1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }

              return Text(
                'Current Location',
                style: TextStyles.h1,
                overflow: TextOverflow.ellipsis,
              );
            }

            return GradientContainer(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: buildLocationText()),
                          if (_locationDenied)
                            Tooltip(
                              message: 'Location access denied',
                              child: Icon(
                                Icons.location_off,
                                color: Colors.white60,
                                size: 18,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            onPressed: _openLocationSearch,
                          ),
                        ],
                      ),
                    ),
                    if (_locationDenied)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Using a default location. Tap 🔍 to pick your city.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(DateTime.now()),
                      style: TextStyles.subtitleText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Image.asset(
                        getWeatherIcon(weatherCode: weather.weather.first.id),
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.cloud,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°',
                      style: TextStyles.h1.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.weather.first.description,
                      style: TextStyles.h3.copyWith(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'H:${weather.main.tempMax.toStringAsFixed(0)}°  L:${weather.main.tempMin.toStringAsFixed(0)}°',
                      style: TextStyles.subtitleText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather.windSpeed > 20
                                  ? 'Windy conditions expected today. Gusts up to ${weather.windSpeed.toStringAsFixed(1)} km/h.'
                                  : 'Comfortable conditions today with light winds around ${weather.windSpeed.toStringAsFixed(1)} km/h.',
                              style: TextStyles.bodyText,
                            ),
                            const SizedBox(height: 12),
                            const HourlyForecast(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    WeatherInfo(weather: weather),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WeatherTips(weather: weather),
                    ),
                    const SizedBox(height: 16),
                    // Real-time Alerts and Insights Panel
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AlertsPanel(),
                    ),
                    const SizedBox(height: 100), // Extra padding for scroll
                  ],
                ),
              ),
            );
          } catch (e) {
            logger.e('Error building weather UI: $e');
            return const WeatherSkeleton(
              statusText: 'Preparing your weather dashboard...',
              hintText: 'Still loading. Please wait a moment.',
            );
          }
        },
        loading: () => const WeatherSkeleton(
          statusText: 'Loading current weather...',
          hintText: 'We are fetching live updates for your selected location.',
        ),
        error: (error, stackTrace) {
          logger.e('Error loading weather data: $error');
          return GradientContainer(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white70,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load weather right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (selectedCoordinates != null) {
                            ref.invalidate(
                              weatherByCoordinatesProvider(selectedCoordinates),
                            );
                          } else {
                            ref.invalidate(currentWeatherProvider);
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
