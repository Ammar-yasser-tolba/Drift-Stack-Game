import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_nav.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/screens/settings/settings_screen.dart';
import 'package:drift_stack/services/storage_service.dart';
import 'package:drift_stack/widgets/app_toggle.dart';

Ghost _tower(int score) => Ghost(
      score: score,
      seed: 5,
      floors: List<GhostFloor>.generate(
        score + 1,
        (int i) => const GhostFloor(0.3, 0.4),
      ),
    );

Future<void> _pumpSettings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      home: const SettingsScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => StorageService.instance.resetProgress());

  testWidgets('toggles save instantly', (WidgetTester tester) async {
    await _pumpSettings(tester);

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Replay tutorial'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Reset progress'), findsOneWidget);
    expect(find.text('Drift Stack v1.0.0'), findsOneWidget);

    expect(StorageService.instance.soundOn, isTrue);
    await tester.tap(find.byType(AppToggle).first);
    await tester.pumpAndSettle();
    expect(StorageService.instance.soundOn, isFalse);

    await tester.tap(find.byType(AppToggle).last);
    await tester.pumpAndSettle();
    expect(StorageService.instance.hapticsOn, isFalse);

    await tester.tap(find.byType(AppToggle).last);
    await tester.pumpAndSettle();
    expect(StorageService.instance.hapticsOn, isTrue);
  });

  testWidgets('ghost source saves and FRIEND explains the missing import',
      (WidgetTester tester) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('FRIEND'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('No friend ghost yet'), findsOneWidget);
    expect(find.text('IMPORT'), findsOneWidget);
    expect(StorageService.instance.ghostSource, GhostSource.off);

    await tester.tap(find.text('OFF'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.ghostSource, GhostSource.off);

    await tester.tap(find.text('MY BEST'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.ghostSource, GhostSource.mine);
  });

  testWidgets('FRIEND is enabled once a friend ghost exists',
      (WidgetTester tester) async {
    StorageService.instance.importFriendGhost(_tower(4));
    await _pumpSettings(tester);

    await tester.tap(find.text('FRIEND'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.ghostSource, GhostSource.friend);
    expect(find.text('No friend ghost yet'), findsNothing);
  });

  testWidgets('about shows the version dialog', (WidgetTester tester) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Drift Stack'), findsOneWidget);
    expect(find.text('Version 1.0.0 · Made with Flutter'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.0 · Made with Flutter'), findsNothing);
  });

  testWidgets('reset asks first, then clears progress and stays', (WidgetTester tester) async {
    StorageService.instance.commitRun(
      mode: GameMode.classic,
      score: 12,
      ghost: _tower(12),
    );
    await _pumpSettings(tester);
    expect(StorageService.instance.coins, 12);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    expect(find.text('Reset progress?'), findsOneWidget);
    expect(
      find.text('Coins, best scores, skins, streak and ghosts will be deleted. '
          'Settings stay.'),
      findsOneWidget,
    );

    await tester.tap(find.text('RESET'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.coins, 0);
    expect(StorageService.instance.bestClassic, 0);
    expect(find.text('Progress reset'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
