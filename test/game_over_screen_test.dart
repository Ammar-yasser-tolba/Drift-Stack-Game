import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_nav.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/models/run_result.dart';
import 'package:drift_stack/screens/game_over/game_over_screen.dart';

Ghost _tower(int score) => Ghost(
      score: score,
      seed: 12,
      floors: List<GhostFloor>.generate(
        score + 1,
        (int i) => const GhostFloor(0.2, 0.6),
      ),
    );

RunResult _result(int score) => RunResult(
      mode: GameMode.classic,
      score: score,
      perfects: 2,
      maxCombo: 3,
      ghost: _tower(score),
    );

Future<void> _pumpGameOver(WidgetTester tester, RunResult result) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      home: GameOverScreen(result: result),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('new best shows the badge, stats and actions', (WidgetTester tester) async {
    await _pumpGameOver(tester, _result(7));

    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('CLASSIC'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('NEW BEST!'), findsOneWidget);
    expect(find.text('BEST 7'), findsOneWidget);
    expect(find.text('PERFECTS'), findsOneWidget);
    expect(find.text('MAX COMBO'), findsOneWidget);
    expect(find.text('COINS'), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('SHARE'), findsOneWidget);
    expect(find.text('COPY GHOST'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a lower score keeps the stored best', (WidgetTester tester) async {
    await _pumpGameOver(tester, _result(2));

    expect(find.text('NEW BEST!'), findsNothing);
    expect(find.text('BEST 7'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('copy ghost writes the run code to the clipboard', (WidgetTester tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await _pumpGameOver(tester, _result(4));
    await tester.tap(find.text('COPY GHOST'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(copied, _tower(4).encode());
    expect(find.text('Ghost code copied.'), findsOneWidget);
  });

  testWidgets('SHARE opens the native sheet with the score text and a PNG',
      (WidgetTester tester) async {
    final List<MethodCall> shareCalls = <MethodCall>[];
    const MethodChannel shareChannel =
        MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (MethodCall call) async {
        shareCalls.add(call);
        return 'dev.fluttercommunity.plus/share/success';
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => Directory.systemTemp.path,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
    });

    await _pumpGameOver(tester, _result(5));
    await tester.tap(find.text('SHARE'));
    for (int i = 0; i < 50 && shareCalls.isEmpty; i++) {
      // The card render runs on the engine, so let real async work happen,
      // then pump to flush the continuations queued on the fake clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(shareCalls, hasLength(1));
    final MethodCall call = shareCalls.single;
    expect(call.method, 'shareFiles');
    final Map<Object?, Object?> args =
        call.arguments as Map<Object?, Object?>;
    expect(args['text'], 'I reached 5 in Drift Stack! Beat me.');
    final List<Object?> paths = args['paths']! as List<Object?>;
    expect(paths, hasLength(1));
    expect(paths.single as String, endsWith('drift_stack_score.png'));
    expect((args['mimeTypes']! as List<Object?>).single, 'image/png');

    final File file = File(paths.single! as String);
    final Uint8List bytes = file.readAsBytesSync();
    expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    expect(bytes.length, greaterThan(1000));

    await tester.pumpAndSettle();
    expect(find.text('Share failed'), findsNothing);
  });
}
