import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/responsive.dart';

/// Section 15.4 toggle: track 52 × 30, radius 15, off = white 24%, on = cyan,
/// 24 dp white knob 3 dp from the edge, slides in 150 ms.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: r.u(52),
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: r.u(52),
            height: r.u(30),
            decoration: BoxDecoration(
              color: value ? AppColors.cyan : AppColors.toggleOff,
              borderRadius: BorderRadius.circular(r.u(15)),
            ),
            child: Padding(
              padding: EdgeInsets.all(r.u(3)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: r.u(24),
                  height: r.u(24),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
