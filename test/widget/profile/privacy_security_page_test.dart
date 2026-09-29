import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/profile/presentation/pages/privacy_security_page.dart';

void main() {
  testWidgets('renders Privacy & Security content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const PrivacySecurityPage(),
      ),
    );

    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('QR Health Passport'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  testWidgets('opens forgot password when Reset Password is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const PrivacySecurityPage(),
        routes: {
          AppRouter.forgotPassword: (_) => const Scaffold(
            body: Text('Forgot Password Screen'),
          ),
        },
      ),
    );

    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password Screen'), findsOneWidget);
  });
}