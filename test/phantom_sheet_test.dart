import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';

const _theme = PhantomTheme.kodivex;

Widget _harness({double initialSize = 0.5, VoidCallback? onClose}) =>
    MaterialApp(
      home: PhantomSheet(
        theme: _theme,
        initialSize: initialSize,
        onClose: onClose ?? () {},
      ),
    );

void main() {
  testWidgets('opens at half the screen', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byType(ClipRRect).first);
    final screen = tester.getSize(find.byType(MaterialApp).first);

    expect(panel.height / screen.height, closeTo(0.5, 0.01));
    // It leaves the app visible behind it, which is the reason for a sheet.
    expect(panel.top, greaterThan(0));
  });

  testWidgets('the panel is anchored to the bottom', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byType(ClipRRect).first);
    final screen = tester.getSize(find.byType(MaterialApp).first);

    expect(panel.bottom, closeTo(screen.height, 0.5));
  });

  testWidgets('dragging the handle up snaps it to full height', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Grab the handle, not the body: the body scrolls.
    await tester.drag(find.byType(PhantomSheet), const Offset(0, -300));
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byType(ClipRRect).first);
    final screen = tester.getSize(find.byType(MaterialApp).first);

    expect(panel.height / screen.height, closeTo(1.0, 0.01));
  });

  testWidgets('a small drag settles back rather than resting off-snap', (
    tester,
  ) async {
    // Without a snap the sheet keeps whatever height a finger left it at,
    // which reads as the panel having drifted.
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PhantomSheet), const Offset(0, -40));
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byType(ClipRRect).first);
    final screen = tester.getSize(find.byType(MaterialApp).first);

    expect(panel.height / screen.height, closeTo(0.5, 0.01));
  });

  testWidgets('dragging it far down closes instead of shrinking', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(_harness(onClose: () => closed = true));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PhantomSheet), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('tapping the scrim closes it', (tester) async {
    var closed = false;
    await tester.pumpWidget(_harness(onClose: () => closed = true));
    await tester.pumpAndSettle();

    // Well above the sheet, so the tap lands on the scrim.
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('the panel carries its own Navigator', (tester) async {
    // Without one the panel's pushes land on the app's root navigator and
    // cover the screen the sheet exists to sit beside.
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PhantomSheet),
        matching: find.byType(Navigator),
      ),
      findsWidgets,
    );
  });

  testWidgets('fullScreen stays the default presentation', (tester) async {
    // Existing callers must see no change from this feature landing.
    const overlay = PhantomOverlay(child: SizedBox());

    expect(overlay.presentation, PhantomPresentation.fullScreen);
  });
}
