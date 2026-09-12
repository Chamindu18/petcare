import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/main.dart';

void main() {
  testWidgets('PetCare+ app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PetCareApp());

    expect(find.text('PetCare+'), findsOneWidget);
    expect(find.text('Firebase initialized successfully'), findsOneWidget);
  });
}
