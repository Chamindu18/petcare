import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/app/router/app_router.dart';
import 'package:petcare/features/profile/presentation/pages/privacy_security_page.dart';

void main() {
  group('PrivacySecurityPage', () {
    testWidgets('renders all privacy and security sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacySecurityPage()));

      // Initial visible content.
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Your Account Protection'), findsOneWidget);
      expect(find.text('Account Security'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);

      // Scroll to the information section.
      await tester.scrollUntilVisible(
        find.text('Your Information'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Your Information'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Pet Care Information'), findsOneWidget);
      expect(find.text('Data Access'), findsOneWidget);

      // Scroll to the account protection tips.
      await tester.scrollUntilVisible(
        find.text('Protect Your Account'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Protect Your Account'), findsOneWidget);
      expect(find.text('Keep your password private'), findsOneWidget);
      expect(find.text('Use trusted devices'), findsOneWidget);
      expect(find.text('Sign out on shared devices'), findsOneWidget);

      // Scroll to the support action.
      await tester.scrollUntilVisible(
        find.text('Need Help?'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Need Help?'), findsOneWidget);

      // QR security claims are intentionally excluded until the
      // QR Health Passport feature has a verified implementation.
      expect(find.text('QR Health Passport'), findsNothing);
    });

    testWidgets('opens forgot password when Reset Password is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySecurityPage(),
          routes: {
            AppRouter.forgotPassword: (_) => const Scaffold(
              body: Center(child: Text('Forgot Password Screen')),
            ),
          },
        ),
      );

      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password Screen'), findsOneWidget);
    });

    testWidgets('opens Help & Support when Need Help is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacySecurityPage(),
          routes: {
            AppRouter.helpSupport: (_) => const Scaffold(
              body: Center(child: Text('Help & Support Screen')),
            ),
          },
        ),
      );

      final needHelpFinder = find.text('Need Help?');

      // First bring the lazy-built section into the widget tree.
      await tester.scrollUntilVisible(
        needHelpFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Ensure the complete widget is inside the visible viewport.
      await tester.ensureVisible(needHelpFinder);
      await tester.pumpAndSettle();

      await tester.tap(needHelpFinder);
      await tester.pumpAndSettle();

      expect(find.text('Help & Support Screen'), findsOneWidget);
    });
  });
}
