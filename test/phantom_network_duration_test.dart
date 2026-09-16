import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/core/phantom_network_logger.dart';
import 'package:phantom_flutter/src/theme/phantom_theme.dart';
import 'package:phantom_flutter/src/ui/network/phantom_network_page.dart';

void main() {
  const theme = PhantomTheme.kodivex;
  final logger = PhantomNetworkLogger.instance;

  setUp(logger.clearAll);
  tearDown(logger.clearAll);

  void logCall(String url, int durationMs) {
    logger.logRequest(method: 'GET', url: url);
    logger.logResponse(url: url, statusCode: 200, durationMs: durationMs);
  }

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PhantomNetworkPage()));
    await tester.pumpAndSettle();
  }

  Color colourOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color ??
      const Color(0x00000000);

  testWidgets('a slow call reads in seconds, in the error colour', (
    tester,
  ) async {
    logCall('https://example.com/v1/slow', 1200);

    await pumpList(tester);

    expect(find.text('1200ms'), findsNothing);
    expect(find.text('1.2 s'), findsOneWidget);
    expect(colourOf(tester, '1.2 s'), theme.error);
  });

  testWidgets('a fast call reads in fractions of a second, in success', (
    tester,
  ) async {
    logCall('https://example.com/v1/fast', 300);

    await pumpList(tester);

    expect(find.text('0.30 s'), findsOneWidget);
    expect(colourOf(tester, '0.30 s'), theme.success);
  });

  testWidgets('the slow filter is labelled in seconds too', (tester) async {
    await pumpList(tester);

    expect(find.text('Slow >1 s'), findsOneWidget);
  });
}
