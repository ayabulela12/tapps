import 'package:appmaniazar/constants/brand_colors.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/providers/current_weather_provider.dart';
import 'package:appmaniazar/providers/get_weather_by_city_provider.dart';
import 'package:appmaniazar/providers/saved_locations_provider.dart';
import 'package:appmaniazar/services/api_helper.dart';
import 'package:appmaniazar/utils/get_weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherLocationsScreen extends ConsumerStatefulWidget {
  const WeatherLocationsScreen({super.key});

  @override
  ConsumerState<WeatherLocationsScreen> createState() =>
      _WeatherLocationsScreenState();
}

class _WeatherLocationsScreenState
    extends ConsumerState<WeatherLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedLocations = ref.watch(savedLocationsProvider);

    return Scaffold(
      backgroundColor: BrandColors.primaryBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrandColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Weather',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: BrandColors.mainGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) async {
                    final city = value.trim();
                    if (city.isEmpty) return;
                    // Known South African provinces – we don't want to add these
                    // as "cities", so show a friendly error instead.
                    const provinces = {
                      'western cape',
                      'eastern cape',
                      'northern cape',
                      'gauteng',
                      'limpopo',
                      'mpumalanga',
                      'north west',
                      'free state',
                      'kwa zulu natal',
                      'kwazulu-natal',
                    };

                    final lower = city.toLowerCase();
                    if (provinces.contains(lower)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('City not found. Please search for a city or town, not a province.'),
                        ),
                      );
                      return;
                    }

                    // Validate against OpenWeather before saving: if we can't
                    // resolve this name to weather data, don't add a card.
                    try {
                      await ApiHelper.getWeatherByCityName(city);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('City not found. Please try a different city name.'),
                        ),
                      );
                      return;
                    }

                    ref
                        .read(savedLocationsProvider.notifier)
                        .addLocation(city);
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a city',
                    hintStyle: TextStyles.subtitleText,
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: TextStyles.bodyText,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: savedLocations.isEmpty
                    ? const Center(
                        child: Text(
                          'No locations yet.\nSearch to add a city.',
                          style: TextStyles.subtitleText,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          top: 8,
                        ),
                        itemCount: savedLocations.length,
                        itemBuilder: (context, index) {
                          final location = savedLocations[index];
                          // Use the full saved label (often "Suburb, City")
                          // when querying weather, so OpenWeather can use the
                          // more precise place name.
                          final weatherAsync =
                              ref.watch(weatherByCityNameProvider(location));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(location),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              onDismissed: (_) {
                                ref
                                    .read(savedLocationsProvider.notifier)
                                    .removeLocation(location);
                              },
                              child: weatherAsync.when(
                                data: (weather) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      ref
                                          .read(selectedLocationProvider
                                              .notifier)
                                          .state = location;
                                      ref
                                          .read(selectedCoordinatesProvider
                                              .notifier)
                                          .state = (
                                        lat: weather.coord.lat,
                                        lon: weather.coord.lon,
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF3A7BD5),
                                            Color(0xFF00D2FF),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                location,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                weather
                                                    .weather.first.description,
                                                style: TextStyles.bodyText,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'H:${weather.main.tempMax.toStringAsFixed(0)}°  L:${weather.main.tempMin.toStringAsFixed(0)}°',
                                                style: TextStyles.subtitleText,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${weather.temperature.toStringAsFixed(0)}°',
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight:
                                                      FontWeight.w300,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Image.asset(
                                                getWeatherIcon(
                                                  weatherCode: weather
                                                      .weather.first.id,
                                                ),
                                                width: 40,
                                                height: 40,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                loading: () => Container(
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                error: (_, __) => Container(
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    location,
                                    style: TextStyles.bodyText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

