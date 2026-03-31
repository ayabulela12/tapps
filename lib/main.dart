import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// Using the existing FirebaseConfig from config/firebase_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appmaniazar/config/firebase_config.dart';
import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/services/alert_service.dart';
import 'package:appmaniazar/screens/home_screen.dart';
import 'package:appmaniazar/screens/pick_location_screen.dart';
import 'package:appmaniazar/screens/provinces_screen.dart';
import 'package:appmaniazar/screens/report_screen.dart';
import 'package:appmaniazar/screens/search_screen.dart';
import 'package:appmaniazar/screens/weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar color and style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  try {
    // Check if Firebase is already initialized (Android auto-initializes via google-services.json)
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        // Web configuration - manual initialization required
        await Firebase.initializeApp(
          options: FirebaseConfig.webOptions,
        );

        // Configure Firestore settings with optimized cache and persistence
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 10485760, // 10 MB cache limit
        );
      } else {
        // Mobile configuration - initialize only if not already done by google-services.json
        await Firebase.initializeApp();
        
        // Configure Firestore settings for mobile
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 10485760, // 10 MB cache limit
        );
      }
      debugPrint('✅ Firebase initialized successfully');
    } else {
      // Firebase already initialized (likely by google-services.json on Android)
      debugPrint('✅ Firebase already initialized');
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize Firebase: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${e.toString().split('.').first}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Reload the app
                      main();
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: AppColors.background,
        platform: kIsWeb ? TargetPlatform.android : Theme.of(context).platform,
      ),
      routes: {
        '/': (context) => const MainScreen(),
        '/search': (context) => const SearchScreen(),
        '/pick_location': (context) => const PickLocationScreen(),
      },
      initialRoute: '/',
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const WeatherScreen(),
    const ProvincesScreen(),
     const ReportScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildWeatherTabIcon() {
    return Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(unreadAlertsCountProvider);
        
        return Stack(
          children: [
            Icon(
              _selectedIndex == 1 ? Icons.wb_sunny : Icons.wb_sunny_outlined,
              size: 28,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        color: AppColors.primaryBlue,
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildWeatherTabIcon(),
              label: 'Weather',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined, size: 28),
              activeIcon: Icon(Icons.location_on, size: 28),
              label: 'Provinces',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined, size: 28),
              activeIcon: Icon(Icons.report, size: 28),
              label: 'Report',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.5),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          iconSize: 28,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
