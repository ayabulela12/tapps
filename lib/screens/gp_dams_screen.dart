import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/services/firebase_service.dart';

class GPDamsScreen extends ConsumerWidget {
  const GPDamsScreen({super.key});

  // Dummy list of Gauteng dams
  static final List<Map<String, dynamic>> _dummyDams = [
    {
      'id': '2',
      'name': 'Hartebeespoort Dam',
      'this_week_level': 62.3,
      'location': 'North West Province Border',
      'capacity': '210 million m³',
    },
    {
      'id': '3',
      'name': 'Roodeplaat Dam',
      'this_week_level': 51.2,
      'location': 'Pretoria',
      'capacity': '80 million m³',
    },
    {
      'id': '4',
      'name': 'Klipvoor Dam',
      'this_week_level': 73.7,
      'location': 'Pretoria',
      'capacity': '120 million m³',
    },
    {
      'id': '5',
      'name': 'Vaalkop Dam',
      'this_week_level': 55.6,
      'location': 'Brits',
      'capacity': '90 million m³',
    },
  ];

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
    // Using Firebase data for Gauteng dams
    final gpDamsAsync = ref.watch(provinceDamsProvider('GP'));

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Gauteng Dams',
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
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            ),
          ),
          child: gpDamsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height - 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error Loading Dams',
                        style: TextStyles.subtitleText.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        style: TextStyles.subtitleText.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (dams) {
              final combinedDams = [...dams, ..._dummyDams];
              
              return combinedDams.isEmpty
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              color: Colors.white.withOpacity(0.6),
                              size: 100,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Dams Found',
                              style: TextStyles.subtitleText.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: combinedDams.length,
                      itemBuilder: (context, index) {
                        final dam = combinedDams[index];
                        final level = (dam['this_week_level'] ?? 0.0).toDouble();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withOpacity(0.1),
                          child: ExpansionTile(
                            title: Text(
                              dam['name'] ?? 'Unknown Dam',
                              style: TextStyles.subtitleText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '${level.toStringAsFixed(1)}%',
                              style: TextStyles.subtitleText.copyWith(
                                color: _getLevelColor(level),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildDetailRow('Location', dam['location'] ?? 'N/A'),
                                    const SizedBox(height: 8),
                                    _buildDetailRow('Capacity', dam['capacity'] ?? 'N/A'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.subtitleText.copyWith(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyles.subtitleText.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
