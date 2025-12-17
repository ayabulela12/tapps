import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/providers/get_weather_by_city_provider.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:jiffy/jiffy.dart';

class SearchHistoryCard extends ConsumerWidget {
  final String location;
  final DateTime timestamp;
  final VoidCallback onTap;

  const SearchHistoryCard({
    super.key,
    required this.location,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherByCityNameProvider(location));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: weatherAsync.when(
          data: (weather) => _buildWeatherInfo(weather),
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(Weather weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyles.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Searched ${Jiffy.parseFromDateTime(timestamp).fromNow()}',
                  style: TextStyles.subtitleText.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Image.network(
                  'https://openweathermap.org/img/w/${weather.icon}.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.cloud,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${weather.temperature.round()}°',
                  style: TextStyles.h2.copyWith(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeatherDetail(
              Icons.water_drop_outlined,
              '${weather.humidity}%',
              'Humidity',
            ),
            _buildWeatherDetail(
              Icons.air,
              '${weather.windSpeed.round()} km/h',
              'Wind',
            ),
            _buildWeatherDetail(
              Icons.visibility_outlined,
              '${((weather.visibility ?? 0) / 1000).toStringAsFixed(1)} km',
              'Visibility',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: TextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Searched ${Jiffy.parseFromDateTime(timestamp).fromNow()}',
                      style: TextStyles.subtitleText.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.cloud_off,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Weather data unavailable: ${error.toString()}',
            style: TextStyles.smallText.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyles.bodyText.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyles.smallText.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
