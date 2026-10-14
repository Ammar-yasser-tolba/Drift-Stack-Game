import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Section 15.2 typography. Rajdhani ships in 600/700 only, so the 800/900
/// weights in the spec resolve to the Bold (700) file.
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Rajdhani';
  static const String monoFamily = 'RobotoMono';
  static const List<String> fallback = <String>['Roboto'];

  static const TextStyle scoreHud = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 0,
    height: 1.0, color: AppColors.white,
  );
  static const TextStyle scoreBig = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 120, fontWeight: FontWeight.w900, letterSpacing: 0,
    height: 1.0, color: AppColors.white,
  );
  static const TextStyle display = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: 8,
    height: 1.0, color: AppColors.white,
  );
  static const TextStyle title = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: 5,
    height: 1.1, color: AppColors.white,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 4,
    height: 1.1, color: AppColors.white,
  );
  static const TextStyle button = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2,
    height: 1.1, color: AppColors.white,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5,
    height: 1.1, color: AppColors.white,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0,
    height: 1.3, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: family, fontFamilyFallback: fallback,
    fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5,
    height: 1.1, color: AppColors.textSecondary,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: monoFamily, fontFamilyFallback: fallback,
    fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0,
    height: 1.4, color: AppColors.white,
  );
}

extension TextStyleScaling on TextStyle {
  /// Scales font size (and fixed letter spacing) by the responsive factor.
  TextStyle scaled(double factor) => copyWith(
        fontSize: (fontSize ?? 14) * factor,
        letterSpacing: letterSpacing == null ? null : letterSpacing! * factor,
      );
}
