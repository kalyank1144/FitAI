import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Application theme configuration.
class AppTheme {
  /// Creates the dark theme for the application.
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppTokens.neonTeal,
      brightness: Brightness.dark,
      background: AppTokens.bg,
      surface: AppTokens.surface,
      primary: AppTokens.neonTeal,
      secondary: AppTokens.neonIndigo,
      error: AppTokens.neonCoral,
      onBackground: AppTokens.onSurface,
      onSurface: AppTokens.onSurface,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.bg,
      textTheme: buildTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Colors.transparent,
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        
      ),
    );
  }
}


/// A widget that creates a gradient border around its child.
class GradientBorder extends StatelessWidget {
  /// Creates a gradient border widget.
  const GradientBorder({
    required this.child,
    super.key,
    this.gradient,
    this.radius = AppTokens.radius,
  });
  
  /// The child widget to wrap with a gradient border.
  final Widget child;
  /// The gradient to use for the border. Defaults to [AppTokens.perfGradient].
  final Gradient? gradient;
  /// The border radius. Defaults to [AppTokens.radius].
  final double radius;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTokens.perfGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius - 1.5),
        ),
        child: child,
      ),
    );
  }
}
