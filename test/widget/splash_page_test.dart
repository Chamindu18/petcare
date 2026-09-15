import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/auth/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage', () {
    testWidgets('shows PetCare+ logo and loading message', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text("Preparing your pet's care..."), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
