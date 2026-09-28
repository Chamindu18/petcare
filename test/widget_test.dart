import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage builds successfully', (tester) async {
    final auth = MockFirebaseAuth(signedIn: false);

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(auth: auth),
        routes: {
          '/onboarding': (context) => const Scaffold(body: Text('Onboarding')),
          '/home': (context) => const Scaffold(body: Text('Home')),
        },
      ),
    );

    expect(find.byType(SplashPage), findsOneWidget);
  });
}
