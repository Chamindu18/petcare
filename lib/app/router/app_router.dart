import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/check_email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/onboarding_slides_page.dart';
import '../../features/auth/presentation/pages/password_reset_success_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/registration_success_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboardingSlides = '/onboarding-slides';

  static const String login = '/login';
  static const String register = '/register';

  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/check-email';
  static const String resetPassword = '/reset-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String registrationSuccess = '/registration-success';

  static const String home = '/home';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),

        onboarding: (_) => const OnboardingPage(),

        onboardingSlides: (_) => const OnboardingSlidesPage(),

        login: (_) => const LoginPage(),

        register: (_) => const RegisterPage(),

        forgotPassword: (_) => const ForgotPasswordPage(),

        checkEmail: (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';

          return CheckEmailPage(email: email);
        },

        resetPassword: (context) {
          final code =
              ModalRoute.of(context)?.settings.arguments as String?;

          return ResetPasswordPage(code: code);
        },

        passwordResetSuccess: (_) => const PasswordResetSuccessPage(),

        registrationSuccess: (_) => const RegistrationSuccessPage(),

        home: (_) => const _PlaceholderPage(title: 'Home'),

        notifications: (_) => const NotificationsPage(),
      };
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}