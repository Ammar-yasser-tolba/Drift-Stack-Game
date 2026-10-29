import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/constants/game_constants.dart';
import 'package:drift_stack/core/theme/skins.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/screens/game/game_engine.dart';
import 'package:drift_stack/screens/game/game_painter.dart';

void main() {
  const Size size = Size(390, 844);

  GameEngine make() => GameEngine(
        mode: GameMode.classic,
        skin: Skins.all.first,
        size: size,
      );

  Future<ui.Image> render(GamePainter painter) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    return recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
  }

  Future<int?> topRow(ui.Image image, int x) async {
    final ByteData data =
        (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final int stride = 4 * size.width.toInt();
    for (int y = 0; y < size.height.toInt(); y++) {
      final int o = y * stride + x * 4;
      final int r = data.getUint8(o);
      final int g = data.getUint8(o + 1);
      final int b = data.getUint8(o + 2);
      if (r + g + b > 400) return y;
    }
    return null;
  }

  Future<int?> leftEdge(ui.Image image, int y) async {
    final ByteData data =
        (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final int stride = 4 * size.width.toInt();
    for (int x = 0; x < size.width.toInt(); x++) {
      final int o = y * stride + x * 4;
      final int r = data.getUint8(o);
      final int g = data.getUint8(o + 1);
      final int b = data.getUint8(o + 2);
      if (r + g + b > 400) return x;
    }
    return null;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('camera scrolls the tower down by the camera offset', (WidgetTester tester) async {
    final GameEngine engine = make();
    final int x = (size.width / 2).round();

    final int? y0 = await tester.runAsync<int?>(() async {
      final ui.Image before =
          await render(GamePainter(engine: engine, skin: engine.skin));
      return topRow(before, x);
    });
    final int baseTop = engine.baseTop.round();
    expect(y0, isNotNull);
    expect((y0! - baseTop).abs(), lessThanOrEqualTo(2));

    engine.camera = 100;
    final int? y1 = await tester.runAsync<int?>(() async {
      final ui.Image after =
          await render(GamePainter(engine: engine, skin: engine.skin));
      return topRow(after, x);
    });
    expect(y1, isNotNull);
    expect((y1! - y0 - 100).abs(), lessThanOrEqualTo(2));
  });

  testWidgets('moving block is drawn one pitch above the stack', (WidgetTester tester) async {
    final GameEngine engine = make()..start();

    final int? top = await tester.runAsync<int?>(() async {
      final ui.Image image =
          await render(GamePainter(engine: engine, skin: engine.skin));
      final int x = (engine.movingX + engine.movingW / 2).round();
      return topRow(image, x);
    });
    expect(top, isNotNull);
    expect(
      (top! - (engine.movingTopY)).abs(),
      lessThanOrEqualTo(2),
      reason: 'movingTopY=${engine.movingTopY}, painted top=$top',
    );
    expect(
      engine.baseTop - engine.movingTopY,
      GameConst.blockHeight,
    );
  });

  testWidgets('placed blocks are painted with the tower drift', (WidgetTester tester) async {
    final GameEngine engine = make();
    final int y = (engine.baseTop + 10).round();

    final int? x0 = await tester.runAsync<int?>(() async {
      final ui.Image image =
          await render(GamePainter(engine: engine, skin: engine.skin));
      return leftEdge(image, y);
    });
    expect(x0, isNotNull);
    expect((x0! - engine.blocks.single.x).abs(), lessThanOrEqualTo(2));

    engine.stackX = 24;
    final int? x1 = await tester.runAsync<int?>(() async {
      final ui.Image image =
          await render(GamePainter(engine: engine, skin: engine.skin));
      return leftEdge(image, y);
    });
    expect(x1, isNotNull);
    expect(x1! - x0, closeTo(24, 2));
  });
}
