import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salama/main.dart';
import 'package:salama/presentation/providers/core_providers.dart';

void main() {
  testWidgets('Salama app boots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const SalamaApp(),
      ),
    );
    await tester.pump();

    // With no stored token the gate settles on the unauthenticated branch.
    expect(find.byType(SalamaApp), findsOneWidget);
  });
}
