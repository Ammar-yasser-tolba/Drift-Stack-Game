import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pressable.dart';

/// Section 15.4 card: radius 20, surface fill, 1.5 dp border.
/// Selected: 2.5 dp cyan border + cyan glow (30%, blur 16).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.fill = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.5,
    this.selected = false,
    this.onTap,
    this.opacity = 1.0,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final bool selected;
  final VoidCallback? onTap;
  final double opacity;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget build(bool pressed) {
      final BorderRadius br = BorderRadius.circular(radius);
      return Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: pressed ? Color.alphaBlend(AppColors.pressedFill, fill) : fill,
            borderRadius: br,
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(color: AppColors.a(AppColors.cyan, 0.3), blurRadius: 16),
                  ]
                : null,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(
              color: selected ? AppColors.cyan : borderColor,
              width: selected ? 2.5 : borderWidth,
            ),
          ),
          child: ClipRRect(borderRadius: br, child: child),
        ),
      );
    }

    if (onTap == null) return build(false);
    return Pressable(onTap: onTap, builder: (BuildContext c, bool p) => build(p));
  }
}
