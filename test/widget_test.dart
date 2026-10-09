// Smoke test: verifies AppShell mounts without crashing.
// Full feature tests live in test/adaptation_parser_test.dart and future
// integration tests. Counter-template boilerplate removed — SnapFood has no
// counter widget.

import 'package:flutter_test/flutter_test.dart';

import 'package:snapfood/app/app_shell.dart';

void main() {
  testWidgets('AppShell mounts without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const AppShell());
    // If we reach here without an exception, the widget tree assembled cleanly.
    expect(tester.takeException(), isNull);
  });
}
