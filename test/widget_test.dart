import 'package:flutter_test/flutter_test.dart';

import 'package:salama/main.dart';

void main() {
  testWidgets('Salama app boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const SalamaApp());
    expect(find.text('Salama Health'), findsWidgets);
  });
}
