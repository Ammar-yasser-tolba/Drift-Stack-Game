import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_nav.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/models/ghost.dart';
import 'package:drift_stack/screens/skins/skins_screen.dart';
import 'package:drift_stack/services/storage_service.dart';
import 'package:drift_stack/widgets/app_buttons.dart';

Ghost _tower(int score) => Ghost(
      score: score,
      seed: 3,
      floors: List<GhostFloor>.generate(
        score + 1,
        (int i) => const GhostFloor(0.2, 0.6),
      ),
    );

Future<void> _pumpSkins(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      home: const SkinsScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => StorageService.instance.resetProgress());

  testWidgets('buy flow asks first, then unlocks and equips the skin',
      (WidgetTester tester) async {
    await _pumpSkins(tester);

    expect(find.text('SKINS'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsNWidgets(2));
    // Preview name + card name.
    expect(find.text('Neon'), findsNWidgets(2));

    await tester.tap(find.text('Desert'));
    await tester.pumpAndSettle();
    expect(find.text('BUY · 100'), findsOneWidget);

    await tester.tap(find.text('BUY · 100'));
    await tester.pumpAndSettle();
    expect(find.text('Not enough coins'), findsOneWidget);
    expect(
      find.text('You need 100 more coins. Play a few runs to earn them.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.ownsSkin('desert'), isFalse);

    StorageService.instance.commitRun(
      mode: GameMode.classic,
      score: 100,
      ghost: _tower(100),
    );
    await tester.pumpAndSettle();
    expect(StorageService.instance.coins, 100);

    await tester.tap(find.text('BUY · 100'));
    await tester.pumpAndSettle();
    expect(find.text('Buy Desert?'), findsOneWidget);
    expect(find.text('This will cost 100 coins.'), findsOneWidget);

    await tester.tap(find.text('BUY'));
    await tester.pumpAndSettle();

    expect(StorageService.instance.ownsSkin('desert'), isTrue);
    expect(StorageService.instance.equippedSkinId, 'desert');
    expect(StorageService.instance.coins, 0);
    expect(find.text('Unlocked Desert!'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsWidgets);
  });

  testWidgets('tapping a locked card previews it without equipping',
      (WidgetTester tester) async {
    await _pumpSkins(tester);

    await tester.tap(find.text('Pharaoh'));
    await tester.pumpAndSettle();
    expect(find.text('BUY · 250'), findsOneWidget);
    expect(StorageService.instance.equippedSkinId, 'neon');

    await tester.tap(find.text('Neon').last);
    await tester.pumpAndSettle();
    expect(find.text('EQUIPPED'), findsNWidgets(2));
  });

  testWidgets('equipping a different owned skin shows the snackbar',
      (WidgetTester tester) async {
    await _pumpSkins(tester);
    StorageService.instance.commitRun(
      mode: GameMode.classic,
      score: 100,
      ghost: _tower(100),
    );
    await tester.pumpAndSettle();

    // Buy Desert through the dialog.
    await tester.tap(find.text('Desert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BUY · 100'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BUY'));
    await tester.pumpAndSettle();

    expect(StorageService.instance.equippedSkinId, 'desert');

    // Let the "Unlocked Desert!" snackbar finish so it no longer covers the
    // action button.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Neon').last);
    await tester.pumpAndSettle();
    expect(find.text('EQUIP'), findsOneWidget);

    await tester.tap(find.text('EQUIP'));
    await tester.pumpAndSettle();
    expect(StorageService.instance.equippedSkinId, 'neon');
    expect(find.text('Neon equipped'), findsOneWidget);
  });

  testWidgets('the equipped action is disabled', (WidgetTester tester) async {
    await _pumpSkins(tester);
    final PrimaryButton button =
        tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'EQUIPPED'));
    expect(button.enabled, isTrue);
    expect(button.onTap, isNull);
  });
}
