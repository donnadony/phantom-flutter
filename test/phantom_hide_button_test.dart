import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/utils/phantom_shake_detector.dart';

const _hide = 'Hide floating button';
const _show = 'Show floating button';

void main() {
  late StreamController<PhantomAcceleration> shakes;

  setUp(() => shakes = StreamController<PhantomAcceleration>.broadcast());
  tearDown(() => shakes.close());

  Widget harness() => PhantomOverlay(
    shakeDetector: PhantomShakeDetector(source: () => shakes.stream),
    child: const MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Finder floatingButton() => find.byIcon(Icons.bug_report_rounded);

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(floatingButton());
    await tester.pumpAndSettle();
  }

  Future<void> closePanel(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  }

  Future<void> shake(WidgetTester tester) async {
    shakes.add(const PhantomAcceleration(30, 0, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('the panel offers to hide the button', (tester) async {
    await tester.pumpWidget(harness());
    await openPanel(tester);

    expect(find.text(_hide), findsOneWidget);
    // The gesture that brings it back is invisible, so the row has to teach it.
    expect(find.textContaining('Shake'), findsOneWidget);
  });

  testWidgets('hiding removes the button but leaves the panel open', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await openPanel(tester);

    await tester.tap(find.text(_hide));
    await tester.pumpAndSettle();

    // The row flipping is the only confirmation the user gets, so the panel
    // must not close out from under it.
    expect(find.text(_show), findsOneWidget);

    await closePanel(tester);
    expect(floatingButton(), findsNothing);
  });

  testWidgets('shaking reopens the panel once the button is hidden', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await openPanel(tester);
    await tester.tap(find.text(_hide));
    await tester.pumpAndSettle();
    await closePanel(tester);

    await shake(tester);

    expect(find.text(_show), findsOneWidget);
  });

  testWidgets('shaking does nothing while the button is still there', (
    tester,
  ) async {
    // No sensor stream should be running during ordinary use, and a shake
    // must not pop the panel open unasked.
    await tester.pumpWidget(harness());

    await shake(tester);

    expect(find.text(_hide), findsNothing);
    expect(floatingButton(), findsOneWidget);
  });

  testWidgets('the button can be restored from the panel', (tester) async {
    await tester.pumpWidget(harness());
    await openPanel(tester);
    await tester.tap(find.text(_hide));
    await tester.pumpAndSettle();
    await closePanel(tester);

    await shake(tester);
    await tester.tap(find.text(_show));
    await tester.pumpAndSettle();
    await closePanel(tester);

    expect(floatingButton(), findsOneWidget);
  });

  testWidgets('a panel with no floating button offers no toggle', (
    tester,
  ) async {
    // Phantom.show(context) pushes the panel without an overlay behind it, so
    // a "hide the button" row there would do nothing.
    await tester.pumpWidget(const MaterialApp(home: PhantomView()));
    await tester.pumpAndSettle();

    expect(find.text(_hide), findsNothing);
    expect(find.text(_show), findsNothing);
  });

  testWidgets('showFloatingButton: false keeps the toggle out of the panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: PhantomOverlay(
              showFloatingButton: false,
              child: ElevatedButton(
                onPressed: () => Phantom.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(_hide), findsNothing);
  });
}
