import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/skins.dart';
import '../../core/utils/utc_date.dart';
import '../../models/game_mode.dart';
import '../../models/ghost.dart';
import '../../models/run_result.dart';

/// Section 9: the hidden 1080 × 1350 share card — skin background, the final
/// tower, the score, the mode and the date.
class ShareCard {
  ShareCard._();

  static const double width = 1080;
  static const double height = 1350;

  static Future<Uint8List> render({
    required RunResult result,
    required SkinDef skin,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect rect = Rect.fromLTWH(0, 0, width, height);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, height),
          <Color>[skin.bgTop, skin.bgBottom],
        ),
    );

    _tower(canvas, result.ghost.floors, skin);

    final TextPainter title = _text(
      'DRIFT STACK',
      68,
      FontWeight.w700,
      10,
      AppColors.white,
    );
    title.paint(canvas, Offset((width - title.width) / 2, 92));

    final TextPainter score = _text(
      '${result.score}',
      190,
      FontWeight.w900,
      0,
      AppColors.white,
      shadows: <Shadow>[
        Shadow(color: AppColors.a(AppColors.cyan, 0.75), blurRadius: 32),
      ],
    );
    score.paint(canvas, Offset((width - score.width) / 2, 940));

    final String label = result.mode == GameMode.daily
        ? 'DAILY · ${UtcDate.fullLabel()}'
        : 'CLASSIC';
    final TextPainter mode = _text(
      label,
      42,
      FontWeight.w600,
      4,
      AppColors.textSecondary,
    );
    mode.paint(canvas, Offset((width - mode.width) / 2, 1170));

    final ui.Image image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static void _tower(Canvas canvas, List<GhostFloor> floors, SkinDef skin) {
    if (floors.isEmpty) return;
    final int n = floors.length;
    final double pitch = (440 / n).clamp(4.0, 46.0).toDouble();
    final double blockH = pitch * 0.86;
    const double bottom = 880;
    const double scale = width * 0.62;
    for (int i = 0; i < n; i++) {
      final GhostFloor f = floors[i];
      final double top = bottom - (i + 1) * pitch;
      final double w = f.w * scale;
      final double cx = width / 2 + (f.x + f.w / 2 - 0.5) * scale;
      final RRect rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w / 2, top, w, blockH),
        Radius.circular(blockH / 2 < 8 ? blockH / 2 : 8),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = AppColors.a(skin.colorAt(i), 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(rr, Paint()..color = skin.colorAt(i));
    }
  }

  static TextPainter _text(
    String text,
    double size,
    FontWeight weight,
    double letterSpacing,
    Color color, {
    List<Shadow>? shadows,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTextStyles.family,
          fontFamilyFallback: AppTextStyles.fallback,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.0,
          color: color,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
