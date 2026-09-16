import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/utils/phantom_shake_detector.dart';

void main() {
  late StreamController<PhantomAcceleration> shakes;

  setUp(() => shakes = StreamController<PhantomAcceleration>.broadcast());
  tearDown(() => shakes.close());

  Widget harness() => PhantomOverlay(
    shakeDetector: PhantomShakeDetector(source: () => shakes.stream),
    child: const MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Finder button() => find.byKey(phantomFloatingButtonKey);
  Finder handle() => find.byKey(phantomEdgeHandleKey);

  double widthOf(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  Future<void> dragBy(WidgetTester tester, Finder finder, Offset delta) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(delta);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a drag past the left edge tucks the button into a handle', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), const Offset(-200, 40));

    expect(button(), findsNothing);
    expect(handle(), findsOneWidget);
    expect(tester.getRect(handle()).left, 0);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('a drag past the right edge tucks it to that edge', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), Offset(widthOf(tester), 0));

    expect(handle(), findsOneWidget);
    expect(tester.getRect(handle()).right, widthOf(tester));
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('tapping the handle brings the button back', (tester) async {
    await tester.pumpWidget(harness());
    await dragBy(tester, button(), const Offset(-200, 0));

    await tester.tap(handle());
    await tester.pumpAndSettle();

    expect(handle(), findsNothing);
    expect(button(), findsOneWidget);
    expect(tester.getRect(button()).left, 16);
  });

  testWidgets('the handle keeps the height the drag left it at', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), const Offset(-200, 120));

    expect(tester.getRect(handle()).top, 220);
  });

  testWidgets('a grab anywhere on the button reaches the tuck', (tester) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), const Offset(-26, 0));

    expect(handle(), findsOneWidget);
  });

  testWidgets('a button left barely over the edge does not tuck', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), const Offset(-20, 0));

    expect(handle(), findsNothing);
    expect(tester.getRect(button()).left, 16);
  });

  testWidgets('a drag that stays on screen snaps without tucking', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await dragBy(tester, button(), const Offset(120, 0));

    expect(handle(), findsNothing);
    expect(tester.getRect(button()).left, 16);
  });

  testWidgets('the tucked handle opens nothing on a drag of its own', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await dragBy(tester, button(), const Offset(-200, 0));

    await dragBy(tester, handle(), const Offset(0, 100));

    expect(find.text('Network'), findsNothing);
    expect(handle(), findsOneWidget);
    expect(tester.getRect(handle()).top, 200);
  });
}
