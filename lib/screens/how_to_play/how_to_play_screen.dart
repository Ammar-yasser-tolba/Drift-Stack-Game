import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/glow_block.dart';

/// S2 How To Play (Sections 4 and 18). Three swipeable pages; first-run mode
/// ends on Home, replay mode pops back to the screen that opened it.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key, this.firstRun = true});

  final bool firstRun;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  static const List<String> _titles = <String>[
    'TAP TO DROP',
    'MISS A LITTLE, LOSE A LITTLE',
    'GO PERFECT',
  ];
  static const List<String> _texts = <String>[
    'Tap anywhere to drop the moving block on the tower.',
    "Anything that hangs over gets cut. Miss completely and it's over.",
    'Land it exactly for a PERFECT. Three in a row and your tower grows back. '
        'Every 10 floors, something changes.',
  ];

  final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    if (!StorageService.instance.tutorialSeen) {
      StorageService.instance.setTutorialSeen(true);
    }
    if (widget.firstRun) {
      Navigator.of(context).pushReplacementNamed(
        AppRouter.home,
        arguments: const RouteArgs(transition: RouteTransition.fade400),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _back() {
    if (_page > 0) {
      _goTo(_page - 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    final bool lastPage = _page == _titles.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: AppBackground(
          child: ContentFrame(
            child: SizedBox(
              height: r.height,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: r.yPos(90),
                    left: 0,
                    right: 0,
                    bottom: math.max(0, r.height - r.yPos(600)),
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (int page) => setState(() => _page = page),
                      children: <Widget>[
                        for (int i = 0; i < _titles.length; i++) _pageContent(r, i),
                      ],
                    ),
                  ),
                  if (!lastPage)
                    Positioned(
                      right: r.u(24),
                      top: r.yPos(16),
                      child: AppTextButton(label: 'SKIP', onTap: _finish),
                    ),
                  Positioned(
                    top: r.yPos(620),
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < _titles.length; i++)
                          _PageDot(
                            active: i == _page,
                            onTap: () => _goTo(i),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: r.yPos(690),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: PrimaryButton(
                        label: lastPage ? "LET'S PLAY" : 'NEXT',
                        onTap: lastPage ? _finish : () => _goTo(_page + 1),
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

  Widget _pageContent(Responsive r, int i) {
    final TextStyle title = AppTextStyles.h2.scaled(r.scale).copyWith(
      fontSize: 28 * r.scale,
      letterSpacing: 2 * r.scale,
      height: 1.15,
      color: AppColors.white,
    );
    final TextStyle body = AppTextStyles.body.scaled(r.scale).copyWith(
      fontSize: 18 * r.scale,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final TextPainter titleLayout = TextPainter(
          text: TextSpan(text: _titles[i], style: title),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 2,
        )..layout(maxWidth: r.u(312));
        final TextPainter bodyLayout = TextPainter(
          text: TextSpan(text: _texts[i], style: body),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 4,
        )..layout(maxWidth: r.u(296));

        final double titleGap = r.u(10);
        final double artGap = r.u(30);
        final double textHeight =
            titleLayout.height + titleGap + bodyLayout.height;
        // Short screens shrink the illustration to whatever is left, and drop
        // it entirely when that is too small to read as a drawing.
        final double artHeight = math.min(
          r.u(260),
          math.max(0.0, box.maxHeight - textHeight - artGap),
        );
        final bool showArt = artHeight >= r.u(80);

        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (showArt) ...<Widget>[
                SizedBox(
                  width: r.u(280),
                  height: artHeight,
                  child: AppCard(
                    radius: r.u(28),
                    padding: EdgeInsets.all(r.u(16)),
                    child: _illustration(i),
                  ),
                ),
                SizedBox(height: artGap),
              ],
              SizedBox(
                width: r.u(312),
                child: Text(
                  _titles[i],
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: title,
                ),
              ),
              SizedBox(height: titleGap),
              SizedBox(
                width: r.u(296),
                child: Text(
                  _texts[i],
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  style: body,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _illustration(int page) {
    switch (page) {
      case 0:
        return const _TapIllustration();
      case 1:
        return const _CutIllustration();
      default:
        return const _PerfectIllustration();
    }
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Responsive r = Responsive.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: r.u(48),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? r.u(24) : r.u(8),
            height: r.u(8),
            margin: EdgeInsets.symmetric(horizontal: r.u(5)),
            decoration: BoxDecoration(
              color: active ? AppColors.cyan : AppColors.a(AppColors.white, 0.3),
              borderRadius: BorderRadius.circular(r.u(4)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 1: a cyan block moves between two arrows while a finger taps it.
class _TapIllustration extends StatefulWidget {
  const _TapIllustration();

  @override
  State<_TapIllustration> createState() => _TapIllustrationState();
}

class _TapIllustrationState extends State<_TapIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double t = _c.value;
            final double blockW = w * 0.34;
            final double blockH = h * 0.09;
            final double top = h * 0.60;
            final double left = w / 2 - blockW / 2 + math.sin(2 * math.pi * t) * w * 0.16;
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: w * 0.08,
                  top: top + blockH / 2 - 8,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.a(AppColors.white, 0.6),
                  ),
                ),
                Positioned(
                  right: w * 0.08,
                  top: top + blockH / 2 - 8,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.a(AppColors.white, 0.6),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  child: GlowBlock(
                    width: blockW,
                    height: blockH,
                    color: AppColors.cyan,
                  ),
                ),
                Positioned(
                  left: w / 2 - 16,
                  top: h * 0.30,
                  child: const Icon(Icons.touch_app, size: 32, color: AppColors.white),
                ),
                for (int i = 0; i < 2; i++) _ripple(w, h, t, i),
              ],
            );
          },
        );
      },
    );
  }

  Widget _ripple(double w, double h, double t, int index) {
    final double p = (t + index * 0.5) % 1.0;
    final double size = 12 + p * 44;
    return Positioned(
      left: w / 2 - size / 2,
      top: h * 0.30 + 30 - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.a(AppColors.white, (1 - p) * 0.45),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 2: a pink block overhangs; the cut piece falls along a dotted path.
class _CutIllustration extends StatefulWidget {
  const _CutIllustration();

  @override
  State<_CutIllustration> createState() => _CutIllustrationState();
}

class _CutIllustrationState extends State<_CutIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double t = _c.value;
            final double baseY = h * 0.88;
            final double blockH = h * 0.085;
            final double gap = h * 0.012;
            final double wBase = w * 0.46;
            final double wSecond = w * 0.42;
            final double wPink = w * 0.40;
            final double cx = w / 2;
            final double topBase = baseY - blockH;
            final double topSecond = topBase - blockH - gap;
            final double topPink = topSecond - blockH - gap;
            final double pinkLeft = cx - wPink / 2 + w * 0.07;
            final double overW = w * 0.11;
            final double cutLeft = pinkLeft + wPink - overW;

            final double p = ((t - 0.15) / 0.55).clamp(0.0, 1.0);
            final double dx = p * w * 0.20;
            final double dy = p * p * h * 0.40;
            final Offset pathStart = Offset(cutLeft + overW / 2, topPink + blockH / 2);
            final Offset pathEnd = pathStart + Offset(w * 0.20, h * 0.40);

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: cx - wBase / 2,
                  top: topBase,
                  child: GlowBlock(width: wBase, height: blockH, color: AppColors.cyan),
                ),
                Positioned(
                  left: cx - wSecond / 2,
                  top: topSecond,
                  child: GlowBlock(width: wSecond, height: blockH, color: AppColors.cyan),
                ),
                Positioned(
                  left: pinkLeft,
                  top: topPink,
                  child: GlowBlock(width: wPink, height: blockH, color: AppColors.pink),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CutPathPainter(start: pathStart, end: pathEnd),
                  ),
                ),
                Positioned(
                  left: cutLeft + dx,
                  top: topPink + dy,
                  child: Transform.rotate(
                    angle: p * 0.45,
                    child: Opacity(
                      opacity: 1 - p,
                      child: GlowBlock(
                        width: overW,
                        height: blockH,
                        color: AppColors.pink,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CutPathPainter extends CustomPainter {
  const _CutPathPainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.a(AppColors.white, 0.35);
    final Offset control = Offset(
      (start.dx + end.dx) / 2 + (end.dx - start.dx) * 0.3,
      start.dy + (end.dy - start.dy) * 0.2,
    );
    for (int i = 1; i <= 8; i++) {
      final double t = i / 8;
      final double mt = 1 - t;
      final Offset p = start * (mt * mt) + control * (2 * mt * t) + end * (t * t);
      canvas.drawCircle(p, 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(_CutPathPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}

/// Page 3: a perfect amber block with sparkles and a green growth arrow.
class _PerfectIllustration extends StatefulWidget {
  const _PerfectIllustration();

  @override
  State<_PerfectIllustration> createState() => _PerfectIllustrationState();
}

class _PerfectIllustrationState extends State<_PerfectIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double t = _c.value;
            final double baseY = h * 0.88;
            final double blockH = h * 0.085;
            final double gap = h * 0.012;
            final double wBase = w * 0.46;
            final double wSecond = w * 0.42;
            final double wTop = w * 0.36;
            final double cx = w / 2;
            final double topBase = baseY - blockH;
            final double topSecond = topBase - blockH - gap;
            final double topTop = topSecond - blockH - gap;
            final Offset sparkleCenter = Offset(cx, topTop + blockH / 2);

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: cx - wBase / 2,
                  top: topBase,
                  child: GlowBlock(width: wBase, height: blockH, color: AppColors.cyan),
                ),
                Positioned(
                  left: cx - wSecond / 2,
                  top: topSecond,
                  child: GlowBlock(width: wSecond, height: blockH, color: AppColors.cyan),
                ),
                Positioned(
                  left: cx - wTop / 2,
                  top: topTop,
                  child: GlowBlock(width: wTop, height: blockH, color: AppColors.amber),
                ),
                for (int i = 0; i < 8; i++) _sparkle(sparkleCenter, w, h, t, i),
                Positioned(
                  left: cx + w * 0.24,
                  top: topTop - h * 0.03 + math.sin(2 * math.pi * t) * 4,
                  child: Icon(Icons.arrow_upward, size: w * 0.07, color: AppColors.success),
                ),
                Positioned(
                  top: h * 0.14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'PERFECT',
                      style: TextStyle(
                        fontFamily: AppTextStyles.family,
                        fontFamilyFallback: AppTextStyles.fallback,
                        fontSize: w * 0.075,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: AppColors.amber,
                        shadows: <Shadow>[
                          Shadow(
                            color: AppColors.a(AppColors.amber, 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sparkle(Offset center, double w, double h, double t, int i) {
    final double angle = i * math.pi / 4;
    final double opacity = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * t + angle));
    final Offset pos = center + Offset(math.cos(angle) * w * 0.30, math.sin(angle) * h * 0.12);
    return Positioned(
      left: pos.dx - 2,
      top: pos.dy - 2,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.a(AppColors.white, opacity),
        ),
      ),
    );
  }
}
