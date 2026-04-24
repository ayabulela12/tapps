import 'dart:async';

import 'package:appmaniazar/constants/brand_colors.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/providers/current_weather_provider.dart';
import 'package:appmaniazar/providers/get_weather_by_city_provider.dart';
import 'package:appmaniazar/providers/saved_locations_provider.dart';
import 'package:appmaniazar/services/api_helper.dart';
import 'package:appmaniazar/services/places_service.dart';
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
  final PlacesService _placesService = PlacesService();
  Timer? _debounce;
  List<PlaceSearchResult> _suggestions = [];
  bool _isSearchingSuggestions = false;
  int _searchVersion = 0;

  Future<void> _submitLocationQuery(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return;

    // Validate against OpenWeather before saving: if we can't
    // resolve this city/area name to weather data, don't add a card.
    try {
      await ApiHelper.getWeatherByCityName(query);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('City or area not found. Please try a different name.'),
        ),
      );
      return;
    }

    ref.read(savedLocationsProvider.notifier).addLocation(query);
    _searchController.clear();
    setState(() {
      _suggestions = [];
    });
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();

    if (value.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearchingSuggestions = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final int localVersion = ++_searchVersion;
      if (mounted) {
        setState(() {
          _isSearchingSuggestions = true;
        });
      }

      try {
        final results = await _placesService.searchPlaces(value.trim());
        if (!mounted || localVersion != _searchVersion) return;
        setState(() {
          _suggestions = results;
        });
      } catch (_) {
        if (!mounted || localVersion != _searchVersion) return;
        setState(() {
          _suggestions = [];
        });
      } finally {
        if (mounted && localVersion == _searchVersion) {
          setState(() {
            _isSearchingSuggestions = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
                  onChanged: _onQueryChanged,
                  onSubmitted: _submitLocationQuery,
                  decoration: InputDecoration(
                    hintText: 'Search city or area',
                    hintStyle: TextStyles.subtitleText,
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: TextStyles.bodyText,
                ),
              ),
              if (_isSearchingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: Colors.white.withValues(alpha: 0.15)),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 20),
                        title: Text(
                          suggestion.mainText,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          suggestion.secondaryText,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        onTap: () {
                          _searchController.text = suggestion.mainText;
                          _submitLocationQuery(suggestion.mainText);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: savedLocations.isEmpty
                    ? const Center(
                        child: Text(
                          'No locations yet.\nSearch to add a city or area.',
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
                                  color: Colors.red.withValues(alpha: 0.8),
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
                                          .read(
                                              selectedLocationProvider.notifier)
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
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Image.asset(
                                                getWeatherIcon(
                                                  weatherCode:
                                                      weather.weather.first.id,
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
                                    color: Colors.white.withValues(alpha: 0.08),
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
                                    color: Colors.white.withValues(alpha: 0.08),
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
