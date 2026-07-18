// Basic smoke test for the card reader home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:card_reader_1/main.dart';

void main() {
  testWidgets('Home screen renders welcome, card and Tap card button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardReaderApp());
    // Let the intro animation settle.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Platinum'), findsOneWidget);

    // The "Tap card" button sits below the fold in the lazy ListView.
    await tester.scrollUntilVisible(find.text('Tap card'), 300);
    expect(find.text('Tap card'), findsOneWidget);
  });
}
