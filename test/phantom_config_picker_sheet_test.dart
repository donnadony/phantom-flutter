import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/ui/config/phantom_config_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const options = ['dev', 'dev-waf', 'mock', 'qa', 'staging', 'local'];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PhantomConfig.instance.register(
      label: 'Picker sheet API',
      key: 'picker_sheet_api',
      defaultValue: 'dev',
      type: PhantomConfigType.picker,
      options: options,
      group: 'Network',
    );
  });

  testWidgets('a picker taller than the room it gets scrolls instead of '
      'overflowing', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 420)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PhantomConfigPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('dev'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('local'),
      40,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('local'));
    await tester.pumpAndSettle();

    expect(
      await PhantomConfig.instance.effectiveValue('picker_sheet_api'),
      'local',
    );
  });
}
