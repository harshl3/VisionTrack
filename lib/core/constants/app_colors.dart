import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryNavy = Color(0xFF070B19); // Deep dark blue for background
  static const Color secondaryNavy = Color(0xFF111827); // Elevated dark color
  static const Color accentBlue = Color(0xFF3B82F6); // Professional GIS blue
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);
  
  // Glassmorphism Colors
  static const Color glassBackground = Color(0x77070B19); // 45% opacity dark blue
  static const Color glassSurface = Color(0x22FFFFFF); // Ultra-translucent surface fill
  static const Color glassBorder = Color(0x443B82F6); // Subtle blue border
  static const Color glassBorderGlow = Color(0x883B82F6); // Vibrant glowing border
  static const Color glassCardBg = Color(0x44111827); // Dark translucent card background
  static const Color glassNavBg = Color(0xB3070B19); // Frosted bottom navigation bar background

  // Gradients
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070B19), Color(0xFF0F172A), Color(0xFF1E1B4B)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
  );

  // Marker Colors
  static const Color govtCamera = Color(0xFF38BDF8); // Light Blue
  static const Color privateCamera = Color(0xFF3B82F6); // Solid Blue
  
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color purpleAccent = Color(0xFF8B5CF6);
}
