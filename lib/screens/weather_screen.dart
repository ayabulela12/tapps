import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/extensions/datetime.dart';
import 'package:appmaniazar/providers/current_weather_provider.dart';
import 'package:appmaniazar/views/gradient_container.dart';
import 'package:appmaniazar/views/hourly_forecast.dart';
import 'package:appmaniazar/views/location_search.dart';
import 'package:appmaniazar/views/weather_info.dart';
import 'package:appmaniazar/views/weather_skeleton.dart';
import 'package:appmaniazar/views/weather_tips.dart';
import 'package:appmaniazar/utils/get_weather_icons.dart';

final selectedLocationProvider = StateProvider<String?>((ref) => null);
final selectedCoordinatesProvider = StateProvider<({double lat, double lon})?>((ref) => null);

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          logger.w('Location permission denied by user');
        }
      }
      
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.w('Location services are disabled');
      }
    } catch (e) {
      logger.e('Error checking location permission: $e');
    }
  }

  void _onLocationSelected(WidgetRef ref, String location) async {
    try {
      final placesService = ref.read(placesServiceProvider);
      final coordinates = await placesService.getLocationFromAddress(location);
      ref.read(selectedLocationProvider.notifier).state = location;
      ref.read(selectedCoordinatesProvider.notifier).state = (
        lat: coordinates.lat,
        lon: coordinates.lon,
      );
    } catch (e) {
      logger.e('Error getting location coordinates: $e');
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
            return GradientContainer(
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Show exact location name from reverse geocoding, or selected location, or weather API name
                          selectedLocation != null
                              ? Text(
                                  selectedLocation!,
                                  style: TextStyles.h1,
                                  textAlign: TextAlign.center,
                                )
                              : locationNameAsync != null
                                  ? locationNameAsync.when(
                                      data: (name) {
                                        // Only use reverse geocoded name if it's not "Unknown Location"
                                        final displayName = (name != 'Unknown Location' && name.isNotEmpty)
                                            ? name
                                            : weather.name;
                                        return Text(
                                          displayName,
                                          style: TextStyles.h1,
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                      loading: () => Text(
                                        weather.name,
                                        style: TextStyles.h1,
                                        textAlign: TextAlign.center,
                                      ),
                                      error: (_, __) => Text(
                                        weather.name,
                                        style: TextStyles.h1,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : Text(
                                      weather.name,
                                      style: TextStyles.h1,
                                      textAlign: TextAlign.center,
                                    ),
                          const SizedBox(height: 8),
                          Text(
                            DateTime.now().dateTime,
                            style: TextStyles.subtitleText,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 160,
                            child: Image.asset(
                              getWeatherIcon(weatherCode: weather.id),
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.cloud,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            weather.weather.first.description,
                            style: TextStyles.h3,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      WeatherInfo(weather: weather),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Today', style: TextStyles.h2),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Next 7 Days >',
                                style: TextStyles.buttonText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const HourlyForecast(),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: WeatherTips(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          } catch (e) {
            logger.e('Error building weather UI: $e');
            return const WeatherSkeleton();
          }
        },
        loading: () => const WeatherSkeleton(),
        error: (error, stackTrace) {
          logger.e('Error loading weather data: $error');
          return const WeatherSkeleton();
        },
      ),
    );
  }
}
