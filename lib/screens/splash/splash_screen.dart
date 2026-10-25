import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_nav.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/skins.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glow_block.dart';

/// S0 Splash (Section 2 / 16). Loads saved data, sounds and fonts behind the
/// logo animation, stays at least 1.2 s, then fades to S1 (or S2 on first
/// launch). Taps do nothing and Android Back is ignored.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const int _totalMs = 1000;
  static const List<int> _startMs = <int>[0, 150, 300]; // bottom, middle, top
  static const List<double> _widths = <double>[140, 110, 80];
  static const List<Color> _colors = <Color>[AppColors.cyan, AppColors.pink, AppColors.amber];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );
  late final List<Animation<double>> _drops = <Animation<double>>[
    for (final int s in _startMs)
      CurvedAnimation(
        parent: _c,
        curve: Interval(s / _totalMs, (s + 400) / _totalMs, curve: Curves.easeOutBack),
      ),
  ];
  late final List<Animation<double>> _fades = <Animation<double>>[
    for (final int s in _startMs)
      CurvedAnimation(parent: _c, curve: Interval(s / _totalMs, (s + 160) / _totalMs)),
  ];
  late final Animation<double> _textFade =
      CurvedAnimation(parent: _c, curve: const Interval(0.6, 1.0));

  Timer? _ringTimer;
  bool _showRing = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final TickerFuture anim = _c.forward();
    // The loading ring only appears if loading takes more than 1.2 s.
    _ringTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showRing = true);
    });
    final Future<void> minHold = Future<void>.delayed(const Duration(milliseconds: 1200));

    _warmUpFonts();
    // Both loaders never throw and have their own 5 s limit.
    await Future.wait<void>(<Future<void>>[
      StorageService.instance.load(),
      AudioService.instance.load(),
    ]);
    await minHold;
    await anim.orCancel.catchError((Object _) {});

    _ringTimer?.cancel();
    if (!mounted) return;
    _goNext();
  }

  /// Touches each font once so it is ready before the first real screen.
  void _warmUpFonts() {
    for (final TextStyle s in <TextStyle>[
      AppTextStyles.title,
      AppTextStyles.body,
      AppTextStyles.mono,
    ]) {
      TextPainter(
        text: TextSpan(text: 'DRIFT STACK 0123456789', style: s),
        textDirection: TextDirection.ltr,
      ).layout();
    }
  }

  void _goNext() {
    final StorageService s = StorageService.instance;
    final bool firstRun = !s.tutorialSeen;
    final bool loadFailed = s.loadFailed;

    AppNav.navigatorKey.currentState?.pushReplacementNamed(
      firstRun ? AppRouter.howToPlay : AppRouter.home,
      arguments: RouteArgs(
        transition: RouteTransition.fade400,
        data: firstRun, // How To Play: true = first-run mode
      ),
    );

    if (loadFailed) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        AppSnackbar.show("Couldn't load saved data. Progress won't be saved.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final double centerY = r.yPos(340);
    final double stackTop = centerY - r.u(40.5); // 3 × 25 + 2 × 3 = 81 dp tall
    final TextStyle nameStyle = AppTextStyles.title.scaled(r.scale).copyWith(
      letterSpacing: 6 * r.scale,
      shadows: const <Shadow>[Shadow(color: AppColors.cyan, blurRadius: 12)],
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          skin: Skins.neon,
          child: Stack(
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: stackTop + (2 - i) * r.u(28),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (BuildContext context, Widget? child) {
                      final double drop = 1.0 - _drops[i].value;
                      return Opacity(
                        opacity: _fades[i].value.clamp(0.0, 1.0).toDouble(),
                        child: Transform.translate(
                          offset: Offset(0, -drop * r.u(320)),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: GlowBlock(
                        width: r.u(_widths[i]),
                        height: r.u(25),
                        color: _colors[i],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: r.yPos(420) - r.u(20),
                child: FadeTransition(
                  opacity: _textFade,
                  child: Center(child: Text('DRIFT STACK', style: nameStyle)),
                ),
              ),
              if (_showRing)
                Positioned(
                  left: 0,
                  right: 0,
                  top: r.yPos(740) - r.u(12),
                  child: Center(
                    child: SizedBox(
                      width: r.u(24),
                      height: r.u(24),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
