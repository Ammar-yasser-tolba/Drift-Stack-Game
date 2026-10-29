import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/core/navigation/app_nav.dart';
import 'package:drift_stack/core/navigation/app_router.dart';
import 'package:drift_stack/models/game_mode.dart';
import 'package:drift_stack/screens/import_ghost/import_ghost_screen.dart';
import 'package:drift_stack/services/storage_service.dart';
import 'package:drift_stack/widgets/app_buttons.dart';

const String _validCode = 'DS1|1|7|0.2,0.6;0.3,0.4';

String get _tooLongCode {
  final String floors = List<String>.filled(501, '0.2,0.5').join(';');
  return 'DS1|500|1|$floors';
}

Future<void> _pumpImport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNav.navigatorKey,
      scaffoldMessengerKey: AppNav.messengerKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
      home: const ImportGhostScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => StorageService.instance.resetProgress());

  testWidgets('IMPORT is disabled while the box is empty',
      (WidgetTester tester) async {
    await _pumpImport(tester);

    expect(find.text('IMPORT GHOST'), findsOneWidget);
    final PrimaryButton button =
        tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'IMPORT'));
    expect(button.onTap, isNull);

    await tester.enterText(find.byType(TextField), 'D');
    await tester.pump();
    final PrimaryButton enabled =
        tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'IMPORT'));
    expect(enabled.onTap, isNotNull);
  });

  testWidgets('damaged codes show an error that clears while typing',
      (WidgetTester tester) async {
    await _pumpImport(tester);

    await tester.enterText(find.byType(TextField), 'DS1|2|1|0.2,0.5');
    await tester.pump();
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    expect(find.text('This code is damaged or incomplete.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'DS1|2|1|0.2,0.5;0.3,0.4');
    await tester.pump();
    expect(find.text('This code is damaged or incomplete.'), findsNothing);

    await tester.enterText(find.byType(TextField), _tooLongCode);
    await tester.pump();
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();
    expect(find.text('This ghost code is too long.'), findsOneWidget);
  });

  testWidgets('a valid import saves the ghost and offers PLAY NOW',
      (WidgetTester tester) async {
    await _pumpImport(tester);

    await tester.enterText(find.byType(TextField), _validCode);
    await tester.pump();
    await tester.tap(find.text('IMPORT'));
    await tester.pumpAndSettle();

    expect(find.text('Ghost imported · score 1'), findsOneWidget);
    expect(find.text('PLAY NOW'), findsOneWidget);
    expect(find.text('Current friend ghost'), findsOneWidget);
    expect(find.text('Score 1'), findsOneWidget);
    expect(StorageService.instance.friendGhost?.score, 1);
    expect(StorageService.instance.ghostSource, GhostSource.friend);

    await tester.tap(find.text('REMOVE'));
    await tester.pumpAndSettle();
    expect(find.text('Current friend ghost'), findsNothing);
    expect(find.text('PLAY NOW'), findsNothing);
    expect(StorageService.instance.friendGhost, isNull);
    expect(StorageService.instance.ghostSource, GhostSource.off);
  });

  testWidgets('PASTE fills the box and reports an empty clipboard',
      (WidgetTester tester) async {
    String? clipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await _pumpImport(tester);

    await tester.tap(find.text('PASTE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Clipboard is empty'), findsOneWidget);

    clipboardText = _validCode;
    await tester.tap(find.text('PASTE'));
    await tester.pumpAndSettle();
    final TextField box = tester.widget<TextField>(find.byType(TextField));
    expect(box.controller?.text, _validCode);
  });
}
