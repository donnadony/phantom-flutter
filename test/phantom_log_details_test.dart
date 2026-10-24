import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/ui/logs/phantom_log_detail_page.dart';
import 'package:phantom_flutter/src/ui/logs/phantom_logs_page.dart';
import 'package:phantom_flutter/src/utils/phantom_exporter.dart';

void main() {
  setUp(() => PhantomLogger.instance.clearAll());

  PhantomLogItem latest() => PhantomLogger.instance.logs.first;

  group('details', () {
    test('a map is stored as indented JSON', () {
      Phantom.logInfo(
        'ui_interaction',
        tag: 'Analytics',
        details: {'ui_label': 'continuar', 'position': 2},
      );

      expect(
        latest().details,
        '{\n  "ui_label": "continuar",\n  "position": 2\n}',
      );
    });

    test('a list is stored as JSON too', () {
      Phantom.logWarning('ids', details: [1, 2]);

      expect(jsonDecode(latest().details ?? ''), [1, 2]);
    });

    test('a value JSON cannot encode is written as its text', () {
      Phantom.logError('at', details: {'when': DateTime.utc(2026)});

      expect(latest().details, contains('"2026-01-01 00:00:00.000Z"'));
    });

    test('a string is kept as given', () {
      Phantom.log(PhantomLogLevel.info, 'raw', details: 'plain text');

      expect(latest().details, 'plain text');
    });

    test('a log without details has none', () {
      Phantom.logInfo('nothing');

      expect(latest().details, isNull);
    });

    test('the export carries them, and leaves them out when absent', () {
      Phantom.logInfo('bare');
      Phantom.logInfo('event', details: {'a': 1});

      final payload =
          jsonDecode(PhantomExporter.encodeLogs(PhantomLogger.instance.logs))
              as Map<String, dynamic>;
      final entries = (payload['entries'] as List).cast<Map<String, dynamic>>();

      expect(entries.first['details'], '{\n  "a": 1\n}');
      expect(entries.last.containsKey('details'), isFalse);
    });
  });

  group('the logs page', () {
    Widget harness() => const MaterialApp(home: PhantomLogsPage());

    testWidgets('a row with details opens them in full', (tester) async {
      Phantom.logInfo(
        'ui_interaction',
        tag: 'Analytics',
        details: {'ui_label': 'continuar'},
      );
      await tester.pumpWidget(harness());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('ui_interaction'));
      await tester.pumpAndSettle();

      expect(find.byType(PhantomLogDetailPage), findsOneWidget);
      expect(find.textContaining('ui_label'), findsWidgets);
      expect(find.textContaining('continuar'), findsWidgets);
    });

    testWidgets('a row without details does not open anything', (tester) async {
      Phantom.logInfo('plain');
      await tester.pumpWidget(harness());

      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text('plain'));
      await tester.pumpAndSettle();

      expect(find.byType(PhantomLogDetailPage), findsNothing);
    });

    testWidgets('search matches what is in the details', (tester) async {
      Phantom.logInfo('event', details: {'ui_label': 'continuar'});
      Phantom.logInfo('other');
      await tester.pumpWidget(harness());

      await tester.enterText(find.byType(TextField), 'continuar');
      await tester.pump();

      expect(find.text('event'), findsOneWidget);
      expect(find.text('other'), findsNothing);
    });
  });

  testWidgets('the detail page copies the details', (tester) async {
    Phantom.logInfo('event', details: {'a': 1});
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: PhantomLogDetailPage(item: latest())),
    );
    await tester.tap(find.text('Copy details'));
    await tester.pump();

    expect(copied, '{\n  "a": 1\n}');
    expect(find.text('Copied'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copy details'), findsOneWidget);
  });
}
