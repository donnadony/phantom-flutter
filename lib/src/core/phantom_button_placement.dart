import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef PhantomButtonPlacement = ({
  double dx,
  double dy,
  bool tucked,
  bool tuckedLeft,
});

abstract interface class PhantomButtonPlacementStore {
  Future<PhantomButtonPlacement?> read();

  Future<void> write(PhantomButtonPlacement placement);
}

final class SharedPreferencesPlacementStore
    implements PhantomButtonPlacementStore {
  const SharedPreferencesPlacementStore();

  static const storageKey = 'phantom_button_placement';

  @override
  Future<PhantomButtonPlacement?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;

    // Anything but a row this class wrote is a miss, not a crash: a half
    // written string, a value left by an older shape of this feature, or a key
    // another tool happened to use. The button falls back to its default place.
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }

    if (json is! Map<String, dynamic>) return null;

    final dx = json['dx'];
    final dy = json['dy'];
    if (dx is! num || dy is! num) return null;

    return (
      dx: dx.toDouble(),
      dy: dy.toDouble(),
      tucked: json['tucked'] == true,
      tuckedLeft: json['tuckedLeft'] == true,
    );
  }

  @override
  Future<void> write(PhantomButtonPlacement placement) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'dx': placement.dx,
        'dy': placement.dy,
        'tucked': placement.tucked,
        'tuckedLeft': placement.tuckedLeft,
      }),
    );
  }
}
