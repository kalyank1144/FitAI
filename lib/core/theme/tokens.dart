import 'package:flutter/material.dart';

/// Design tokens and constants for the application theme.
class AppTokens {
  /// Background color for the app.
  static const Color bg = Color(0xFF0A0B10);
  /// Surface color for cards and containers.
  static const Color surface = Color(0xFF12131A);
  /// Text color on surfaces.
  static const Color onSurface = Color(0xFFE6E8EF);
  /// Primary neon teal color.
  static const Color neonTeal = Color(0xFF00E5FF);
  /// Secondary neon indigo color.
  static const Color neonIndigo = Color(0xFF6C63FF);
  /// Accent neon coral color.
  static const Color neonCoral = Color(0xFFFF5C8A);
  /// Accent neon magenta color.
  static const Color neonMagenta = Color(0xFFFF00B8);

  /// Fast animation duration.
  static const Duration fast = Duration(milliseconds: 200);
  /// Normal animation duration.
  static const Duration normal = Duration(milliseconds: 240);
  /// Slow animation duration.
  static const Duration slow = Duration(milliseconds: 300);

  /// Standard border radius.
  static const double radius = 16;
  /// Standard padding.
  static const double padding = 16;
  /// Standard gap between elements.
  static const double gap = 12;

  /// Performance gradient (teal to indigo).
  static LinearGradient perfGradient = const LinearGradient(
    colors: [neonTeal, neonIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  /// Activity gradient (coral to magenta).
  static LinearGradient activityGradient = const LinearGradient(
    colors: [neonCoral, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Builds a custom text theme based on the provided base theme.
TextTheme buildTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w700,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w700,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w600,
    ),
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
