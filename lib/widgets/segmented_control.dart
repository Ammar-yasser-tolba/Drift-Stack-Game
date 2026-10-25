import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// Section 15.4 segmented control: 280 × 40, radius 20, surface fill, equal
/// segments. Selected = cyan fill + dark text; unselected = white 70%;
/// disabled segment = 40% opacity (tap calls [onDisabledTap]).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.onDisabledTap,
    this.width = 280,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final ValueChanged<T>? onDisabledTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double h = r.u(40);
    return Container(
      width: math.min(r.u(width), r.contentWidth - 48),
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: Row(
        children: <Widget>[
          for (final SegmentOption<T> o in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (o.enabled) {
                    onChanged(o.value);
                  } else {
                    onDisabledTap?.call(o.value);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.value == selected ? AppColors.cyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(h / 2),
                  ),
                  child: Opacity(
                    opacity: o.enabled ? 1.0 : 0.4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        o.label,
                        maxLines: 1,
                        style: AppTextStyles.buttonSmall.scaled(r.scale).copyWith(
                              fontSize: 14 * r.scale,
                              color: o.value == selected ? AppColors.bgTop : AppColors.white70,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
