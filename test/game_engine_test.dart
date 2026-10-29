
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/constants/game_constants.dart';
import 'package:drift_stack/core/theme/skins.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/models/run_result.dart';
import 'package:drift_stack/screens/game/game_engine.dart';

void main() {
  const Size size = Size(390, 844);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => null,
    );
  });

  GameEngine make() => GameEngine(
        mode: GameMode.classic,
        skin: Skins.all.first,
        size: size,
      );

  void dropPerfect(GameEngine e) {
    e.update(0.2);
    e.movingX = e.blocks.last.x + e.stackX;
    e.tapDrop();
  }

  test('base block starts at the spec width', () {
    final GameEngine e = make();
    expect(e.phase, GamePhase.ready);
    expect(e.blocks.single.w, closeTo(390 * GameConst.startWidthFrac, 0.01));
    expect(e.blocks.single.x, closeTo((390 - e.blocks.single.w) / 2, 0.01));
  });

  test('perfect drops keep width and grow by 8 dp from the 3rd combo', () {
    final GameEngine e = make()..start();
    final double startW = e.blocks.single.w;

    dropPerfect(e);
    expect(e.score, 1);
    expect(e.perfects, 1);
    expect(e.combo, 1);
    expect(e.blocks.last.w, closeTo(startW, 0.01));

    dropPerfect(e);
    expect(e.combo, 2);
    expect(e.blocks.last.w, closeTo(startW, 0.01));

    dropPerfect(e);
    expect(e.combo, 3);
    expect(e.maxCombo, 3);
    expect(e.blocks.last.w, closeTo(startW + GameConst.growthPerPerfect, 0.01));
    expect(e.blocks.last.x, closeTo(e.blocks[e.blocks.length - 2].x - GameConst.growthPerPerfect / 2, 0.01));

    dropPerfect(e);
    expect(e.blocks.last.w, closeTo(startW + 2 * GameConst.growthPerPerfect, 0.01));
  });

  test('normal drop trims the tower to the overlap and breaks the combo', () {
    final GameEngine e = make()..start();
    dropPerfect(e);
    final PlacedBlock prev = e.blocks.last;

    e.update(0.2);
    e.movingX = prev.x + e.stackX - 20;
    e.tapDrop();

    expect(e.phase, GamePhase.playing);
    expect(e.combo, 0);
    expect(e.blocks.last.w, closeTo(prev.w - 20, 0.01));
    expect(e.blocks.last.x, closeTo(prev.x, 0.01));
    expect(e.pieces, isNotEmpty);
  });

  test('a drop with less than the minimum overlap ends the run', () {
    final GameEngine e = make()..start();
    e.update(0.2);
    e.movingX = e.blocks.single.x +
        e.stackX +
        e.blocks.single.w -
        GameConst.minWidth +
        1;
    e.tapDrop();

    expect(e.phase, GamePhase.over);
    expect(e.overT, 0);

    e.update(GameConst.gameOverAnim.inMilliseconds / 2000);
    expect(e.overProgress, greaterThan(0));
    e.update(GameConst.gameOverAnim.inMilliseconds / 1000);
    expect(e.overProgress, 1);
  });

  test('speed grows per floor up to the cap', () {
    final GameEngine e = make()..start();
    for (int i = 0; i < 12; i++) {
      dropPerfect(e);
    }
    expect(e.speed, closeTo(GameConst.startSpeed + 12 * GameConst.speedGain, 0.01));

    for (int i = 0; i < 80; i++) {
      dropPerfect(e);
    }
    expect(e.speed, GameConst.maxSpeed);
  });

  test('camera starts scrolling 8 floors above the base', () {
    final GameEngine e = make()..start();
    for (int i = 0; i < 6; i++) {
      dropPerfect(e);
    }
    e.update(1);
    expect(e.camera, closeTo(0, 0.01));

    for (int i = 0; i < 6; i++) {
      dropPerfect(e);
    }
    e.update(1);
    e.update(1);
    expect(e.camera, closeTo((12 - GameConst.cameraFloorsAboveBase) * GameConst.blockHeight, 1));
  });

  test('an event starts every 10 floors and lasts 5', () {
    final GameEngine e = make()..start();
    for (int i = 0; i < 9; i++) {
      dropPerfect(e);
    }
    expect(e.event, isNull);

    dropPerfect(e);
    expect(e.score, 10);
    final ActiveEvent? ev = e.event;
    expect(ev, isNotNull);
    expect(ev!.floorsLeft, GameConst.eventLength);

    for (int i = 0; i < GameConst.eventLength; i++) {
      dropPerfect(e);
    }
    expect(ev.floorsLeft, 0);
    e.update(GameConst.eventFadeOutSeconds);
    expect(e.event, isNull);
  });

  test('result carries score, seed and the normalized tower', () {
    final GameEngine e = make()..start();
    dropPerfect(e);
    dropPerfect(e);

    final RunResult result = e.result();
    expect(result.mode, GameMode.classic);
    expect(result.score, 2);
    expect(result.perfects, 2);
    expect(result.maxCombo, 2);
    expect(result.ghost.score, 2);
    expect(result.ghost.seed, e.seed);
    expect(result.ghost.floors.length, e.blocks.length);

    final GhostFloor first = result.ghost.floors.first;
    expect(first.x, closeTo(e.blocks.first.x / size.width, 1e-9));
    expect(first.w, closeTo(e.blocks.first.w / size.width, 1e-9));
  });

  test('the whole tower drifts while playing and stays on screen', () {
    final GameEngine e = make();
    expect(e.stackX, 0);
    e.start();
    e.update(0.2);
    expect(e.stackX, greaterThan(0));

    double minSeen = 0;
    double maxSeen = 0;
    for (int i = 0; i < 600; i++) {
      e.update(1 / 60);
      final double left = e.blocks
          .map((PlacedBlock b) => b.x + e.stackX)
          .reduce(math.min);
      final double right = e.blocks
          .map((PlacedBlock b) => b.x + b.w + e.stackX)
          .reduce(math.max);
      expect(left, greaterThanOrEqualTo(-0.01));
      expect(right, lessThanOrEqualTo(size.width + 0.01));
      minSeen = math.min(minSeen, e.stackX);
      maxSeen = math.max(maxSeen, e.stackX);
    }
    expect(minSeen, lessThan(0));
    expect(maxSeen, greaterThan(0));
  });

  test('the tower freezes when the run is over', () {
    final GameEngine e = make()..start();
    e.update(0.2);
    e.movingX = size.width * 2;
    e.tapDrop();
    expect(e.phase, GamePhase.over);
    final double frozen = e.stackX;
    e.update(0.2);
    expect(e.stackX, frozen);
  });

  test('a drop is judged against the drifted tower, not the stored x', () {
    final GameEngine e = make()..start();
    e.update(0.1);
    final PlacedBlock top = e.blocks.last;
    e.stackX = 15;
    e.movingX = top.x;
    e.tapDrop();

    expect(e.phase, GamePhase.playing);
    expect(e.combo, 0);
    expect(e.blocks.last.w, closeTo(top.w - 15, 0.01));
    expect(e.blocks.last.x, closeTo(top.x, 0.01));
  });
}
