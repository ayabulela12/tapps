import 'package:flutter/material.dart';

class BrandColors {
  // New primary colors for main gradient
  static const Color primaryBlue = Color(0xFF1A89CC);  // Updated to #1a89cc
  static const Color secondaryBlue = Color(0xFF23224A); // Updated to #23224a
  
  // Lighter variations for backgrounds and accents
  static const Color primaryLightBlue = Color(0xFF1A8FE3);
  static const Color secondaryLightBlue = Color(0xFF5CCFF3);
  
  // Darker variations for hourly forecast
  static const Color primaryDarkBlue = Color(0xFF0B5A94);  
  static const Color secondaryDarkBlue = Color(0xFF2599C1); 
  
  // Gradient pairs
  static const List<Color> mainGradient = [primaryBlue, secondaryBlue];
  static const List<Color> darkGradient = [primaryDarkBlue, primaryBlue];
}
