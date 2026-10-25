import 'package:flutter/material.dart';

/// Gentle looping scale (Home PLAY button 1↔1.03 in 1.6 s, NEW BEST badge
/// 1↔1.08 in 0.8 s). [period] is one full cycle.
class PulseScale extends StatefulWidget {
  const PulseScale({
    super.key,
    required this.child,
    this.end = 1.03,
    this.period = const Duration(milliseconds: 1600),
  });

  final Widget child;
  final double end;
  final Duration period;

  @override
  State<PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<PulseScale> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(microseconds: widget.period.inMicroseconds ~/ 2),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: widget.end)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // The boundary sits under the scale so the child is rasterized once and the
  // animation only updates the transform layer.
  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: RepaintBoundary(child: widget.child),
      );
}
