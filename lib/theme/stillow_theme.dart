import 'package:flutter/material.dart';

abstract final class StillowColors {
  static const background = Color(0xFF101615);
  static const backgroundSoft = Color(0xFF151D1C);
  static const surface = Color(0xFF1B2523);
  static const surfaceRaised = Color(0xFF23302D);
  static const linen = Color(0xFFE7DFCC);
  static const linenMuted = Color(0xFFB8B2A3);
  static const sage = Color(0xFF9FB3A4);
  static const sageDeep = Color(0xFF6E887A);
  static const moon = Color(0xFFD8C9A6);
  static const outline = Color(0xFF34433F);
}

abstract final class StillowTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: StillowColors.moon,
      onPrimary: StillowColors.background,
      secondary: StillowColors.sage,
      onSecondary: StillowColors.background,
      surface: StillowColors.surface,
      onSurface: StillowColors.linen,
      outline: StillowColors.outline,
      error: Color(0xFFD8A49E),
    );

    final textTheme = Typography.material2021().white.apply(
      bodyColor: StillowColors.linen,
      displayColor: StillowColors.linen,
      fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei'],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: StillowColors.background,
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.6,
          color: StillowColors.linenMuted,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
      ),
      dividerTheme: const DividerThemeData(
        color: StillowColors.outline,
        thickness: 1,
      ),
    );
  }
}
