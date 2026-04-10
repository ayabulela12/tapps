import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/services/supabase_dam_service.dart';
import 'package:appmaniazar/views/gradient_container.dart';

class DamDetailsScreen extends ConsumerWidget {
  final String damId;
  final String collection;

  const DamDetailsScreen({
    super.key,
    required this.damId,
    this.collection = 'WCDams',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final damAsync = ref.watch(specificDamProvider({
      'damId': damId,
      'collection': collection,
    }));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Dam Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientContainer(
        children: [
          damAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading dam details: $error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (dam) {
              if (dam == null) {
                return const Center(
                  child: Text(
                    'Dam not found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      title: dam['name'] ?? 'Unknown Dam',
                      icon: Icons.water_drop,
                      color: _getLevelColor(dam['this_week_level'] ?? 0.0),
                      children: [
                        _buildInfoRow('Current Level', '${dam['this_week_level']?.toStringAsFixed(1) ?? 'N/A'}%'),
                        _buildInfoRow('Last Week', '${dam['last_week_level']?.toStringAsFixed(1) ?? 'N/A'}%'),
                        _buildInfoRow('Last Year', '${dam['last_year_level']?.toStringAsFixed(1) ?? 'N/A'}%'),
                        const Divider(),
                        _buildInfoRow('Location', dam['location'] ?? 'N/A'),
                        _buildInfoRow('Capacity', dam['capacity'] ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Add more details or actions here
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level) {
    if (level >= 80) return Colors.green;
    if (level >= 60) return Colors.lightGreen;
    if (level >= 40) return Colors.orange;
    return Colors.red;
  }
}
