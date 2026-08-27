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

  group('window insets', () {
    testWidgets('an open keyboard lifts the sheet instead of crushing it', (
      tester,
    ) async {
      // The panel is bottom-anchored inside a nested MaterialApp, which builds
      // its MediaQuery from the FlutterView. Left alone, the keyboard inset
      // applied inside a box that never moved collapsed the panel to nothing.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(ClipRRect).first);
      expect(panel.bottom, closeTo(800 - 336, 0.5),
          reason: 'the sheet should sit on top of the keyboard');

      final body = tester.getRect(find.byType(PhantomViewBody));
      expect(body.height, greaterThan(0),
          reason: 'the panel contents must survive an open keyboard');
    });

    testWidgets('the status bar does not pad the panel from the inside', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 47);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // The sheet's top edge is nowhere near the status bar, so the AppBar
      // should be its plain height rather than 47pt taller.
      expect(tester.getSize(find.byType(AppBar)).height, closeTo(56, 0.5));
    });
  });

  group('size bounds', () {
    testWidgets('drag-to-close still works below the default minSize', (
      tester,
    ) async {
      // The clamp floor used to be a hardcoded 0.1, so any minSize under it
      // put the close threshold somewhere the drag could never reach.
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PhantomSheet(
            theme: _theme,
            minSize: 0.05,
            onClose: () => closed++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PhantomSheet), const Offset(0, 5000));
      await tester.pumpAndSettle();

      expect(closed, 1);
    });

    testWidgets('an initialSize below minSize is rejected', (tester) async {
      // Otherwise the sheet opens already past its close threshold and a
      // two-pixel drag dismisses it.
      expect(
        () => PhantomSheet(theme: _theme, initialSize: 0.2, onClose: () {}),
        throwsAssertionError,
      );
    });
  });
}
