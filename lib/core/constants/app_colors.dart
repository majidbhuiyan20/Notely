import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFFC107);

  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color grey = Color(0xFF9E9E9E);

  // Named Colors
  static const Color royalBlue = Color(0xFF4169E1);
  static const Color coral = Color(0xFFFF7F50);
  static const Color indigo = Color(0xFF4B0082);
  static const Color crimson = Color(0xFFDC143C);
  static const Color mint = Color(0xFF98FF98);
  static const Color turquoise = Color(0xFF40E0D0);
  static const Color gold = Color(0xFFFFD700);
  static const Color green = Color(0xFF008000);
  static const Color orange = Color(0xFFFFA500);
  static const Color pink = Color(0xFFFFC0CB);
  static const Color purple = Color(0xFF800080);
  static const Color red = Color(0xFFFF0000);
  static const Color teal = Color(0xFF008080);
  static const Color violet = Color(0xFFEE82EE);
  static const Color yellow = Color(0xFFFFFF00);
  static const Color brown = Color(0xFFA52A2A);
  static const Color blue = Color(0xFF0000FF);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color lime = Color(0xFF00FF00);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color olive = Color(0xFF808000);

  // Chart palette used by the analytics screen. Five brand-coherent
  // colours so pie / bar charts stay readable.
  static const List<Color> chartPalette = [
    royalBlue, // #4169E1
    orange, // #FFA500
    green, // #008000
    purple, // #800080
    crimson, // #DC143C
  ];

  /// Opaque + faded version of a chart colour for stacked bars.
  static Color faded(Color c) => c.withValues(alpha: 0.6);
}