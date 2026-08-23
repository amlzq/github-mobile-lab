import 'package:flutter/material.dart';

/// Application themes.
///
/// Seeded from GitHub's near-black brand color; Material 3 generates the
/// full light and dark color schemes.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF24292E);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
