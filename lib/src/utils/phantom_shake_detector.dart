import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// A single accelerometer reading, gravity already excluded.
///
/// Exists so the detector can be driven from a test without the plugin.
class PhantomAcceleration {
  final double x;
  final double y;
  final double z;

  const PhantomAcceleration(this.x, this.y, this.z);

  /// Magnitude of the reading, in m/s².
  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// Fires when the device is shaken.
///
/// Used to reach Phantom once its floating button has been hidden. Listening
/// only starts while that is the case, so there is no sensor stream running
/// during ordinary use.
class PhantomShakeDetector {
  /// How hard the device has to move, in m/s², before it counts as a shake.
  ///
  /// Gravity is already excluded from the readings, so ordinary handling sits
  /// well under this — walking peaks around 3, a deliberate tilt lower still.
  static const defaultThreshold = 15.0;

  /// A shake spans many samples above the threshold. Without this the callback
  /// would fire dozens of times for one gesture.
  static const defaultCooldown = Duration(milliseconds: 800);

  final Stream<PhantomAcceleration> Function() _source;
  final double threshold;
  final Duration cooldown;

  StreamSubscription<PhantomAcceleration>? _subscription;
  void Function()? _onShake;
  DateTime? _lastShake;

  PhantomShakeDetector({
    Stream<PhantomAcceleration> Function()? source,
    this.threshold = defaultThreshold,
    this.cooldown = defaultCooldown,
  }) : _source = source ?? _platformSource;

  bool get isRunning => _subscription != null;

  /// Begins listening, calling [onShake] each time the device is shaken.
  ///
  /// Calling this while already running is a no-op rather than a second
  /// subscription, so one gesture cannot be reported twice.
  void start(void Function() onShake) {
    if (_subscription != null) return;
    _onShake = onShake;
    try {
      _subscription = _source().listen(
        _handle,
        // Desktop and web have no accelerometer, and a phone can drop the
        // sensor at runtime. Neither should take the host app down: the button
        // is only hidden for the session, so restarting still brings it back.
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      _subscription = null;
    }
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    _onShake = null;
    await subscription?.cancel();
  }

  Future<void> dispose() => stop();

  void _handle(PhantomAcceleration event) {
    if (event.magnitude < threshold) return;

    final now = DateTime.now();
    final last = _lastShake;
    if (last != null && now.difference(last) < cooldown) return;

    _lastShake = now;
    _onShake?.call();
  }

  static Stream<PhantomAcceleration> _platformSource() {
    return userAccelerometerEventStream().map(
      (e) => PhantomAcceleration(e.x, e.y, e.z),
    );
  }
}
