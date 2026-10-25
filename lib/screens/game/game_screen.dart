import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/game_constants.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/utils/utc_date.dart';
import '../../models/game_mode.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/pressable.dart';
import 'game_engine.dart';
import 'game_painter.dart';

/// S3 Game (Sections 5 and 19) with the S4 pause overlay (Section 20).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _Overlay { none, panel, countdown }

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  GameEngine? _engine;
  Duration? _lastTick;
  double _slowTime = 0;
  bool _navigated = false;

  _Overlay _overlay = _Overlay.none;
  Timer? _countdownTimer;
  int _countdown = GameConst.resumeCountdownSeconds;
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engine ??= GameEngine(
      mode: widget.mode,
      skin: StorageService.instance.equippedSkin,
      size: MediaQuery.sizeOf(context),
      ghost: StorageService.instance.activeGhostFor(widget.mode),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _ticker.dispose();
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  /// Section 5.5: backgrounding the app pauses the run; it never resumes by
  /// itself, and a running 3-2-1 countdown is cancelled.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final bool was = _wasBackgrounded;
    _wasBackgrounded = false;
    final GameEngine? e = _engine;
    if (!was || e == null || e.phase != GamePhase.playing) return;
    _countdownTimer?.cancel();
    if (mounted && _overlay != _Overlay.panel) {
      setState(() {
        _overlay = _Overlay.panel;
        _countdown = GameConst.resumeCountdownSeconds;
      });
    }
  }

  void _onTick(Duration elapsed) {
    final GameEngine? e = _engine;
    if (e == null) return;
    final Duration? last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    // Everything freezes while S4 / the countdown is up.
    if (_overlay != _Overlay.none) return;

    final double raw = (elapsed - last).inMicroseconds / 1e6;
    // Section 14: frame time over 20 ms for 2 s halves particles and glow.
    if (!e.lowEnd && raw >= GameConst.slowFrameMs / 1000) {
      _slowTime += raw;
      if (_slowTime >= GameConst.slowFrameWindowSeconds) e.lowEnd = true;
    } else if (!e.lowEnd) {
      _slowTime = 0;
    }

    e.update(raw.clamp(0.0, 0.05));

    if (!_navigated && e.phase == GamePhase.over && e.overT >= 1) {
      _navigated = true;
      _ticker.stop();
      _openGameOver(e);
    }
    if (mounted) setState(() {});
  }

  void _openGameOver(GameEngine e) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRouter.gameOver,
      arguments: RouteArgs(
        transition: RouteTransition.fade300,
        data: e.result(),
      ),
    );
  }

  void _tap() {
    final GameEngine? e = _engine;
    if (e == null || _overlay != _Overlay.none) return;
    switch (e.phase) {
      case GamePhase.ready:
        e.start();
      case GamePhase.playing:
        e.tapDrop();
      case GamePhase.over:
        break;
    }
  }

  void _pause() {
    final GameEngine? e = _engine;
    if (e == null || e.phase != GamePhase.playing) return;
    if (_overlay != _Overlay.none) return;
    setState(() => _overlay = _Overlay.panel);
  }

  void _resume() {
    if (_overlay != _Overlay.panel) return;
    setState(() {
      _overlay = _Overlay.countdown;
      _countdown = GameConst.resumeCountdownSeconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: GameConst.countdownNumberMs),
      (Timer t) {
        if (!mounted) return;
        if (t.tick >= GameConst.resumeCountdownSeconds) {
          t.cancel();
          setState(() => _overlay = _Overlay.none);
        } else {
          setState(() => _countdown = GameConst.resumeCountdownSeconds - t.tick);
        }
      },
    );
  }

  /// RESTART (home = false) or HOME (home = true) from S4. Scores of 5 or
  /// more ask D2 first; the unfinished run is always discarded.
  Future<void> _quitTo({required bool home}) async {
    final GameEngine? e = _engine;
    if (e == null) return;
    if (e.score >= GameConst.minScoreForQuitConfirm) {
      final bool? quit = await showAppDialog<bool>(
        context: context,
        title: 'Quit this run?',
        body: "Your score of ${e.score} won't be saved.",
        buttons: const <DialogButton<bool>>[
          DialogButton<bool>(label: 'KEEP PLAYING', value: false),
          DialogButton<bool>(
            label: 'QUIT',
            value: true,
            style: DialogButtonStyle.muted,
          ),
        ],
        backValue: false,
      );
      if (quit != true || !mounted) return;
    }
    _countdownTimer?.cancel();
    if (home) {
      Navigator.of(context).popUntil(
        (Route<dynamic> r) => r.isFirst || r.settings.name == AppRouter.home,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRouter.game,
        arguments: RouteArgs(
          transition: RouteTransition.fade300,
          data: widget.mode,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GameEngine? e = _engine;
    if (e == null) return const SizedBox.shrink();
    final double h = e.size.height;

    return PopScope(
      canPop: e.phase == GamePhase.ready && _overlay == _Overlay.none,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (e.phase != GamePhase.playing) return;
        if (_overlay == _Overlay.none) {
          _pause();
        } else if (_overlay == _Overlay.panel) {
          _resume();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgTop,
        body: AppBackground(
          skin: e.skin,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (TapDownDetails _) => _tap(),
                child: CustomPaint(
                  painter: GamePainter(engine: e, skin: e.skin),
                ),
              ),
              if (e.event != null)
                IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.a(
                      e.event!.color,
                      GameConst.eventTintOpacity * e.event!.fade,
                    ),
                  ),
                ),
              _hud(e, h),
              if (e.phase == GamePhase.ready && _overlay == _Overlay.none)
                Positioned(
                  left: 16,
                  top: 16,
                  child: IconCircleButton(
                    icon: Icons.close,
                    semanticLabel: 'Close',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              if (e.phase == GamePhase.playing && _overlay == _Overlay.none)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _pauseButton(),
                ),
              if (_overlay != _Overlay.none) _overlayLayer(e),
            ],
          ),
        ),
      ),
    );
  }

  /// Visible 48 × 48, tap area 56 × 56 (Section 19.2).
  Widget _pauseButton() {
    return Semantics(
      button: true,
      label: 'Pause',
      child: Pressable(
        onTap: _pause,
        builder: (BuildContext context, bool pressed) => Container(
          width: GameConst.pauseTapArea,
          height: GameConst.pauseTapArea,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? AppColors.pressedFill : AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Icon(Icons.pause, size: 24, color: AppColors.white),
          ),
        ),
      ),
    );
  }

  Widget _overlayLayer(GameEngine e) {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        reverseDuration: const Duration(milliseconds: 120),
        transitionBuilder: (Widget child, Animation<double> a) {
          final Animation<double> curved =
              CurvedAnimation(parent: a, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        child: _overlay == _Overlay.panel
            ? KeyedSubtree(key: const ValueKey<String>('panel'), child: _panel(e))
            : KeyedSubtree(
                key: const ValueKey<String>('countdown'),
                child: _countdownView(),
              ),
      ),
    );
  }

  Widget _panel(GameEngine e) {
    final Responsive r = Responsive.of(context);
    final TextStyle titleStyle = AppTextStyles.h2.scaled(r.scale).copyWith(
      fontSize: 32 * r.scale,
      letterSpacing: 4 * r.scale,
      height: 1.0,
      color: AppColors.white,
    );
    final TextStyle scoreStyle = AppTextStyles.body.scaled(r.scale).copyWith(
      fontSize: 18 * r.scale,
      fontWeight: FontWeight.w600,
      letterSpacing: 2 * r.scale,
      color: AppColors.textSecondary,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ModalBarrier(color: AppColors.scrim, dismissible: false),
        Center(
          child: Container(
            width: math.min(r.u(296), r.contentWidth - 48),
            padding: EdgeInsets.all(24 * r.scale),
            decoration: BoxDecoration(
              color: const Color(0xF21A1640),
              borderRadius: BorderRadius.circular(28 * r.scale),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('PAUSED', style: titleStyle),
                SizedBox(height: 8 * r.scale),
                Text('SCORE ${e.score}', style: scoreStyle),
                SizedBox(height: 28 * r.scale),
                PrimaryButton(
                  label: 'RESUME',
                  onTap: _resume,
                  width: 248,
                  height: 60,
                ),
                SizedBox(height: 14 * r.scale),
                SecondaryButton(
                  label: 'RESTART',
                  onTap: () => _quitTo(home: false),
                  width: 248,
                  height: 52,
                ),
                SizedBox(height: 12 * r.scale),
                MutedButton(
                  label: 'HOME',
                  onTap: () => _quitTo(home: true),
                  width: 248,
                  height: 52,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _countdownView() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ModalBarrier(color: AppColors.scrim, dismissible: false),
        Center(
          child: _CountdownNumber(
            key: ValueKey<int>(_countdown),
            number: _countdown,
          ),
        ),
      ],
    );
  }


  Widget _hud(GameEngine e, double h) {
    final TextStyle scoreStyle = AppTextStyles.scoreHud.copyWith(
      shadows: <Shadow>[
        Shadow(color: AppColors.a(Colors.black, 0.4), blurRadius: 8),
      ],
    );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: GameConst.scoreTop,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 1 - e.overProgress,
                child: Transform.scale(
                  scale: 1 + 0.15 * e.scorePulse,
                  child: Text('${e.score}', style: scoreStyle),
                ),
              ),
            ),
          ),
          if (e.mode == GameMode.daily)
            _pill(
              top: GameConst.dailyPillY,
              text: 'DAILY · ${UtcDate.shortLabel()}',
              color: AppColors.white,
            ),
          if (e.ghost != null)
            _pill(
              top: e.mode == GameMode.daily
                  ? GameConst.ghostPillYDaily
                  : GameConst.ghostPillYClassic,
              text: 'GHOST · ${e.ghost!.score}',
              color: AppColors.textSecondary,
            ),
          if (e.phase == GamePhase.ready)
            Positioned(
              top: h * GameConst.tapToStartYFrac - 18,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: e.tapToStartOpacity,
                child: Center(
                  child: Text(
                    'TAP TO START',
                    style: TextStyle(
                      fontFamily: AppTextStyles.family,
                      fontFamilyFallback: AppTextStyles.fallback,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      height: 1.0,
                      color: AppColors.white,
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.a(AppColors.cyan, 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (e.bannerText != null)
            Positioned(
              top: h * GameConst.bannerYFrac,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: e.bannerAlpha,
                child: Center(
                  child: Text(
                    e.bannerText!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.family,
                      fontFamilyFallback: AppTextStyles.fallback,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      height: 1.0,
                      color: e.bannerColor,
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.a(e.bannerColor, 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill({
    required double top,
    required String text,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            widthFactor: 1.0,
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section 20: each countdown digit scales 1.4 → 1 and fades 100% → 0% over
/// one second.
class _CountdownNumber extends StatefulWidget {
  const _CountdownNumber({super.key, required this.number});

  final int number;

  @override
  State<_CountdownNumber> createState() => _CountdownNumberState();
}

class _CountdownNumberState extends State<_CountdownNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: GameConst.countdownNumberMs),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 1.4, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  late final Animation<double> _fade =
      Tween<double>(begin: 1.0, end: 0.0).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return IgnorePointer(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            '${widget.number}',
            style: AppTextStyles.scoreBig.scaled(r.scale).copyWith(
              color: AppColors.white,
              shadows: <Shadow>[
                Shadow(color: AppColors.a(AppColors.cyan, 0.7), blurRadius: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
