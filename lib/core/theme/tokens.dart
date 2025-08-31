import 'package:flutter/material.dart';

class AppTokens {
  static const Color bg = Color(0xFF0A0B10);
  static const Color surface = Color(0xFF12131A);
  static const Color onSurface = Color(0xFFE6E8EF);
  static const Color neonTeal = Color(0xFF00E5FF);
  static const Color neonIndigo = Color(0xFF6C63FF);
  static const Color neonCoral = Color(0xFFFF5C8A);
  static const Color neonMagenta = Color(0xFFFF00B8);

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 300);

  static const double radius = 16;
  static const double padding = 16;
  static const double gap = 12;

  static LinearGradient perfGradient = const LinearGradient(
    colors: [neonTeal, neonIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient activityGradient = const LinearGradient(
    colors: [neonCoral, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

TextTheme buildTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontFamily: 'Urbanist', fontWeight: FontWeight.w700),
    displayMedium: base.displayMedium?.copyWith(fontFamily: 'Urbanist', fontWeight: FontWeight.w700),
    displaySmall: base.displaySmall?.copyWith(fontFamily: 'Urbanist', fontWeight: FontWeight.w600),
    headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Urbanist'),
    headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Urbanist'),
    headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Urbanist'),
    titleLarge: base.titleLarge?.copyWith(fontFamily: 'Urbanist'),
    titleMedium: base.titleMedium?.copyWith(fontFamily: 'Urbanist'),
    titleSmall: base.titleSmall?.copyWith(fontFamily: 'Urbanist'),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Inter'),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Inter'),
    bodySmall: base.bodySmall?.copyWith(fontFamily: 'Inter'),
    labelLarge: base.labelLarge?.copyWith(fontFamily: 'Inter'),
    labelMedium: base.labelMedium?.copyWith(fontFamily: 'Inter'),
    labelSmall: base.labelSmall?.copyWith(fontFamily: 'Inter'),
  );
}