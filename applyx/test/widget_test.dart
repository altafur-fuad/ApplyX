import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:applyx/app/app.dart';

void main() {
  testWidgets('App renders splash screen with brand elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ApplyXApp()));

    // Splash should show the brand name and tagline
    expect(find.text('ApplyX'), findsOneWidget);
    expect(find.text('Your AI opportunity assistant'), findsOneWidget);

    // Pump past the splash timer so no pending timers remain
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
  });

  testWidgets('Splash auto-navigates to onboarding after delay',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ApplyXApp()));

    // Advance past splash delay (2200ms)
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    // Should now be on onboarding — first page title
    expect(find.text('Define your goal'), findsOneWidget);
  });

  testWidgets('Onboarding skip navigates to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ApplyXApp()));

    // Skip past splash
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    // Verify on onboarding
    expect(find.text('Define your goal'), findsOneWidget);

    // Tap "Skip" to go to login
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Should be on login
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
