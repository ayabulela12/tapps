import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:appmaniazar/screens/ec_dams_screen.dart';
import 'package:appmaniazar/screens/fs_dams_screen.dart';
import 'package:appmaniazar/screens/gp_dams_screen.dart';
import 'package:appmaniazar/screens/kzn_dams_screen.dart';
import 'package:appmaniazar/screens/lp_dams_screen.dart';
import 'package:appmaniazar/screens/mp_dams_screen.dart';
import 'package:appmaniazar/screens/nc_dams_screen.dart';
import 'package:appmaniazar/screens/nw_dams_screen.dart';
import 'package:appmaniazar/screens/wc_dams_screen.dart';
import 'package:appmaniazar/screens/city_of_cape_town_screen.dart';
import 'package:appmaniazar/screens/nelson_mandela_metro_screen.dart';
import 'package:appmaniazar/screens/ethekwini_municipality_screen.dart';
import 'package:appmaniazar/services/firebase_service.dart';

class ProvinceDetailsScreen extends ConsumerWidget {
  final String provinceName;
  final String provinceCode;

  const ProvinceDetailsScreen({
    super.key,
    required this.provinceName,
    required this.provinceCode,
  });

  Color _getLevelColor(double level) {
    
    if (level >= 80) return const Color(0xFF4CAF50); // Green
    if (level >= 60) return const Color(0xFFFFC107); // Amber
    if (level >= 40) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provinceTotalsAsync = ref.watch(provinceTotalsProvider(provinceCode));

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content with scrolling
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 180), // Space for buttons
                  child: provinceTotalsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (error, stackTrace) {
                      debugPrint('Error loading province data: $error');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load province data',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your internet connection and try again.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.refresh(provinceTotalsProvider(provinceCode));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0D47A1),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    data: (provinceRecord) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          // Back button and title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provinceName,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Lottie animation
                          SizedBox(
                            height: 180,
                            child: Lottie.network(
                              'https://assets6.lottiefiles.com/packages/lf20_8opq8ij6.json',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.water_drop,
                                  size: 80,
                                  color: Colors.white,
                                );
                              },
                              frameBuilder: (context, child, composition) {
                                if (composition == null) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                return child;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dam Level % title with background
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DAM LEVEL %',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Level cards with padding
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildLevelCard(
                              'This Week',
                              provinceRecord.thisWeekLevel,
                              _getLevelColor(provinceRecord.thisWeekLevel),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildLevelCard(
                              'Last Week',
                              provinceRecord.lastWeekLevel,
                              _getLevelColor(provinceRecord.lastWeekLevel),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildLevelCard(
                              'Last Year',
                              provinceRecord.lastYearLevel,
                              _getLevelColor(provinceRecord.lastYearLevel),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              // Fixed bottom buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View All Dams button for all provinces
                        _buildButton(
                          context,
                          'VIEW ALL DAMS',
                          () {
                            switch (provinceCode) {
                              case 'WC':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const WCDamsScreen()),
                                );
                                break;
                              case 'EC':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ECDamsScreen()),
                                );
                                break;
                              case 'FS':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FSDamsScreen()),
                                );
                                break;
                              case 'KZN':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const KZNDamsScreen()),
                                );
                                break;
                              case 'GP':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GPDamsScreen()),
                                );
                                break;
                              case 'MP':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MPDamsScreen()),
                                );
                                break;
                              case 'LP':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LPDamsScreen()),
                                );
                                break;
                              case 'NC':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NCDamsScreen()),
                                );
                                break;
                              case 'NW':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NWDamsScreen()),
                                );
                                break;
                            }
                          },
                        ),
                        
                        // Metro buttons for specific provinces
                        if (provinceCode == 'WC')
                          _buildButton(
                            context,
                            'CITY OF CAPE TOWN',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CityOfCapeTownScreen()),
                              );
                            },
                            isSecondary: true,
                          )
                        else if (provinceCode == 'EC')
                          _buildButton(
                            context,
                            'NELSON MANDELA BAY',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NelsonMandelaMetroScreen()),
                              );
                            },
                            isSecondary: true,
                          )
                        else if (provinceCode == 'KZN')
                          _buildButton(
                            context,
                            'ETHEKWINI MUNICIPALITY',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EThekwiniMunicipalityScreen()),
                              );
                            },
                            isSecondary: true,
                          ),
                      ].whereType<Widget>().toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(String label, double? value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)}%' : 'N/A',
            style: GoogleFonts.outfit(
              color: value != null ? color : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    bool isSecondary = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isSecondary ? Colors.transparent : Colors.white,
          foregroundColor: isSecondary ? Colors.white : const Color(0xFF0D47A1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSecondary
                ? const BorderSide(color: Colors.white, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSecondary ? Colors.white : const Color(0xFF0D47A1),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
























// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart';
// import 'package:appmaniazar/constants/app_colors.dart';
// import 'package:appmaniazar/screens/ec_dams_screen.dart';
// import 'package:appmaniazar/screens/fs_dams_screen.dart';
// import 'package:appmaniazar/screens/gp_dams_screen.dart';
// import 'package:appmaniazar/screens/kzn_dams_screen.dart';
// import 'package:appmaniazar/screens/lp_dams_screen.dart';
// import 'package:appmaniazar/screens/mp_dams_screen.dart';
// import 'package:appmaniazar/screens/nc_dams_screen.dart';
// import 'package:appmaniazar/screens/nw_dams_screen.dart';
// import 'package:appmaniazar/screens/wc_dams_screen.dart';
// import 'package:appmaniazar/screens/city_of_cape_town_screen.dart';
// import 'package:appmaniazar/screens/nelson_mandela_metro_screen.dart';
// import 'package:appmaniazar/screens/ethekwini_municipality_screen.dart';
// import 'package:appmaniazar/services/firebase_service.dart';
// import 'package:appmaniazar/views/gradient_container.dart';

// class ProvinceDetailsScreen extends ConsumerWidget {
//   final String provinceName;
//   final String provinceCode;

//   const ProvinceDetailsScreen({
//     super.key,
//     required this.provinceName,
//     required this.provinceCode,
//   });

//   Color _getLevelColor(double level) {
//     if (level >= 80) return const Color(0xFF4CAF50); // Green
//     if (level >= 60) return const Color(0xFFFFC107); // Amber
//     if (level >= 40) return const Color(0xFFFF9800); // Orange
//     return const Color(0xFFF44336); // Red
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final provinceTotalsAsync = ref.watch(provinceTotalsProvider(provinceCode));

//     // Set status bar style
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ));

//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Main content with scrolling
//               SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: Padding(
//                   padding: const EdgeInsets.only(bottom: 180), // Space for buttons
//                   child: provinceTotalsAsync.when(
//                     loading: () => const Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(32.0),
//                         child: CircularProgressIndicator(color: Colors.white),
//                       ),
//                     ),
//                     error: (error, stackTrace) {
//                       debugPrint('Error loading province data: $error');
//                       return Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(32.0),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Failed to load province data',
//                                 style: GoogleFonts.outfit(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Please check your internet connection and try again.',
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
//                               ),
//                               const SizedBox(height: 16),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   ref.refresh(provinceTotalsProvider(provinceCode));
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.white,
//                                   foregroundColor: const Color(0xFF0D47A1),
//                                 ),
//                                 child: const Text('Retry'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                     data: (provinceRecord) {
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 10),
//                         // Back button and title
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
//                                 onPressed: () => Navigator.pop(context),
//                                 padding: EdgeInsets.zero,
//                                 constraints: const BoxConstraints(),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   provinceName,
//                                   style: GoogleFonts.outfit(
//                                     color: Colors.white,
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     height: 1.2,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         // Lottie animation
//                         SizedBox(
//                           height: 180,
//                           child: Lottie.network(
//                             'https://assets6.lottiefiles.com/packages/lf20_8opq8ij6.json',
//                             fit: BoxFit.contain,
//                             errorBuilder: (context, error, stackTrace) {
//                               return const Icon(
//                                 Icons.water_drop,
//                                 size: 80,
//                                 color: Colors.white,
//                               );
//                             },
//                             frameBuilder: (context, child, composition) {
//                               if (composition == null) {
//                                 return const Center(
//                                   child: SizedBox(
//                                     width: 40,
//                                     height: 40,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                       strokeWidth: 2,
//                                     ),
//                                   ),
//                                 );
//                               }
//                               return child;
//                             },
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         // Dam Level % title with background
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                               vertical: 10,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               'DAM LEVEL %',
//                               style: GoogleFonts.outfit(
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 1.2,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         // Level cards with padding
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: _buildLevelCard(
//                             'This Week',
//                             provinceRecord.thisWeekLevel,
//                             _getLevelColor(provinceRecord.thisWeekLevel),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: _buildLevelCard(
//                             'Last Week',
//                             provinceRecord.lastWeekLevel,
//                             _getLevelColor(provinceRecord.lastWeekLevel),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: _buildLevelCard(
//                             'Last Year',
//                             provinceRecord.lastYearLevel,
//                             _getLevelColor(provinceRecord.lastYearLevel),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
          
//           // Fixed bottom buttons
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               padding: const EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 20,
//                 bottom: 16,
//               ),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.9),
//                   ],
//                 ),
//               ),
//               child: SafeArea(
//                 top: false,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // View All Dams button for all provinces
//                     _buildButton(
//                       context,
//                       'VIEW ALL DAMS',
//                       () {
//                         switch (provinceCode) {
//                           case 'WC':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const WCDamsScreen()),
//                             );
//                             break;
//                           case 'EC':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const ECDamsScreen()),
//                             );
//                             break;
//                           case 'FS':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const FSDamsScreen()),
//                             );
//                             break;
//                           case 'KZN':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const KZNDamsScreen()),
//                             );
//                             break;
//                           case 'GP':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const GPDamsScreen()),
//                             );
//                             break;
//                           case 'MP':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const MPDamsScreen()),
//                             );
//                             break;
//                           case 'LP':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const LPDamsScreen()),
//                             );
//                             break;
//                           case 'NC':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const NCDamsScreen()),
//                             );
//                             break;
//                           case 'NW':
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const NWDamsScreen()),
//                             );
//                             break;
//                         }
//                       },
//                     ),
                    
//                     // Metro buttons for specific provinces
//                     if (provinceCode == 'WC')
//                       _buildButton(
//                         context,
//                         'CITY OF CAPE TOWN',
//                         () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const CityOfCapeTownScreen()),
//                           );
//                         },
//                         isSecondary: true,
//                       )
//                     else if (provinceCode == 'EC')
//                       _buildButton(
//                         context,
//                         'NELSON MANDELA BAY',
//                         () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const NelsonMandelaMetroScreen()),
//                           );
//                         },
//                         isSecondary: true,
//                       )
//                     else if (provinceCode == 'KZN')
//                       _buildButton(
//                         context,
//                         'ETHEKWINI MUNICIPALITY',
//                         () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const EThekwiniMunicipalityScreen()),
//                           );
//                         },
//                         isSecondary: true,
//                       ),
//                   ].whereType<Widget>().toList(),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLevelCard(String label, double? value, Color color) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.05),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label.toUpperCase(),
//             style: GoogleFonts.outfit(
//               color: Colors.white.withOpacity(0.9),
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.5,
//             ),
//           ),
//           Text(
//             value != null ? '${value.toStringAsFixed(1)}%' : 'N/A',
//             style: GoogleFonts.outfit(
//               color: value != null ? color : Colors.white70,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildButton(
//     BuildContext context,
//     String label,
//     VoidCallback onPressed, {
//     bool isSecondary = false,
//   }) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 10),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           backgroundColor: isSecondary ? Colors.transparent : Colors.white,
//           foregroundColor: isSecondary ? Colors.white : const Color(0xFF0D47A1),
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: isSecondary
//                 ? const BorderSide(color: Colors.white, width: 1.5)
//                 : BorderSide.none,
//           ),
//         ),
//         child: Text(
//           label,
//           style: GoogleFonts.outfit(
//             color: isSecondary ? Colors.white : const Color(0xFF0D47A1),
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.5,
//           ),
//         ),
//       ),
//     );
//   }
// }
