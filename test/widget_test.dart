import 'package:flutter_test/flutter_test.dart';
import 'package:upah/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UpahPetukangApp());
    expect(find.text('UpahPetukang'), findsWidgets);
  });
}
