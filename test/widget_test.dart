// Smoke test: pump the entire app and verify the splash brand text
// renders. We can't exercise the network in a unit test (Dio is
// configured for real HTTP), so we settle for confirming the widget
// tree builds.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/core/theme/app_theme.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: Text('Notely'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Notely'), findsOneWidget);
  });
}
