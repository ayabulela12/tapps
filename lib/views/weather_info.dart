import 'package:flutter/material.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/models/weather.dart';

class WeatherInfo extends StatelessWidget {
  const WeatherInfo({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WeatherInfoTitle(
            title: 'Temp', 
            value: '${weather.temperature.toStringAsFixed(1)}°C'
          ),
          WeatherInfoTitle(
            title: 'Wind', 
            value: '${weather.windSpeed.toStringAsFixed(1)} km/h'
          ),
          WeatherInfoTitle(
            title: 'Humidity', 
            value: '${weather.humidity}%'
          ),
        ],
      ),
    );
  }
}

class WeatherInfoTitle extends StatelessWidget {
  const WeatherInfoTitle({
    super.key, 
    required this.title, 
    required this.value
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyles.subtitleText),
        const SizedBox(height: 10),
        Text(value, style: TextStyles.h3),
      ],
    );
  }
}
