import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';

void main() {
  Widget harness() => const PhantomOverlay(
    child: MaterialApp(home: Scaffold(body: Text('the app'))),
  );

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byKey(phantomFloatingButtonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('the panel does not offer to hide the button', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await openPanel(tester);

    expect(find.text('Phantom'), findsOneWidget);
    expect(find.textContaining('floating button'), findsNothing);
    expect(find.textContaining('Shake'), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('closing the panel leaves the button where it was', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await openPanel(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byKey(phantomFloatingButtonKey), findsOneWidget);
  });
}
