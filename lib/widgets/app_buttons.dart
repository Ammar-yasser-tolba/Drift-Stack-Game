import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';
import 'pressable.dart';

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.text,
    required this.style,
    required this.scale,
    this.icon,
    this.leading,
  });

  final String text;
  final TextStyle style;
  final double scale;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, SizedBox(width: 8 * scale)],
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18 * scale, color: style.color),
          SizedBox(width: 8 * scale),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, style: style),
          ),
        ),
      ],
    );
  }
}

/// Section 15.4 primary button: 280 × 64, radius = half height, cyan fill,
/// cyan glow (40%, blur 20, offset 0,4). Disabled = 40% opacity, no glow.
/// [fill], [textColor] and [glow] allow the amber BUY and danger variants.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.width = 280,
    this.height = 64,
    this.fill = AppColors.cyan,
    this.textColor = AppColors.bgTop,
    this.glow = AppColors.cyan,
    this.leading,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final double width;
  final double height;
  final Color fill;
  final Color textColor;
  final Color glow;
  final Widget? leading;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double w = math.min(r.u(width), r.contentWidth - 48);
    final double h = r.u(height);
    final bool on = enabled && onTap != null;
    TextStyle style = AppTextStyles.button.scaled(r.scale).copyWith(color: textColor);
    if (fontSize != null) style = style.copyWith(fontSize: fontSize! * r.scale);
    return Opacity(
      opacity: on ? 1.0 : 0.4,
      child: Pressable(
        enabled: on,
        onTap: onTap,
        builder: (BuildContext context, bool pressed) => Container(
          width: w,
          height: h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 12 * r.scale),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(h / 2),
            boxShadow: on
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.a(glow, 0.4),
                      blurRadius: 20 * r.scale,
                      offset: Offset(0, 4 * r.scale),
                    ),
                  ]
                : null,
          ),
          child: _ButtonLabel(text: label, style: style, scale: r.scale, leading: leading),
        ),
      ),
    );
  }
}

/// Danger variant: red fill, white text, red glow (RESET).
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 280,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      fill: AppColors.danger,
      textColor: AppColors.white,
      glow: AppColors.danger,
    );
  }
}

/// Section 15.4 secondary button: 280 × 56, transparent, 2 dp cyan border,
/// cyan text. Pressed = cyan 15% fill. [loading] shows a 20 dp spinner and
/// ignores taps (SHARE while working).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.width = 280,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double w = math.min(r.u(width), r.contentWidth - 48);
    final double h = r.u(height);
    final bool on = enabled && !loading && onTap != null;
    final TextStyle style =
        AppTextStyles.buttonSmall.scaled(r.scale).copyWith(color: AppColors.cyan, fontSize: 18 * r.scale);
    return Opacity(
      opacity: (enabled || loading) ? 1.0 : 0.4,
      child: Pressable(
        enabled: on,
        onTap: onTap,
        builder: (BuildContext context, bool pressed) => Container(
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? AppColors.a(AppColors.cyan, 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: AppColors.cyan, width: 2),
          ),
          child: loading
              ? SizedBox(
                  width: 20 * r.scale,
                  height: 20 * r.scale,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                )
              : _ButtonLabel(text: label, style: style, scale: r.scale),
        ),
      ),
    );
  }
}

/// Section 15.4 muted button (Home, Copy Ghost, Quit): height 48–52,
/// 1.5 dp border white 24%, white text. [width] null = fill the parent.
class MutedButton extends StatelessWidget {
  const MutedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
    this.height = 52,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double? width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double h = r.u(height);
    final bool on = enabled && onTap != null;
    final TextStyle style = AppTextStyles.buttonSmall.scaled(r.scale);
    return Opacity(
      opacity: on ? 1.0 : 0.4,
      child: Pressable(
        enabled: on,
        onTap: onTap,
        builder: (BuildContext context, bool pressed) => Container(
          width: width == null ? double.infinity : r.u(width!),
          height: h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 10 * r.scale),
          decoration: BoxDecoration(
            color: pressed ? AppColors.pressedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: AppColors.mutedBorder, width: 1.5),
          ),
          child: _ButtonLabel(text: label, style: style, scale: r.scale, icon: icon),
        ),
      ),
    );
  }
}

/// Text-only button (SKIP, REMOVE). Always at least 48 dp tall.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.cyan,
    this.fontSize = 16,
    this.minWidth = 64,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double fontSize;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return Pressable(
      onTap: onTap,
      builder: (BuildContext context, bool pressed) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: r.u(minWidth), minHeight: 48),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.buttonSmall
                .scaled(r.scale)
                .copyWith(color: color, fontSize: fontSize * r.scale),
          ),
        ),
      ),
    );
  }
}

/// Section 15.4 icon button: 48 × 48 circle, surface fill, 1.5 dp border,
/// 24 dp white icon. Pressed = white 16% fill.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.white,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double size = math.max(48.0, r.u(48));
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        builder: (BuildContext context, bool pressed) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pressed ? AppColors.pressedFill : AppColors.surface,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Icon(icon, size: 24 * r.scale, color: iconColor),
        ),
      ),
    );
  }
}
