import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/skins.dart';
import '../../models/game_mode.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/coins_chip.dart';
import '../../widgets/glow_block.dart';
import '../../widgets/pulse_scale.dart';

/// S1 Home (Sections 3 and 17).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService.instance;
  Timer? _dateTimer;

  @override
  void initState() {
    super.initState();
    // Section 3.3: re-check the UTC date every 60 s so the Daily card and
    // streak row flip over while Home stays open.
    _dateTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    super.dispose();
  }

  void _push(String route, {Object? args}) {
    Navigator.of(context).pushNamed(route, arguments: args).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _confirmExit() async {
    final bool? exit = await showAppDialog<bool>(
      context: context,
      title: 'Exit Drift Stack?',
      body: 'Are you sure you want to leave?',
      buttons: const <DialogButton<bool>>[
        DialogButton<bool>(label: 'STAY', value: false, style: DialogButtonStyle.muted),
        DialogButton<bool>(label: 'EXIT', value: true),
      ],
      backValue: false,
    );
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: AppBackground(
          child: ContentFrame(
            child: SizedBox(
              height: r.height,
              child: AnimatedBuilder(
                animation: _storage,
                builder: (BuildContext context, Widget? child) => _content(r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(Responsive r) {
    final SkinDef skin = _storage.equippedSkin;
    final double titleSize = (r.isShort ? 44 : 56) * r.scale;
    final TextStyle titleStyle = AppTextStyles.display
        .scaled(r.scale)
        .copyWith(fontSize: titleSize, letterSpacing: 8 * r.scale, height: 1.0);
    final TextStyle bestStyle = AppTextStyles.title
        .scaled(r.scale)
        .copyWith(letterSpacing: 0, height: 1.0);

    return Stack(
      children: <Widget>[
        if (!r.isShort)
          Positioned(
            left: 0,
            right: 0,
            top: r.yPos(250),
            child: Center(
              child: SizedBox(
                width: r.u(180),
                height: r.u(137),
                child: _DecorativeTower(skin: skin),
              ),
            ),
          ),

        // --- top bar ---
        Positioned(
          left: r.u(24),
          top: r.yPos(16),
          child: CoinsChip(
            coins: _storage.coins,
            onTap: () => _push(AppRouter.skins),
          ),
        ),
        Positioned(
          right: r.u(24),
          top: r.yPos(12),
          child: IconCircleButton(
            icon: Icons.settings,
            semanticLabel: 'Settings',
            onTap: () => _push(AppRouter.settings),
          ),
        ),

        // --- title ---
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(100),
          child: Center(child: Text('DRIFT', style: titleStyle)),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(160),
          child: Center(
            child: Text(
              'STACK',
              style: titleStyle.copyWith(
                color: AppColors.cyan,
                shadows: <Shadow>[Shadow(color: AppColors.cyan, blurRadius: 16 * r.scale)],
              ),
            ),
          ),
        ),

        // --- best ---
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(410),
          child: Center(
            child: Text(
              'BEST',
              style: AppTextStyles.caption.scaled(r.scale).copyWith(letterSpacing: 3 * r.scale),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(430),
          child: Center(
            child: Text(
              _storage.bestClassic == 0 ? '—' : '${_storage.bestClassic}',
              style: bestStyle,
            ),
          ),
        ),

        // --- play ---
        Positioned(
          left: 0,
          right: 0,
          top: r.yPos(510),
          child: Center(
            child: PulseScale(
              child: PrimaryButton(
                label: 'PLAY',
                onTap: () => _push(
                  AppRouter.game,
                  args: const RouteArgs(data: GameMode.classic),
                ),
              ),
            ),
          ),
        ),

        // --- daily card ---
        Positioned(
          left: r.u(24),
          right: r.u(24),
          top: r.yPos(594),
          child: _DailyCard(
            playedToday: _storage.dailyPlayedToday,
            bestToday: _storage.dailyBestToday,
            streak: _storage.displayStreak,
            onTap: () => _push(
              AppRouter.game,
              args: const RouteArgs(data: GameMode.daily),
            ),
          ),
        ),

        // --- bottom row ---
        Positioned(
          left: r.u(24),
          top: r.yPos(708),
          child: Row(
            children: <Widget>[
              _HomeAction(
                icon: Icons.palette,
                label: 'Skins',
                onTap: () => _push(AppRouter.skins),
              ),
              SizedBox(width: r.u(12)),
              _HomeAction(
                icon: Icons.visibility_outlined,
                label: 'Ghost',
                onTap: () => _push(AppRouter.importGhost),
              ),
              SizedBox(width: r.u(12)),
              _HomeAction(
                icon: Icons.help_outline,
                label: 'How to play',
                onTap: () => _push(
                  AppRouter.howToPlay,
                  args: const RouteArgs(data: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section 17: five blocks sliding ±10 dp, period 3 s, 0.3 s apart.
class _DecorativeTower extends StatefulWidget {
  const _DecorativeTower({required this.skin});

  final SkinDef skin;

  @override
  State<_DecorativeTower> createState() => _DecorativeTowerState();
}

class _DecorativeTowerState extends State<_DecorativeTower>
    with SingleTickerProviderStateMixin {
  static const List<double> _widths = <double>[180, 170, 150, 150, 120]; // bottom → top

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    // Each block gets its own layer: the shadows are rasterized once and only
    // the layer transform changes while the tower slides.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          final double t = _c.value;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              for (int i = _widths.length - 1; i >= 0; i--)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 0 ? 0 : r.u(3)),
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(2 * math.pi * (t + i * 0.1)) * r.u(10),
                      0,
                    ),
                    child: RepaintBoundary(
                      child: Opacity(
                        opacity: 0.9,
                        child: GlowBlock(
                          width: r.u(_widths[i]),
                          height: r.u(25),
                          color: widget.skin.colorAt(i),
                          outline: widget.skin.outline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Section 3.2 / 17: Daily Challenge card in its two states.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.playedToday,
    required this.bestToday,
    required this.streak,
    required this.onTap,
  });

  final bool playedToday;
  final int bestToday;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return AppCard(
      height: r.u(96),
      radius: r.u(20),
      borderColor: AppColors.a(AppColors.pink, 0.6),
      padding: EdgeInsets.symmetric(horizontal: r.u(16), vertical: r.u(12)),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(Icons.calendar_today, size: r.u(36), color: AppColors.pink),
          SizedBox(width: r.u(12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DAILY CHALLENGE',
                    maxLines: 1,
                    style: AppTextStyles.button.scaled(r.scale).copyWith(
                      fontSize: 18 * r.scale,
                      letterSpacing: 1.5 * r.scale,
                      color: AppColors.white,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    playedToday ? "Today's best: $bestToday" : 'Same tower for everyone today',
                    maxLines: 1,
                    style: AppTextStyles.body.scaled(r.scale).copyWith(fontSize: 14 * r.scale),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.local_fire_department, size: r.u(16), color: AppColors.amber),
                    SizedBox(width: r.u(6)),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          streak > 0 ? '$streak day streak' : 'Start a streak today',
                          maxLines: 1,
                          style: AppTextStyles.caption.scaled(r.scale).copyWith(
                            fontSize: 13 * r.scale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: r.u(12)),
          Container(
            width: r.u(72),
            height: r.u(36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(r.u(18)),
            ),
            child: Text(
              playedToday ? 'AGAIN' : 'PLAY',
              style: AppTextStyles.button.scaled(r.scale).copyWith(
                fontSize: 16 * r.scale,
                letterSpacing: 0,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 17: the three 96 × 72 cards in the bottom row.
class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return AppCard(
      width: r.u(96),
      height: r.u(72),
      radius: r.u(16),
      padding: EdgeInsets.only(top: r.u(14)),
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Icon(icon, size: r.u(28), color: AppColors.white),
          SizedBox(height: r.u(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.caption.scaled(r.scale).copyWith(
                fontSize: 13 * r.scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
