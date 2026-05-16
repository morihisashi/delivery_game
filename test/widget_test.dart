import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_game/main.dart';

void main() {
  testWidgets('Title screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryGameApp());

    expect(find.text('Delivery Game'), findsOneWidget);
    expect(find.text('かんたん'), findsOneWidget);
    expect(find.text('ふつう'), findsOneWidget);
    expect(find.text('むずかしい'), findsOneWidget);
  });
}
