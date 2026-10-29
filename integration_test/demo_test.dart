// Automated UI tour used to record the demo video and the screenshot set.
// Run with: flutter drive --profile -d <device>
//   --driver=test_driver/integration_test.dart
//   --target=integration_test/demo_test.dart
//
// The test prints "DEMO_MARK:<name>" right before every screen is held, so an
// external adb script can grab a screenshot at a deterministic moment.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:drift_stack/main.dart' as app;
import 'package:drift_stack/screens/game/game_engine.dart';
import 'package:drift_stack/screens/game/game_painter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo tour', (WidgetTester tester) async {
    // Give the recorder time to start before the first Flutter frame.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await app.main();

    // ---------------------------------------------------------------- home
    await waitFor(tester, find.text('DRIFT'), 'home');
    mark('home');
    await hold(tester, 2.4);

    // ------------------------------------------------------------ settings
    await tester.tap(find.byIcon(Icons.settings));
    await waitFor(tester, find.text('Sound'), 'settings');
    mark('settings');
    await hold(tester, 2.4);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('DRIFT'), 'home again');

    // --------------------------------------------------------------- skins
    await tester.tap(find.text('Skins'));
    await waitFor(tester, find.text('Neon'), 'skins');
    mark('skins');
    await hold(tester, 2.4);

    // Equip Desert.
    await tester.tap(find.text('Desert'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('EQUIP'));
    await waitFor(tester, find.text('Desert equipped'), 'desert equipped');
    mark('skins_desert');
    await hold(tester, 2.4);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('DRIFT'), 'home after desert');

    // ------------------------------------------- desert game (cut + miss)
    GameEngine engine = await openGame(tester);
    await hold(tester, 0.7);
    dropNow(tester, engine); // start the run
    await playFloors(tester, engine, 3);
    await tester.tap(find.byIcon(Icons.pause));
    await waitFor(tester, find.text('PAUSED'), 'paused');
    mark('pause');
    await hold(tester, 2.2);
    await tester.tap(find.text('RESUME'));
    mark('countdown');
    await hold(tester, 0.9);
    await hold(tester, 2.4); // let the 3-2-1 finish
    await playFloors(tester, engine, 1);
    // Show a normal placement: tap as far from the tower as the block goes.
    await waitForEdge(tester, engine);
    dropNow(tester, engine);
    mark('desert_playing');
    await hold(tester, 1.6);
    await endRunByMiss(tester, engine);
    await waitFor(tester, find.text('GAME OVER'), 'desert game over');
    mark('game_over_desert');
    await hold(tester, 3.0);
    await tester.tap(find.text('HOME'));
    await waitFor(tester, find.text('DRIFT'), 'home after desert run');

    // ------------------------------------------------------ pharaoh skin
    await tester.tap(find.text('Skins'));
    await waitFor(tester, find.text('Pharaoh'), 'skins again');
    await tester.tap(find.text('Pharaoh'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('EQUIP'));
    await waitFor(tester, find.text('Pharaoh equipped'), 'pharaoh equipped');
    mark('skins_pharaoh');
    await hold(tester, 2.4);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('DRIFT'), 'home after pharaoh');

    engine = await openGame(tester);
    await hold(tester, 0.7);
    dropNow(tester, engine);
    await playFloors(tester, engine, 5);
    mark('pharaoh_playing');
    await hold(tester, 1.6);
    await tester.tap(find.byIcon(Icons.pause));
    await waitFor(tester, find.text('PAUSED'), 'pharaoh paused');
    await tester.tap(find.text('HOME'));
    await waitFor(tester, find.text('Quit this run?'), 'quit dialog');
    await tester.tap(find.text('QUIT'));
    await waitFor(tester, find.text('DRIFT'), 'home after pharaoh run');

    // --------------------------------------------------------- how to play
    await tester.tap(find.text('How to play'));
    await waitFor(tester, find.text('TAP TO DROP'), 'how to play 1');
    mark('how_to_play');
    await hold(tester, 2.4);
    await tester.tap(find.text('NEXT'));
    await waitFor(tester, find.text('MISS A LITTLE, LOSE A LITTLE'), 'page 2');
    mark('how_to_play_2');
    await hold(tester, 2.4);
    await tester.tap(find.text('NEXT'));
    await waitFor(tester, find.text('GO PERFECT'), 'page 3');
    mark('how_to_play_3');
    await hold(tester, 2.4);
    await tester.tap(find.text("LET'S PLAY"));
    await waitFor(tester, find.text('DRIFT'), 'home after tutorial');

    // --------------------------------------------------------- import ghost
    await tester.tap(find.text('Ghost'));
    await waitFor(tester, find.text('PASTE'), 'ghost screen');
    mark('import_ghost');
    await hold(tester, 2.4);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('DRIFT'), 'home after ghost');

    // ------------------------------------------------------- neon skin
    await tester.tap(find.text('Skins'));
    await waitFor(tester, find.text('Neon'), 'skins for neon');
    await tester.tap(find.text('Neon'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('EQUIP'));
    await waitFor(tester, find.text('Neon equipped'), 'neon equipped');
    mark('skins_neon');
    await hold(tester, 2.4);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await waitFor(tester, find.text('DRIFT'), 'home after neon');

    // -------------------------------------------- final long neon gameplay
    engine = await openGame(tester);
    await hold(tester, 0.7);
    dropNow(tester, engine);
    await playFor(tester, engine, const Duration(seconds: 7));
    mark('neon_playing');
    await hold(tester, 1.6);
    await playFor(tester, engine, const Duration(seconds: 7));
    await tester.tap(find.byIcon(Icons.pause));
    await waitFor(tester, find.text('PAUSED'), 'final paused');
    mark('pause_neon');
    await hold(tester, 2.2);
    await tester.tap(find.text('RESUME'));
    await hold(tester, 3.4);
    await playFor(tester, engine, const Duration(seconds: 5));
    await tester.tap(find.byIcon(Icons.pause));
    await waitFor(tester, find.text('PAUSED'), 'final paused 2');
    await tester.tap(find.text('HOME'));
    await waitFor(tester, find.text('Quit this run?'), 'quit dialog 2');
    await tester.tap(find.text('QUIT'));
    await waitFor(tester, find.text('DRIFT'), 'final home');
    mark('home_end');
    await hold(tester, 3.0);
  });
}

// ---------------------------------------------------------------- helpers

void mark(String name) {
  // ignore: avoid_print
  print('DEMO_MARK:$name');
}

Future<void> hold(WidgetTester tester, double seconds) async {
  final DateTime end =
      DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder,
  String label, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for "$label"');
    }
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pump(const Duration(milliseconds: 60));
}

Finder gamePaint() => find.byWidgetPredicate(
      (Widget w) => w is CustomPaint && w.painter is GamePainter,
    );

GameEngine engineOf(WidgetTester tester) {
  final CustomPaint cp = tester.widget<CustomPaint>(gamePaint().first);
  return (cp.painter! as GamePainter).engine;
}

/// Opens a classic run from Home and returns its engine once the screen is up.
Future<GameEngine> openGame(WidgetTester tester) async {
  await tester.tap(find.text('PLAY').first);
  await waitFor(tester, find.byWidgetPredicate(
    (Widget w) => w is CustomPaint && w.painter is GamePainter,
  ), 'game screen');
  return engineOf(tester);
}

/// Drops synchronously from the game's own tap callback so the engine state
/// that the bot just read is exactly the state used for the placement.
void dropNow(WidgetTester tester, GameEngine engine) {
  final GestureDetector gd = tester.widget<GestureDetector>(
    find
        .byWidgetPredicate(
          (Widget w) => w is GestureDetector && w.onTapDown != null,
        )
        .first,
  );
  gd.onTapDown!(TapDownDetails());
}

Future<void> playFloors(
  WidgetTester tester,
  GameEngine engine,
  int floors, {
  double gap = 0.45,
}) async {
  final int target = engine.score + floors;
  DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
  while (engine.phase == GamePhase.playing && engine.score < target) {
    final PlacedBlock top = engine.blocks.last;
    final double topX = top.x + engine.stackX;
    final double dx = engine.movingX - topX;
    final bool gapOk =
        DateTime.now().difference(last).inMilliseconds >= (gap * 1000);
    if (dx.abs() <= 5 && gapOk) {
      dropNow(tester, engine);
      last = DateTime.now();
      await tester.pump(const Duration(milliseconds: 25));
    } else {
      await tester.pump(const Duration(milliseconds: 4));
    }
  }
}

Future<void> playFor(
  WidgetTester tester,
  GameEngine engine,
  Duration span, {
  double gap = 0.55,
}) async {
  final DateTime end = DateTime.now().add(span);
  DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
  while (engine.phase == GamePhase.playing && DateTime.now().isBefore(end)) {
    final PlacedBlock top = engine.blocks.last;
    final double topX = top.x + engine.stackX;
    final double dx = engine.movingX - topX;
    final bool gapOk =
        DateTime.now().difference(last).inMilliseconds >= (gap * 1000);
    if (dx.abs() <= 5 && gapOk) {
      dropNow(tester, engine);
      last = DateTime.now();
      await tester.pump(const Duration(milliseconds: 25));
    } else {
      await tester.pump(const Duration(milliseconds: 4));
    }
  }
}

/// Waits until the moving block sits at a screen edge (largest possible cut).
Future<void> waitForEdge(WidgetTester tester, GameEngine engine) async {
  final DateTime end = DateTime.now().add(const Duration(seconds: 5));
  while (engine.phase == GamePhase.playing && DateTime.now().isBefore(end)) {
    final double travelMax = engine.size.width - engine.movingW;
    if (engine.movingX <= 1 || engine.movingX >= travelMax - 1) return;
    await tester.pump(const Duration(milliseconds: 4));
  }
}

/// Cuts once at a screen edge, then drops the next block while it is
/// completely off the tower to finish the run.
Future<void> endRunByMiss(WidgetTester tester, GameEngine engine) async {
  final DateTime end = DateTime.now().add(const Duration(seconds: 12));
  bool needCut = true;
  while (engine.phase == GamePhase.playing && DateTime.now().isBefore(end)) {
    if (needCut) {
      final double travelMax = engine.size.width - engine.movingW;
      if (engine.movingX <= 1 || engine.movingX >= travelMax - 1) {
        dropNow(tester, engine);
        needCut = false;
        await tester.pump(const Duration(milliseconds: 30));
      } else {
        await tester.pump(const Duration(milliseconds: 4));
      }
      continue;
    }
    final PlacedBlock top = engine.blocks.last;
    final double topX = top.x + engine.stackX;
    final bool disjoint = engine.movingX > topX + top.w + 0.5 ||
        engine.movingX + engine.movingW < topX - 0.5;
    if (disjoint) {
      dropNow(tester, engine);
      await tester.pump(const Duration(milliseconds: 30));
      if (engine.phase == GamePhase.playing) needCut = true;
    } else {
      await tester.pump(const Duration(milliseconds: 4));
    }
  }
}
