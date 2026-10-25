import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../core/theme/app_colors.dart';

/// A decorative block with the game's look (Section 19.1): glow (same colour
/// at 55%, sigma 12), solid fill, and a 4 dp white 25% highlight strip.
/// Sizes are passed in final (already scaled) dp.
class GlowBlock extends StatelessWidget {
  const GlowBlock({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.radius = GameConst.blockRadius,
    this.glow = true,
    this.outline,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;
  final bool glow;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: outline == null
            ? null
            : Border.all(color: outline!, width: GameConst.pharaohOutlineWidth),
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.a(color, GameConst.glowOpacity),
                  blurRadius: GameConst.glowSigma * 2,
                ),
              ]
            : null,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: GameConst.highlightHeight,
          decoration: BoxDecoration(
            color: AppColors.a(AppColors.white, GameConst.highlightOpacity),
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
        ),
      ),
    );
  }
}
