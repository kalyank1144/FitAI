import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

class AppTheme {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}


class GradientBorder extends StatelessWidget {
  const GradientBorder({required this.child, super.key, this.gradient, this.radius = AppTokens.radius});
  final Widget child;
  final Gradient? gradient;
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