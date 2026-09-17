import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/core/phantom_button_placement.dart';
import 'package:phantom_flutter/src/utils/phantom_shake_detector.dart';

class _RecordingStore implements PhantomButtonPlacementStore {
  _RecordingStore([this.stored]);

  final PhantomButtonPlacement? stored;
  final written = <PhantomButtonPlacement>[];
  Completer<void>? gate;

  @override
  Future<PhantomButtonPlacement?> read() async {
    if (gate != null) await gate!.future;
    return stored;
  }

  @override
  Future<void> write(PhantomButtonPlacement placement) async =>
      written.add(placement);
}

class _BrokenStore implements PhantomButtonPlacementStore {
  @override
  Future<PhantomButtonPlacement?> read() async => throw StateError('no disk');

  @override
  Future<void> write(PhantomButtonPlacement placement) async =>
      throw StateError('no disk');
}

void main() {
  late StreamController<PhantomAcceleration> shakes;

  setUp(() => shakes = StreamController<PhantomAcceleration>.broadcast());
  tearDown(() => shakes.close());

  Widget harness(PhantomButtonPlacementStore store) => PhantomOverlay(
    shakeDetector: PhantomShakeDetector(source: () => shakes.stream),
    placementStore: store,
    child: const MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Finder button() => find.byKey(phantomFloatingButtonKey);
  Finder handle() => find.byKey(phantomEdgeHandleKey);

  Future<void> dragBy(WidgetTester tester, Finder finder, Offset delta) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(delta);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing stored the button keeps its default place', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_RecordingStore()));
    await tester.pumpAndSettle();

    expect(tester.getRect(button()).left, 16);
    expect(tester.getRect(button()).top, 100);
  });

  testWidgets('a stored place is where the button comes back', (tester) async {
    final store = _RecordingStore((
      dx: 300,
      dy: 420,
      tucked: false,
      tuckedLeft: false,
    ));

    await tester.pumpWidget(harness(store));
    await tester.pumpAndSettle();

    expect(tester.getRect(button()).left, 300);
    expect(tester.getRect(button()).top, 420);
  });

  testWidgets('a button stored tucked comes back as the handle', (
    tester,
  ) async {
    final store = _RecordingStore((
      dx: 16,
      dy: 240,
      tucked: true,
      tuckedLeft: false,
    ));

    await tester.pumpWidget(harness(store));
    await tester.pumpAndSettle();

    expect(button(), findsNothing);
    expect(handle(), findsOneWidget);
    expect(tester.getRect(handle()).right, 800);
    expect(tester.getRect(handle()).top, 240);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('a drag that snaps is written down', (tester) async {
    final store = _RecordingStore();
    await tester.pumpWidget(harness(store));
    await tester.pumpAndSettle();

    await dragBy(tester, button(), const Offset(120, 60));

    expect(store.written.last.tucked, isFalse);
    expect(store.written.last.dx, 16);
    expect(store.written.last.dy, 160);
  });

  testWidgets('tucking is written down, with the edge it went to', (
    tester,
  ) async {
    final store = _RecordingStore();
    await tester.pumpWidget(harness(store));
    await tester.pumpAndSettle();

    await dragBy(tester, button(), const Offset(-200, 0));

    expect(store.written.last.tucked, isTrue);
    expect(store.written.last.tuckedLeft, isTrue);
  });

  testWidgets('coming back out of the handle is written down too', (
    tester,
  ) async {
    final store = _RecordingStore();
    await tester.pumpWidget(harness(store));
    await tester.pumpAndSettle();
    await dragBy(tester, button(), const Offset(-200, 0));

    await tester.tap(handle());
    await tester.pumpAndSettle();

    expect(store.written.last.tucked, isFalse);
  });

  testWidgets('a store that cannot be read leaves the button usable', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_BrokenStore()));
    await tester.pumpAndSettle();

    expect(button(), findsOneWidget);
    expect(tester.getRect(button()).left, 16);

    await dragBy(tester, button(), const Offset(-200, 0));
    expect(handle(), findsOneWidget);
  });

  testWidgets('the button is there before the store answers', (tester) async {
    final store = _RecordingStore((
      dx: 300,
      dy: 420,
      tucked: false,
      tuckedLeft: false,
    ))..gate = Completer<void>();

    await tester.pumpWidget(harness(store));
    await tester.pump();

    expect(button(), findsOneWidget);
    expect(tester.getRect(button()).left, 16);

    store.gate!.complete();
    await tester.pumpAndSettle();

    expect(tester.getRect(button()).left, 300);
  });
}
