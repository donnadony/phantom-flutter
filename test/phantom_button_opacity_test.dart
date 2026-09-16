import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/utils/phantom_shake_detector.dart';

void main() {
  late StreamController<PhantomAcceleration> shakes;

  setUp(() => shakes = StreamController<PhantomAcceleration>.broadcast());
  tearDown(() => shakes.close());

  Widget harness({double? buttonOpacity}) => PhantomOverlay(
    shakeDetector: PhantomShakeDetector(source: () => shakes.stream),
    buttonOpacity: buttonOpacity ?? 1,
    child: const MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Opacity fade(WidgetTester tester) => tester.widget<Opacity>(
    find.ancestor(
      of: find.byIcon(Icons.bug_report_rounded),
      matching: find.byType(Opacity),
    ),
  );

  testWidgets('the floating button fades to the opacity the app asks for', (
    tester,
  ) async {
    await tester.pumpWidget(harness(buttonOpacity: 0.4));

    expect(fade(tester).opacity, 0.4);
  });

  testWidgets('by default the button is fully opaque', (tester) async {
    await tester.pumpWidget(harness());

    expect(fade(tester).opacity, 1);
  });

  testWidgets('a faded button still opens the panel', (tester) async {
    await tester.pumpWidget(harness(buttonOpacity: 0.2));

    await tester.tap(find.byIcon(Icons.bug_report_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Hide floating button'), findsOneWidget);
  });
}
