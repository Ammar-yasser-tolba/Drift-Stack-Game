import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift_stack/widgets/app_dialog.dart';

void main() {
  testWidgets('two-button dialog lays out without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () => showAppDialog<bool>(
                context: context,
                title: 'Quit this run?',
                body: "Your score of 6 won't be saved.",
                buttons: const <DialogButton<bool>>[
                  DialogButton<bool>(label: 'KEEP PLAYING', value: false),
                  DialogButton<bool>(
                    label: 'QUIT',
                    value: true,
                    style: DialogButtonStyle.muted,
                  ),
                ],
                backValue: false,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Quit this run?'), findsOneWidget);
    expect(find.text('KEEP PLAYING'), findsOneWidget);
    expect(find.text('QUIT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
