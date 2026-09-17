import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/core/phantom_button_placement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SharedPreferencesPlacementStore();
  const placement = (dx: 314.0, dy: 159.0, tucked: true, tuckedLeft: true);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing is stored until something is written', () async {
    expect(await store.read(), isNull);
  });

  test('a placement survives the round trip', () async {
    await store.write(placement);

    expect(await store.read(), placement);
  });

  test('the last write is the one that comes back', () async {
    await store.write(placement);
    await store.write((dx: 1, dy: 2, tucked: false, tuckedLeft: false));

    expect(await store.read(), (
      dx: 1.0,
      dy: 2.0,
      tucked: false,
      tuckedLeft: false,
    ));
  });

  test('a row written by something else is ignored, not crashed on', () async {
    for (final junk in ['', 'not json', '[]', '{"dx":"left"}', '{}']) {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlacementStore.storageKey: junk,
      });

      expect(await store.read(), isNull, reason: junk);
    }
  });
}
