import 'package:flutter_test/flutter_test.dart';
import 'package:ai_balance_tracker/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App shows splash then dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AIBalanceApp()),
    );

    // Splash screen should show first
    expect(find.text('AI Balance'), findsOneWidget);
    expect(find.text('Tracker'), findsOneWidget);

    // Advance past the 2.5s splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Dashboard should now be visible (no PIN set by default, no providers)
    expect(find.text('No providers configured'), findsOneWidget);
  });
}
