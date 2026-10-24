import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:phantom_flutter/src/ui/logs/phantom_log_detail_page.dart';
import 'package:phantom_flutter/src/ui/logs/phantom_logs_page.dart';
import 'package:phantom_flutter/src/ui/network/phantom_json_tree_view.dart';
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

      expect(entries.first['details'], {'a': 1});
      expect(entries.last.containsKey('details'), isFalse);
    });

    test('the export keeps a details string that is not JSON as text', () {
      Phantom.logInfo('event', details: 'plain text');

      final payload =
          jsonDecode(PhantomExporter.encodeLogs(PhantomLogger.instance.logs))
              as Map<String, dynamic>;

      expect((payload['entries'] as List).single['details'], 'plain text');
    });

    test('an object with toJson is written through it', () {
      Phantom.logInfo('event', details: {'entity': const _Entity('x')});
      expect(jsonDecode(latest().details ?? ''), {
        'entity': {'id': 'x'},
      });

      Phantom.logInfo('event', details: const _Entity('y'));
      expect(jsonDecode(latest().details ?? ''), {'id': 'y'});
    });

    test('a payload that cannot be encoded never throws into the caller', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;

      expect(() => Phantom.logInfo('cycle', details: cyclic), returnsNormally);
      expect(latest().details, startsWith('<details could not be encoded'));

      expect(
        () => Phantom.logInfo('bad', details: _Unprintable()),
        returnsNormally,
      );
      expect(latest().details, startsWith('<details could not be encoded'));
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

  group('the detail page', () {
    Widget page() => MaterialApp(home: PhantomLogDetailPage(item: latest()));

    testWidgets('a string that is valid JSON is drawn as a tree', (
      tester,
    ) async {
      Phantom.logInfo('event', details: '{"ui_label": "continuar"}');
      await tester.pumpWidget(page());

      expect(find.text('ui_label'), findsOneWidget);
      expect(find.text('"continuar"'), findsOneWidget);
    });

    testWidgets('a long value is shown whole', (tester) async {
      final long = List.filled(400, 'x').join();
      Phantom.logInfo('event', details: {'url': long});
      await tester.pumpWidget(page());

      final leaf = tester.widget<Text>(find.text('"$long"'));
      expect(leaf.maxLines, isNull);
      expect(leaf.overflow, isNull);
    });

    testWidgets('a long message does not push the details off the page', (
      tester,
    ) async {
      Phantom.logInfo(List.filled(200, 'line').join('\n'), details: {'a': 1});
      await tester.pumpWidget(page());

      expect(tester.takeException(), isNull);
      expect(find.text('Copy details'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PhantomJsonTreeView)).height,
        greaterThan(100),
      );
    });

    testWidgets('the panel theme reaches the page the row opens', (
      tester,
    ) async {
      Phantom.logInfo('event', details: {'a': 1});
      await tester.pumpWidget(
        const MaterialApp(
          home: PhantomThemeProvider(theme: _custom, child: PhantomLogsPage()),
        ),
      );

      await tester.tap(find.text('event'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(PhantomLogDetailPage),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, _custom.background);
    });
  });

  testWidgets('the detail page copies the details', (tester) async {
    Phantom.logInfo('event', details: {'a': 1});
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
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

class _Entity {
  const _Entity(this.id);

  final String id;

  Map<String, Object?> toJson() => {'id': id};
}

class _Unprintable {
  @override
  String toString() => throw StateError('no text');
}

const _custom = PhantomTheme(
  background: Color(0xFF123456),
  surface: Color(0xFF1C2540),
  surfaceVariant: Color(0xFF283050),
  onBackground: Color(0xFFE4ECFF),
  onBackgroundVariant: Color(0xFFA8B4D0),
  onPrimary: Color(0xFF3C0091),
  primary: Color(0xFFD0BCFF),
  primaryContainer: Color(0xFFA078FF),
  info: Color(0xFF5DE6FF),
  warning: Color(0xFFFFB869),
  error: Color(0xFFFFB4AB),
  success: Color(0xFF5DE6FF),
  outline: Color(0xFF958EA0),
  outlineVariant: Color(0xFF5A5570),
  tint: Color(0xFFA078FF),
  inputBackground: Color(0xFF0F1829),
  httpGet: Color(0xFF5DE6FF),
  httpPost: Color(0xFFD0BCFF),
  httpPut: Color(0xFFFFB869),
  httpDelete: Color(0xFFFFB4AB),
  jsonString: Color(0xFF5DE6FF),
  jsonNumber: Color(0xFFD0BCFF),
  jsonBoolean: Color(0xFFFFB869),
  jsonNull: Color(0xFF958EA0),
);
