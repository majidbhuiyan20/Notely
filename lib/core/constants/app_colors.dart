import 'package:flutter/material.dart';

/// Premium design tokens for Notely.
///
/// The palette is centred on an indigo→violet gradient with warm accent
/// highlights. All colours here are *theme* tokens — feature code should
/// reference these (or `Theme.of(context).colorScheme`) instead of
/// hard-coding hex values.
class AppColors {
  // ───────────────────────── Brand ─────────────────────────
  static const Color brandPrimary = Color(0xFF5B5BF0); // indigo-500
  static const Color brandPrimaryDark = Color(0xFF3F3FCD);
  static const Color brandSecondary = Color(0xFF8B5CF6); // violet-500
  static const Color brandAccent = Color(0xFFFFB86B); // warm peach
  static const Color brandMint = Color(0xFF34D399);

  // ───────────────────────── Surfaces ──────────────────────
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F3FA);
  static const Color glass = Color(0xCCFFFFFF);
  static const Color divider = Color(0xFFE7E9F2);

  // ───────────────────────── Text ──────────────────────────
  static const Color textPrimary = Color(0xFF11142B);
  static const Color textSecondary = Color(0xFF5C6184);
  static const Color textTertiary = Color(0xFF9CA0BC);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ───────────────────────── Status ────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─────────────────────── Gradient stops ──────────────────
  static const List<Color> brandGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  static const List<Color> heroGradient = [
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
  ];
  static const List<Color> sunsetGradient = [
    Color(0xFFFFB86B),
    Color(0xFFFF6B9C),
  ];

  // ─────────────────────── Legacy aliases ──────────────────
  // Kept so existing feature code (royal blue, palette charts, etc.)
  // continues to compile without a sweeping rename.
  static const Color primary = brandPrimary;
  static const Color primaryVariant = brandPrimaryDark;
  static const Color secondary = brandSecondary;
  static const Color secondaryVariant = brandPrimaryDark;

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
  static const Color grey = Color(0xFF9E9E9E);

  static const List<Color> chartPalette = [
    brandPrimary,
    orange,
    green,
    brandSecondary,
    crimson,
  ];

  static Color faded(Color c) => c.withValues(alpha: 0.6);
}

/// Geometric & motion tokens. Components should reach for these instead
/// of writing magic numbers — keeps the look consistent.
class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppElevation {
  static const double flat = 0;
  static const double low = 1;
  static const double card = 6;
  static const double raised = 12;
  static const double overlay = 24;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1411142B),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0811142B),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> raisedShadow = [
    BoxShadow(
      color: Color(0x1F11142B),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> brandGlow = [
    BoxShadow(
      color: Color(0x555B5BF0),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}