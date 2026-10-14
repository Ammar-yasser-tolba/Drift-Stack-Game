import 'package:flutter/material.dart';

/// Section 15.1 colour tokens.
class AppColors {
  AppColors._();

  static const Color bgTop = Color(0xFF0B0F2B);
  static const Color bgBottom = Color(0xFF1B0B3A);
  static const Color cyan = Color(0xFF18FFFF);
  static const Color pink = Color(0xFFFF4081);
  static const Color amber = Color(0xFFFFC107);
  static const Color amberDark = Color(0xFFB07A00); // "C" on the coin icon
  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8BCE0);
  static const Color textMuted = Color(0x66FFFFFF); // white 40%
  static const Color surface = Color(0x14FFFFFF); // white 8%
  static const Color border = Color(0x2EFFFFFF); // white 18%
  static const Color dialogFill = Color(0xFF1A1640);
  static const Color scrim = Color(0x99000000); // black 60%
  static const Color danger = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);
  static const Color snackbarFill = Color(0xFF2A2560);

  // Frequently used derived values.
  static const Color mutedBorder = Color(0x3DFFFFFF); // white 24%
  static const Color divider = Color(0x1FFFFFFF); // white 12%
  static const Color pressedFill = Color(0x29FFFFFF); // white 16%
  static const Color toggleOff = Color(0x3DFFFFFF); // white 24%
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color ghostOutline = Color(0x40FFFFFF); // white 25%
  static const Color floorFill = Color(0x4D000000); // black 30%
  static const Color floorLine = Color(0x4D18FFFF); // cyan 30%

  /// [c] with opacity [o] (0..1).
  static Color a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());
}
