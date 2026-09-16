import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/core/models/phantom_mock_rule.dart';
import 'package:phantom_flutter/src/theme/phantom_theme.dart';
import 'package:phantom_flutter/src/ui/mock/phantom_mock_edit_page.dart';
import 'package:phantom_flutter/src/ui/mock/phantom_response_edit_page.dart';

void main() {
  testWidgets('the response editor saves the delay that was picked', (
    tester,
  ) async {
    PhantomMockResponse? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<PhantomMockResponse>(
                MaterialPageRoute(
                  builder: (_) => const PhantomResponseEditPage(),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 s'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.delayMs, 1000);
  });

  testWidgets('a new rule answers without a delay until one is picked', (
    tester,
  ) async {
    PhantomMockRule? saved;
    await tester.pumpWidget(
      MaterialApp(home: PhantomMockEditPage(onSave: (rule) => saved = rule)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Users');
    await tester.enterText(find.byType(TextField).at(1), '/v1/users');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.responses.single.delayMs, 0);
  });

  testWidgets('the inline editor carries the delay into the rule it saves', (
    tester,
  ) async {
    PhantomMockRule? saved;
    await tester.pumpWidget(
      MaterialApp(home: PhantomMockEditPage(onSave: (rule) => saved = rule)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Users');
    await tester.enterText(find.byType(TextField).at(1), '/v1/users');
    await tester.pumpAndSettle();
    await tester.tap(find.text('0.5 s'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved?.responses.single.delayMs, 500);
  });

  testWidgets('an existing delay comes back selected in the editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhantomResponseEditPage(
          existingResponse: PhantomMockResponse(
            id: 'a',
            name: 'Slow',
            delayMs: 10000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const theme = PhantomTheme.kodivex;
    expect(
      tester.widget<Text>(find.text('10 s')).style?.color,
      theme.onPrimary,
    );
    expect(
      tester.widget<Text>(find.text('1 s')).style?.color,
      theme.onBackground,
    );
  });
}
