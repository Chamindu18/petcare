import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/main.dart';

void main() {
  testWidgets('PetCare+ app starts at splash route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PetCareApp());

    expect(find.text('Splash'), findsNWidgets(2));
  });
}
