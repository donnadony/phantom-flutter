import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/utils/phantom_shake_detector.dart';

void main() {
  late StreamController<PhantomAcceleration> source;
  late PhantomShakeDetector detector;
  late int shakes;

  setUp(() {
    source = StreamController<PhantomAcceleration>.broadcast();
    detector = PhantomShakeDetector(source: () => source.stream);
    shakes = 0;
  });

  tearDown(() async {
    await detector.dispose();
    await source.close();
  });

  Future<void> push(double x, double y, double z) async {
    source.add(PhantomAcceleration(x, y, z));
    await Future<void>.delayed(Duration.zero);
  }

  test('ordinary handling does not register as a shake', () async {
    detector.start(() => shakes++);

    // Walking with a phone in hand, or a deliberate tilt.
    for (var i = 0; i < 20; i++) {
      await push(1.5, -2.0, 0.8);
    }

    expect(shakes, 0);
  });

  test('a sharp jolt registers once', () async {
    detector.start(() => shakes++);

    await push(20, 0, 0);

    expect(shakes, 1);
  });

  test('a sustained shake fires once, not once per sample', () async {
    // A real shake spans many samples above the threshold. Without a cooldown
    // the panel would be told to open dozens of times per gesture.
    detector.start(() => shakes++);

    for (var i = 0; i < 30; i++) {
      await push(25, -25, 25);
    }

    expect(shakes, 1);
  });

  test('a second shake after the cooldown fires again', () async {
    detector = PhantomShakeDetector(
      source: () => source.stream,
      cooldown: const Duration(milliseconds: 20),
    );
    detector.start(() => shakes++);

    await push(20, 0, 0);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await push(20, 0, 0);

    expect(shakes, 2);
  });

  test('stop() detaches the callback', () async {
    detector.start(() => shakes++);
    await detector.stop();

    await push(30, 30, 30);

    expect(shakes, 0);
  });

  test('start() is idempotent, so one gesture cannot fire twice', () async {
    detector.start(() => shakes++);
    detector.start(() => shakes++);

    await push(20, 0, 0);

    expect(shakes, 1);
  });

  test('a source that is unavailable is not fatal', () async {
    // Desktop and web have no accelerometer: the plugin may throw on
    // subscription. Hiding the button must not take the app down with it.
    final broken = PhantomShakeDetector(
      source: () => throw StateError('no accelerometer on this platform'),
    );

    expect(() => broken.start(() => shakes++), returnsNormally);
    expect(shakes, 0);
  });

  test('an error mid-stream is swallowed rather than thrown', () async {
    detector.start(() => shakes++);

    source.addError(StateError('sensor went away'));
    await Future<void>.delayed(Duration.zero);

    expect(shakes, 0);
  });
}
