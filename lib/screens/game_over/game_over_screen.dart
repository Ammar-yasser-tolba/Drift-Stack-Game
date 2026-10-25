import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/skins.dart';
import '../../core/utils/utc_date.dart';
import '../../models/game_mode.dart';
import '../../models/ghost.dart';
import '../../models/run_result.dart';
import '../../services/audio_service.dart';
import '../../services/clipboard_service.dart';
import '../../services/haptics_service.dart';
import '../../services/share_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/pulse_scale.dart';
import 'share_card.dart';

/// S5 Game Over (Sections 7 and 21). The run is committed in [initState], so
/// coins, best score, ghost and streak are saved the moment the screen opens.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key, required this.result});

  final RunResult result;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late final SkinDef _skin;
  late final RunCommitResult _commit;
  late final AnimationController _entrance;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _skin = StorageService.instance.equippedSkin;
    _commit = StorageService.instance.commitRun(
      mode: widget.result.mode,
      score: widget.result.score,
      ghost: widget.result.ghost,
    );
    // Section 27: a new best is celebrated the moment S5 opens — badge,
    // confetti, perfect.wav and a heavy haptic all start together.
    if (_commit.isNewBest) {
      AudioService.instance.play(Sfx.perfect);
      HapticsService.instance.heavy();
    }
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  // --- actions ---------------------------------------------------------

  void _playAgain() {
    Navigator.of(context).pushReplacementNamed(
      AppRouter.game,
      arguments: RouteArgs(
        transition: RouteTransition.fade300,
        data: widget.result.mode,
      ),
    );
  }

  void _home() {
    if (_sharing) return;
    Navigator.of(context).popUntil(
      (Route<dynamic> r) => r.isFirst || r.settings.name == AppRouter.home,
    );
  }

  Future<void> _copyGhost() async {
    try {
      await ClipboardService.copy(widget.result.ghost.encode());
    } catch (_) {
      return;
    }
    if (mounted) AppSnackbar.show('Ghost code copied.');
  }

  String get _shareText {
    final int s = widget.result.score;
    if (widget.result.mode == GameMode.daily) {
      return 'I reached $s in Drift Stack on ${UtcDate.shortLabel()}! Beat me.';
    }
    return 'I reached $s in Drift Stack! Beat me.';
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    bool failed = false;
    try {
      final File file = await (() async {
        final Uint8List png =
            await ShareCard.render(result: widget.result, skin: _skin);
        return ShareService.writePng(png);
      })()
          .timeout(const Duration(seconds: 5));
      await ShareService.shareImage(file, _shareText);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!failed) return;
    await showAppDialog<bool>(
      context: context,
      title: 'Share failed',
      body: "Couldn't create the image. Please try again.",
      buttons: const <DialogButton<bool>>[
        DialogButton<bool>(label: 'OK', value: true),
      ],
      backValue: true,
    );
  }

  // --- layout ----------------------------------------------------------

  /// Section 21 entrance: 60 ms between elements, each fades in and slides
  /// up 16 dp. The controller runs for 800 ms.
  Widget _enter(Responsive r, int slot, Widget child) {
    final double start = math.min(1.0, slot * 60 / 800);
    final double end = math.min(1.0, start + 240 / 800);
    return AnimatedBuilder(
      animation: _entrance,
      child: child,
      builder: (BuildContext context, Widget? c) {
        final double t =
            Interval(start, end, curve: Curves.easeOut).transform(_entrance.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, r.u(16) * (1 - t)),
            child: c,
          ),
        );
      },
    );
  }

  Widget _modePill(Responsive r) {
    final String label = widget.result.mode == GameMode.daily
        ? 'DAILY · ${UtcDate.shortLabel()}'
        : 'CLASSIC';
    return Container(
      height: r.u(32),
      padding: EdgeInsets.symmetric(horizontal: r.u(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.u(16)),
        border: Border.all(color: AppColors.cyan, width: 1.5),
      ),
      child: Center(
        widthFactor: 1.0,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: AppTextStyles.family,
            fontFamilyFallback: AppTextStyles.fallback,
            fontSize: 14 * r.scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 2 * r.scale,
            height: 1.0,
            color: AppColors.cyan,
          ),
        ),
      ),
    );
  }

  /// Counts 0 → score over 600 ms (interval 0.15–0.9 of the entrance).
  Widget _score(Responsive r) {
    final TextStyle style = AppTextStyles.scoreBig.scaled(r.scale).copyWith(
      color: AppColors.white,
      shadows: <Shadow>[
        Shadow(color: AppColors.a(AppColors.cyan, 0.6), blurRadius: 24 * r.scale),
      ],
    );
    return AnimatedBuilder(
      animation: _entrance,
      builder: (BuildContext context, Widget? _) {
        final double t = const Interval(0.15, 0.9).transform(_entrance.value);
        return Text('${(widget.result.score * t).round()}', style: style);
      },
    );
  }

  Widget _newBestBadge(Responsive r) {
    return Container(
      width: r.u(140),
      height: r.u(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(r.u(18)),
      ),
      child: Text(
        'NEW BEST!',
        maxLines: 1,
        style: AppTextStyles.buttonSmall.scaled(r.scale).copyWith(
          fontSize: 16 * r.scale,
          letterSpacing: 2 * r.scale,
          height: 1.0,
          color: AppColors.bgTop,
        ),
      ),
    );
  }

  Widget _bestLine(Responsive r) {
    return Text(
      'BEST ${_commit.best}',
      maxLines: 1,
      style: AppTextStyles.body.scaled(r.scale).copyWith(
        fontSize: 18 * r.scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 2 * r.scale,
        height: 1.0,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _statsCard(Responsive r) {
    final int coins = _commit.coinsEarned;
    return AppCard(
      width: r.u(312),
      height: r.u(92),
      radius: r.u(20),
      padding: EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          _stat(r, '${widget.result.perfects}', 'PERFECTS', AppColors.white),
          _divider(r),
          _stat(r, '${widget.result.maxCombo}', 'MAX COMBO', AppColors.white),
          _divider(r),
          _stat(r, '+$coins', 'COINS', AppColors.amber),
        ],
      ),
    );
  }

  Widget _stat(Responsive r, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: <Widget>[
          SizedBox(height: r.u(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTextStyles.family,
                fontFamilyFallback: AppTextStyles.fallback,
                fontSize: 28 * r.scale,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: color,
              ),
            ),
          ),
          SizedBox(height: r.u(20)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTextStyles.family,
                fontFamilyFallback: AppTextStyles.fallback,
                fontSize: 12 * r.scale,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5 * r.scale,
                height: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Responsive r) {
    return Container(width: 1, height: r.u(92), color: AppColors.divider);
  }

  List<Widget> _elements(Responsive r) {
    final bool newBest = _commit.isNewBest;
    final int sBest = newBest ? 4 : 3;
    final int sStats = newBest ? 5 : 4;
    final int sPlay = newBest ? 6 : 5;
    final int sShare = newBest ? 7 : 6;
    final int sBottom = newBest ? 8 : 7;

    return <Widget>[
      Positioned(
        top: r.yPos(72),
        left: 0,
        right: 0,
        child: Center(child: _enter(r, 0, _modePill(r))),
      ),
      Positioned(
        top: r.yPos(124),
        left: 0,
        right: 0,
        child: Center(
          child: _enter(
            r,
            1,
            Text(
              'GAME OVER',
              maxLines: 1,
              style: AppTextStyles.title.scaled(r.scale).copyWith(height: 1.0),
            ),
          ),
        ),
      ),
      Positioned(
        top: r.yPos(190),
        left: 0,
        right: 0,
        child: Center(child: _enter(r, 2, _score(r))),
      ),
      if (newBest)
        Positioned(
          top: r.yPos(322),
          left: 0,
          right: 0,
          child: Center(
            child: _enter(
              r,
              3,
              PulseScale(
                end: 1.08,
                period: const Duration(milliseconds: 800),
                child: _newBestBadge(r),
              ),
            ),
          ),
        ),
      Positioned(
        top: r.yPos(368),
        left: 0,
        right: 0,
        child: Center(child: _enter(r, sBest, _bestLine(r))),
      ),
      Positioned(
        top: r.yPos(420),
        left: 0,
        right: 0,
        child: Center(child: _enter(r, sStats, _statsCard(r))),
      ),
      Positioned(
        top: r.yPos(540),
        left: 0,
        right: 0,
        child: Center(
          child: _enter(
            r,
            sPlay,
            PrimaryButton(label: 'PLAY AGAIN', onTap: _playAgain),
          ),
        ),
      ),
      Positioned(
        top: r.yPos(618),
        left: 0,
        right: 0,
        child: Center(
          child: _enter(
            r,
            sShare,
            SecondaryButton(
              label: 'SHARE',
              onTap: _sharing ? null : _share,
              loading: _sharing,
            ),
          ),
        ),
      ),
      Positioned(
        top: r.yPos(690),
        left: 0,
        right: 0,
        child: Center(
          child: _enter(
            r,
            sBottom,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MutedButton(
                  label: 'COPY GHOST',
                  icon: Icons.copy,
                  onTap: _copyGhost,
                  width: 148,
                  height: 48,
                ),
                SizedBox(width: r.u(16)),
                MutedButton(
                  label: 'HOME',
                  icon: Icons.home_outlined,
                  onTap: _home,
                  width: 148,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _home();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgTop,
        body: AppBackground(
          skin: _skin,
          child: ContentFrame(
            child: SizedBox(
              height: r.height,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FaintTowerPainter(
                          floors: widget.result.ghost.floors,
                          skin: _skin,
                        ),
                      ),
                    ),
                  ),
                  ..._elements(r),
                  if (_commit.isNewBest)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _Confetti(
                          seed: widget.result.ghost.seed,
                          colors: _skin.blockColors,
                          side: r.u(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section 21 background: the finished tower at 15% opacity, compressed so it
/// sits along the bottom edge.
class _FaintTowerPainter extends CustomPainter {
  const _FaintTowerPainter({required this.floors, required this.skin});

  final List<GhostFloor> floors;
  final SkinDef skin;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = floors.length;
    if (n == 0) return;
    final double pitch = (size.height * 0.42 / n).clamp(4.0, 26.0).toDouble();
    final double blockH = math.max(3.0, pitch - 2);
    final double scale = size.width * 0.62;
    final Paint paint = Paint();
    for (int i = 0; i < n; i++) {
      final GhostFloor f = floors[i];
      final double top = size.height - (i + 1) * pitch;
      final double w = f.w * scale;
      final double cx = size.width / 2 + (f.x + f.w / 2 - 0.5) * scale;
      paint.color = AppColors.a(skin.colorAt(i), 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, top, w, blockH),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FaintTowerPainter oldDelegate) =>
      oldDelegate.floors != floors || oldDelegate.skin != skin;
}

/// Section 21: 8 × 8 dp squares in the skin palette fall for 2 s on a new best.
class _Confetti extends StatefulWidget {
  const _Confetti({
    required this.seed,
    required this.colors,
    required this.side,
  });

  final int seed;
  final List<Color> colors;
  final double side;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.sway,
    required this.spin,
    required this.colorIndex,
  });

  final double x;
  final double delay;
  final double sway;
  final double spin;
  final int colorIndex;
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  static const int _count = 42;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: GameConst.confettiSeconds),
  )..forward();

  late final List<_ConfettiPiece> _pieces = _generate();

  List<_ConfettiPiece> _generate() {
    final math.Random rnd = math.Random(widget.seed);
    return List<_ConfettiPiece>.generate(_count, (int i) {
      return _ConfettiPiece(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.6,
        sway: (rnd.nextDouble() - 0.5) * 0.08,
        spin: (rnd.nextDouble() - 0.5) * 6,
        colorIndex: rnd.nextInt(widget.colors.length),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        return CustomPaint(
          painter: _ConfettiPainter(
            progress: _c.value,
            pieces: _pieces,
            colors: widget.colors,
            side: widget.side,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.pieces,
    required this.colors,
    required this.side,
  });

  final double progress;
  final List<_ConfettiPiece> pieces;
  final List<Color> colors;
  final double side;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _ConfettiPiece p in pieces) {
      if (progress <= p.delay) continue;
      final double local = (progress - p.delay) / (1 - p.delay);
      final double x = p.x * size.width +
          math.sin(local * math.pi * 3 + p.x * math.pi * 2) *
              size.height *
              p.sway;
      final double y = -side + local * (size.height + side * 2);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin);
      paint.color = colors[p.colorIndex % colors.length];
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pieces != pieces ||
      oldDelegate.colors != colors ||
      oldDelegate.side != side;
}
