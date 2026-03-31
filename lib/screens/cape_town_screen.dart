import 'package:appmaniazar/constants/app_colors.dart';
// import 'package:appmaniazar/services/firebase_service.dart'; // Temporarily disabled
import 'package:appmaniazar/views/gradient_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for Cape Town Metro totals - temporarily disabled
// final capeTownMetroTotalsProvider = StreamProvider((ref) {
//   return ref.watch(firebaseServiceProvider).getCapeTownMetroTotals();
// });

class CapeTownScreen extends ConsumerWidget {
  const CapeTownScreen({super.key});

  Color _getLevelColor(double level) {
    if (level >= 80) {
      return Colors.green;
    } else if (level >= 60) {
      return Colors.yellow.shade700;
    } else if (level >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final metroTotalsAsync = ref.watch(capeTownMetroTotalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Cape Town',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GradientContainer(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cape Town Metro Dam Levels',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Static data while Firebase is disabled
                  Column(
                    children: [
                      _buildLevelCard(
                        'Level This Week',
                        75.2,
                        Icons.water_drop,
                      ),
                      const SizedBox(height: 15),
                      _buildLevelCard(
                        'Level Last Week',
                        74.8,
                        Icons.history,
                      ),
                      const SizedBox(height: 15),
                      _buildLevelCard(
                        'Level Last Year',
                        68.5,
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Key Information',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    'Population',
                    '4.7 million',
                    Icons.people,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    'Area',
                    '2,461 km²',
                    Icons.map,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Major Dams',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDamsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(String title, double level, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: _getLevelColor(level), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${level.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    color: _getLevelColor(level),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDamsList() {
    final dams = [
      {'name': 'Theewaterskloof Dam', 'capacity': '480 million m³'},
      {'name': 'Voëlvlei Dam', 'capacity': '164 million m³'},
      {'name': 'Berg River Dam', 'capacity': '130 million m³'},
      {'name': 'Wemmershoek Dam', 'capacity': '59 million m³'},
      {'name': 'Steenbras Upper Dam', 'capacity': '31.8 million m³'},
      {'name': 'Steenbras Lower Dam', 'capacity': '33.5 million m³'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dams.length,
      itemBuilder: (context, index) {
        final dam = dams[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.water,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dam['name'] as String,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Capacity: ${dam['capacity']}',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
