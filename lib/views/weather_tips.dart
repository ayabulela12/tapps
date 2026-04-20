import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:flutter/material.dart';

class WeatherTips extends StatelessWidget {
  const WeatherTips({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final tips = _buildDynamicTips(weather);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Weather Tips', style: TextStyles.h2),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(tips.length, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == tips.length - 1 ? 0 : 12),
                child: tips[index],
              );
            }),
          ),
        ),
      ],
    );
  }

  List<WeatherTipCard> _buildDynamicTips(Weather weather) {
    final condition = weather.weather.isNotEmpty ? weather.weather.first.main.toLowerCase() : '';
    final tips = <WeatherTipCard>[];

    if (condition.contains('thunderstorm')) {
      tips.add(
        const WeatherTipCard(
          title: 'Storm Safety',
          description: 'Thunderstorms detected. Stay indoors and avoid open areas and metal structures.',
          icon: Icons.thunderstorm,
          color: Colors.redAccent,
        ),
      );
    }

    if (condition.contains('rain') || condition.contains('drizzle')) {
      tips.add(
        const WeatherTipCard(
          title: 'Rain Ready',
          description: 'Rain is expected. Carry rain gear and avoid low-lying flood-prone routes.',
          icon: Icons.umbrella,
          color: Colors.lightBlueAccent,
        ),
      );
    }

    if (weather.main.feelsLike >= 32 || weather.temperature >= 30) {
      tips.add(
        const WeatherTipCard(
          title: 'Heat Precaution',
          description: 'Hot conditions today. Hydrate often and reduce intense outdoor activity at midday.',
          icon: Icons.thermostat,
          color: Colors.orange,
        ),
      );
    }

    if (weather.windSpeed >= 35) {
      tips.add(
        const WeatherTipCard(
          title: 'Wind Advisory',
          description: 'Strong winds expected. Secure loose outdoor items and drive carefully.',
          icon: Icons.air,
          color: Colors.cyanAccent,
        ),
      );
    }

    if (weather.visibilityInKm > 0 && weather.visibilityInKm <= 3) {
      tips.add(
        const WeatherTipCard(
          title: 'Low Visibility',
          description: 'Visibility is reduced. Use headlights and leave extra stopping distance.',
          icon: Icons.visibility_off,
          color: Colors.amber,
        ),
      );
    }

    if (tips.isEmpty) {
      tips.add(
        const WeatherTipCard(
          title: 'Stable Conditions',
          description: 'Conditions look stable right now. It is a good time for routine outdoor tasks.',
          icon: Icons.check_circle_outline,
          color: Colors.greenAccent,
        ),
      );
      tips.add(
        const WeatherTipCard(
          title: 'Stay Prepared',
          description: 'Carry water and check updates later in case local conditions shift.',
          icon: Icons.info_outline,
          color: Colors.blueAccent,
        ),
      );
    }

    return tips.take(3).toList();
  }
}

class WeatherTipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const WeatherTipCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 