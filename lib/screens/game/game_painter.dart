import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/skins.dart';
import '../../models/ghost.dart';
import 'game_engine.dart';

/// Paints the whole S3 world: floor, ghost, tower, moving block, cut pieces,
/// particles and floating texts (Sections 19.1 and 19.3).
class GamePainter extends CustomPainter {
  GamePainter({required this.engine, required this.skin});

  final GameEngine engine;
  final SkinDef skin;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double baseTop = engine.baseTop;
    final double baseBottom = engine.baseBottom;
    final double camera = engine.camera;
    final double dim = 1 - 0.5 * engine.overProgress;

    canvas.save();
    canvas.translate(engine.shakeOffsetX, 0);
    canvas.translate(0, camera);

    // Ground floor below the base block.
    final double floorBottom = h - camera;
    if (floorBottom > baseBottom) {
      canvas.drawRect(
        Rect.fromLTRB(0, baseBottom, w, floorBottom),
        Paint()..color = AppColors.floorFill,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, baseBottom, w, GameConst.floorLineWidth),
        Paint()..color = AppColors.floorLine,
      );
    }

    final double tilt = engine.tiltAngle;
    if (tilt != 0) {
      canvas.translate(w / 2, baseBottom);
      canvas.rotate(tilt);
      canvas.translate(-w / 2, -baseBottom);
    }

    _paintGhost(canvas, w, h, baseTop, dim);

    for (final PlacedBlock b in engine.blocks) {
      final double y = baseTop - b.floor * GameConst.blockHeight;
      final double screenY = y + camera;
      if (screenY > h + 40) continue;
      if (screenY < -40) break;
      _block(
        canvas,
        b.x + engine.stackX,
        y,
        b.w,
        skin.colorAt(b.floor),
        outline: skin.outline,
        opacity: dim,
      );
    }

    if (engine.phase != GamePhase.over) {
      _block(
        canvas,
        engine.movingX,
        engine.movingTopY,
        engine.movingW,
        skin.colorAt(engine.blocks.length),
        outline: skin.outline,
        opacity: dim,
      );
    }

    _paintPieces(canvas, h, camera, dim);
    _paintParticles(canvas, h, camera, dim);
    _paintFloats(canvas, h, camera, dim);

    canvas.restore();
  }

  void _paintGhost(Canvas canvas, double w, double h, double baseTop, double dim) {
    final Ghost? ghost = engine.ghost;
    if (ghost == null) return;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConst.ghostLineWidth
      ..color = AppColors.a(AppColors.white, GameConst.ghostOpacity * dim);
    for (int i = 0; i < ghost.floors.length; i++) {
      final double y = baseTop - i * GameConst.blockHeight;
      final double screenY = y + engine.camera;
      if (screenY > h + 40) continue;
      if (screenY < -40) break;
      final GhostFloor f = ghost.floors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            f.x * w + engine.stackX,
            y,
            f.w * w,
            GameConst.blockDrawHeight,
          ),
          const Radius.circular(GameConst.blockRadius),
        ),
        stroke,
      );
    }
  }

  void _paintPieces(Canvas canvas, double h, double camera, double dim) {
    for (final FallingPiece p in engine.pieces) {
      final double screenY = p.y + camera;
      if (screenY > h + 60 || screenY < -60) continue;
      final double fade = 1 - p.age / GameConst.fallFadeSeconds;
      final double cx = p.x + p.w / 2;
      final double cy = p.y + GameConst.blockDrawHeight / 2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rot);
      canvas.translate(-cx, -cy);
      _block(canvas, p.x, p.y, p.w, p.color, opacity: fade * dim);
      canvas.restore();
    }
  }

  void _paintParticles(Canvas canvas, double h, double camera, double dim) {
    final Paint paint = Paint();
    for (final BurstParticle p in engine.particles) {
      final double screenY = p.y + camera;
      if (screenY > h + 20 || screenY < -20) continue;
      final double fade = 1 - p.age / GameConst.burstLife;
      paint.color = AppColors.a(AppColors.white, fade * dim);
      canvas.drawCircle(
        Offset(p.x, p.y),
        GameConst.particleRadius,
        paint,
      );
    }
  }

  void _paintFloats(Canvas canvas, double h, double camera, double dim) {
    for (final FloatText f in engine.floats) {
      if (f.age < f.delay) continue;
      final double progress =
          ((f.age - f.delay) / GameConst.perfectTextSeconds).clamp(0.0, 1.0);
      final double screenY = f.y + camera;
      if (screenY > h + 60 || screenY < -60) continue;
      final double opacity = (1 - progress) * dim;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontFamily: AppTextStyles.family,
            fontFamilyFallback: AppTextStyles.fallback,
            fontSize: f.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            height: 1.0,
            color: AppColors.a(f.color, opacity),
            shadows: <Shadow>[
              Shadow(
                color: AppColors.a(f.color, 0.8 * opacity),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          f.x - tp.width / 2,
          f.y - GameConst.perfectTextRise * progress - tp.height / 2,
        ),
      );
    }
  }

  void _block(
    Canvas canvas,
    double x,
    double y,
    double w,
    Color color, {
    Color? outline,
    required double opacity,
  }) {
    if (w <= 0) return;
    const double bh = GameConst.blockDrawHeight;
    final RRect rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, bh),
      const Radius.circular(GameConst.blockRadius),
    );

    final double sigma = engine.lowEnd ? 6 : GameConst.glowSigma;
    canvas.drawRRect(
      rr,
      Paint()
        ..color = AppColors.a(color, GameConst.glowOpacity * opacity)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma),
    );
    canvas.drawRRect(rr, Paint()..color = AppColors.a(color, opacity));

    final RRect highlight = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, w, GameConst.highlightHeight),
      topLeft: const Radius.circular(GameConst.blockRadius),
      topRight: const Radius.circular(GameConst.blockRadius),
    );
    canvas.drawRRect(
      highlight,
      Paint()..color = AppColors.a(AppColors.white, GameConst.highlightOpacity * opacity),
    );

    if (outline != null) {
      canvas.drawRRect(
        rr.deflate(GameConst.pharaohOutlineWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = GameConst.pharaohOutlineWidth
          ..color = AppColors.a(outline, opacity),
      );
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
