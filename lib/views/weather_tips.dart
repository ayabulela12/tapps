import 'package:flutter/material.dart';
import 'package:appmaniazar/constants/text_styles.dart';

class WeatherTips extends StatelessWidget {
  const WeatherTips({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Weather Tips', style: TextStyles.h2),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              WeatherTipCard(
                title: 'UV Protection',
                description: 'High UV levels today. Use sunscreen and wear protective clothing.',
                icon: Icons.wb_sunny,
                color: Colors.orange,
              ),
              SizedBox(width: 12),
              WeatherTipCard(
                title: 'Stay Hydrated',
                description: 'Remember to drink plenty of water throughout the day.',
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
              SizedBox(width: 12),
              WeatherTipCard(
                title: 'Outdoor Activity',
                description: 'Great conditions for outdoor activities in the afternoon.',
                icon: Icons.directions_walk,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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