import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_mobile/main.dart';

void main() {
  testWidgets('app shell shows four bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GithubMobileApp()));
    await tester.pumpAndSettle();

    // Home tab is the initial location.
    expect(find.text('Home Page'), findsOneWidget);

    // Switch to the Inbox tab.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox Page'), findsOneWidget);

    // Switch to the Explore tab.
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Page'), findsOneWidget);

    // Switch to the Copilot tab.
    await tester.tap(find.text('Copilot'));
    await tester.pumpAndSettle();
    expect(find.text('Copilot Page'), findsOneWidget);

    // Switching back to Home keeps the tab branch alive (state preserved).
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home Page'), findsOneWidget);
  });
}
