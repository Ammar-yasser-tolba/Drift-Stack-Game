import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/haptics_service.dart';

/// Rule 1.5-2: every button scales to 0.96 in 80 ms and returns in 120 ms.
/// Also plays the UI tap sound and the "selection click" haptic (Section 27)
/// on tap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.enabled = true,
    this.haptic = true,
    this.pressedScale = 0.96,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;
  final bool enabled;
  final bool haptic;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool down = _pressed && _active;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _set(true) : null,
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: _active
          ? () {
              if (widget.haptic) HapticsService.instance.selection();
              AudioService.instance.play(Sfx.tap, volume: 0.6);
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: down ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: down ? 80 : 120),
        curve: Curves.easeOut,
        child: widget.builder(context, down),
      ),
    );
  }
}
