import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakarot_chat/widgets/kakarot_brand.dart';

void main() {
  testWidgets('renders the Kakarot Chat brand and logo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: KakarotBrand()),
        ),
      ),
    );

    expect(find.text('Kakarot Chat'), findsOneWidget);
    expect(find.byType(KakarotBrand), findsOneWidget);
  });
}
