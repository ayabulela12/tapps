import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/constants/text_styles.dart';
import 'package:appmaniazar/services/supabase_dam_service.dart';

class ECDamsScreen extends ConsumerWidget {
  const ECDamsScreen({super.key});

  // Dummy list of Eastern Cape dams
  static final List<Map<String, dynamic>> _dummyDams = [
    {
      'id': '2',
      'name': 'Kouga Dam',
      'this_week_level': 72.3,
      'location': 'Baviaanskloof',
      'capacity': '180 million m³',
    },
    {
      'id': '3',
      'name': 'Groendal Dam',
      'this_week_level': 51.2,
      'location': 'Uitenhage',
      'capacity': '45 million m³',
    },
    {
      'id': '4',
      'name': 'Impofu Dam',
      'this_week_level': 63.7,
      'location': 'Port Elizabeth',
      'capacity': '75 million m³',
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
    // Using Firebase data for Eastern Cape dams
    final ecDamsAsync = ref.watch(provinceDamsProvider('EC'));

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Eastern Cape Dams',
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
          child: ecDamsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Dams',
                    style: TextStyles.subtitleText.copyWith(color: Colors.white),
                  ),
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
            data: (dams) {
              final combinedDams = [...dams, ..._dummyDams];
              
              return combinedDams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 100,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Dams Found',
                            style: TextStyles.subtitleText.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
                      itemCount: combinedDams.length,
                      itemBuilder: (context, index) {
                        final dam = combinedDams[index];
                        final level = (dam['this_week_level'] ?? 0.0).toDouble();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withValues(alpha: 0.1),
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
