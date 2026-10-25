import 'package:flutter/material.dart';

import '../core/theme/skins.dart';
import '../services/storage_service.dart';

/// Section 15.1: vertical gradient from the top to the bottom colour of the
/// equipped skin. Pass [skin] to force one (Splash = Neon, Skins preview).
/// The gradient sits in its own RepaintBoundary so it is never repainted by
/// the content above it.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.skin});

  final Widget child;
  final SkinDef? skin;

  @override
  Widget build(BuildContext context) {
    if (skin != null) return _Gradient(skin: skin!, child: child);
    return ListenableBuilder(
      listenable: StorageService.instance,
      builder: (BuildContext context, Widget? _) =>
          _Gradient(skin: StorageService.instance.equippedSkin, child: child),
    );
  }
}

class _Gradient extends StatelessWidget {
  const _Gradient({required this.skin, required this.child});

  final SkinDef skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: DecoratedBox(decoration: BoxDecoration(gradient: skin.gradient)),
        ),
        child,
      ],
    );
  }
}
