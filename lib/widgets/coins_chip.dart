import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';
import 'pressable.dart';

/// 20 dp amber circle with a darker amber "C".
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.amber),
      child: Text(
        'C',
        style: TextStyle(
          fontFamily: AppTextStyles.family,
          fontFamilyFallback: AppTextStyles.fallback,
          fontSize: size * 0.62,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: AppColors.amberDark,
        ),
      ),
    );
  }
}

/// Section 15.4 coins chip: height 40, radius 20, padding 14, surface fill,
/// 1.5 dp border. When [coins] changes the number counts up/down in 0.5 s.
class CoinsChip extends StatefulWidget {
  const CoinsChip({super.key, required this.coins, this.onTap});

  final int coins;
  final VoidCallback? onTap;

  @override
  State<CoinsChip> createState() => _CoinsChipState();
}

class _CoinsChipState extends State<CoinsChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1.0,
  );
  late int _from = widget.coins;
  late int _to = widget.coins;

  int get _shown {
    final double t = Curves.easeOut.transform(_c.value);
    return (_from + (_to - _from) * t).round();
  }

  @override
  void didUpdateWidget(CoinsChip old) {
    super.didUpdateWidget(old);
    if (old.coins != widget.coins) {
      _from = _shown;
      _to = widget.coins;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double h = r.u(40);

    Widget chip(bool pressed) => Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: 14 * r.scale),
          decoration: BoxDecoration(
            color: pressed ? AppColors.pressedFill : AppColors.surface,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CoinIcon(size: 20 * r.scale),
              SizedBox(width: 8 * r.scale),
              AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) => Text(
                  '$_shown',
                  style: AppTextStyles.button
                      .scaled(r.scale)
                      .copyWith(fontSize: 18 * r.scale, letterSpacing: 0),
                ),
              ),
            ],
          ),
        );

    if (widget.onTap == null) return chip(false);
    return Pressable(onTap: widget.onTap, builder: (BuildContext c, bool p) => chip(p));
  }
}
