import 'package:flutter_test/flutter_test.dart';
import 'package:ai_balance_tracker/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AIBalanceApp()),
    );
    expect(find.text('AI Balance'), findsOneWidget);
  });
}
