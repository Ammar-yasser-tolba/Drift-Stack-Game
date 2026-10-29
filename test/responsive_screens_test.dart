import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_nav.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/models/run_result.dart';
import 'package:drift_stack/screens/game/game_screen.dart';
import 'package:drift_stack/screens/game_over/game_over_screen.dart';
import 'package:drift_stack/screens/home/home_screen.dart';
import 'package:drift_stack/screens/how_to_play/how_to_play_screen.dart';
import 'package:drift_stack/screens/import_ghost/import_ghost_screen.dart';
import 'package:drift_stack/screens/settings/settings_screen.dart';
import 'package:drift_stack/screens/skins/skins_screen.dart';
import 'package:drift_stack/screens/splash/splash_screen.dart';
import 'package:drift_stack/services/storage_service.dart';

/// Android sizes worth covering, in dp: the legacy 320-wide phones, the usual
/// 360–412 phones, and 600/800 tablets. Portrait only — the manifest locks it.
const List<Size> _sizes = <Size>[
  Size(320, 480),
  Size(320, 568),
  Size(360, 640),
  Size(360, 800),
  Size(393, 852),
  Size(412, 915),
  Size(600, 960),
  Size(800, 1280),
];

RunResult _result({required int score}) => RunResult(
      mode: GameMode.classic,
      score: score,
      perfects: 1,
      maxCombo: 2,
      ghost: Ghost(
        score: score,
        seed: 3,
        floors: List<GhostFloor>.generate(
          score + 1,
          (int i) => const GhostFloor(0.25, 0.5),
        ),
      ),
    );

/// Mirrors the real app shell: portrait, fixed text scale (see main.dart).
Widget _app(Widget home) => MaterialApp(
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      builder: (BuildContext context, Widget? child) =>
          MediaQuery.withNoTextScaling(
        child: child ?? const SizedBox.shrink(),
      ),
      onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
        builder: (BuildContext context) => const SizedBox.shrink(),
      ),
      home: home,
    );

void main() {
  setUp(() => StorageService.instance.resetProgress());

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'HowToPlay': () => const HowToPlayScreen(),
    'Settings': () => const SettingsScreen(),
    'Skins': () => const SkinsScreen(),
    'ImportGhost': () => const ImportGhostScreen(),
    'GameOver': () => GameOverScreen(result: _result(score: 0)),
    'GameOver new best': () => GameOverScreen(result: _result(score: 6)),
  };

  for (final Size size in _sizes) {
    for (final MapEntry<String, Widget Function()> screen in screens.entries) {
      testWidgets('${screen.key} lays out at ${size.width}x${size.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(_app(screen.value()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        if (screen.key == 'GameOver new best') {
          await tester.pump(const Duration(milliseconds: 2100));
        }
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }

  testWidgets('HowToPlay pages fit at 320x480',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(_app(const HowToPlayScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Page 2 has the longest body text.
    await tester.tap(find.text('NEXT'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('NEXT'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("LET'S PLAY"), findsOneWidget);
  });

  testWidgets('ImportGhost stays usable with the keyboard open',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(_app(const ImportGhostScreen()));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Game plays without overflow at every size',
      (WidgetTester tester) async {
    for (final Size size in _sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
      await tester.pumpWidget(_app(const GameScreen(mode: GameMode.classic)));
      await tester.pump();
      await tester.tapAt(Offset(size.width / 2, size.height * 0.6));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  });

  testWidgets('Splash lays out at every size',
      (WidgetTester tester) async {
    for (final Size size in _sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
      await tester.pumpWidget(_app(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 400));
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  });
}
