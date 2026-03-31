import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/extensions/int.dart';
import 'package:appmaniazar/providers/hourly_weather_provider.dart';
import 'package:appmaniazar/utils/get_weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HourlyForecast extends ConsumerWidget {
  const HourlyForecast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyWeatherData = ref.watch(hourlyWeatherProvider);

    return hourlyWeatherData.when(
      data: (hourlyWeather) {
        if (hourlyWeather.list.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return SizedBox(
          height: 120,
          child: ListView.builder(
            itemCount: hourlyWeather.list.length,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final entry = hourlyWeather.list[index];
              final weather = entry.weather.first;
              return HourlyForcastTitle(
                id: weather.id,
                hour: entry.dt.time,
                temp: entry.main.temp.round(),
                isActive: index == 0,
              );
            },
          ),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Text(
            'Unable to load forecast',
            style: TextStyles.subtitleText.copyWith(color: Colors.red),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

class HourlyForcastTitle extends StatelessWidget {
  const HourlyForcastTitle({
    super.key,
    required this.id,
    required this.hour,
    required this.temp,
    required this.isActive,
  });

  final int id;
  final String hour;
  final int temp;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.lightBlue : AppColors.accentBlue,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hour,
              style: TextStyles.subtitleText.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Image.asset(
              getWeatherIcon(weatherCode: id),
              width: 30,
              height: 30,
            ),
            const SizedBox(height: 8),
            Text(
              '$temp°',
              style: TextStyles.h3.copyWith(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
