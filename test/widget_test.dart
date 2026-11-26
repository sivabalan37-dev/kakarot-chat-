import 'package:flutter_test/flutter_test.dart';
import 'package:kakarot_chat/app/kakarot_app.dart';

void main() {
  testWidgets('shows the isolated migration workspace', (tester) async {
    await tester.pumpWidget(const KakarotApp());
    expect(find.text('Flutter migration workspace'), findsOneWidget);
    expect(find.textContaining('Production login: not connected'), findsOneWidget);
  });
}
