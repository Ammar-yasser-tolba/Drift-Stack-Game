import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Section 15.3 responsive helper. Reference screen = 360 × 800 dp.
/// UI screens are limited to 420 dp wide and centred on tablets; the game
/// itself uses the full width (use [width] there).
class Responsive {
  const Responsive._({
    required this.width,
    required this.height,
    required this.contentWidth,
    required this.scale,
    required this.safeTop,
    required this.safeBottom,
  });

  factory Responsive.of(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double h = mq.size.height;
    final double cw = math.min(w, maxContentWidth);
    final double s = math.min(cw / refWidth, h / refHeight).clamp(0.7, 1.25).toDouble();
    return Responsive._(
      width: w,
      height: h,
      contentWidth: cw,
      scale: s,
      safeTop: mq.padding.top,
      safeBottom: mq.padding.bottom,
    );
  }

  static const double refWidth = 360;
  static const double refHeight = 800;
  static const double maxContentWidth = 420;
  static const double shortScreenHeight = 700;
  static const double sideMargin = 24;

  final double width;
  final double height;
  final double contentWidth;
  final double scale;
  final double safeTop;
  final double safeBottom;

  /// Screens shorter than 700 dp use smaller titles and hide decorations.
  bool get isShort => height < shortScreenHeight;
  bool get isTablet => width > maxContentWidth;

  /// Scales a reference dp value.
  double u(double dp) => dp * scale;

  /// Fraction of the full screen width (game world sizes).
  double fw(double fraction) => width * fraction;

  /// Fraction of the full screen height.
  double fh(double fraction) => height * fraction;

  /// Y position measured from the top of the safe area on the 360 × 800
  /// reference screen, stretched to the real usable height.
  double yPos(double refY) {
    final double usable = height - safeTop - safeBottom;
    return safeTop + refY * usable / refHeight;
  }

  /// Width available inside the side margins.
  double get innerWidth => contentWidth - u(sideMargin) * 2;
}

/// Centres its child and limits it to 420 dp (tablet rule, Section 15.3).
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: child,
      ),
    );
  }
}
