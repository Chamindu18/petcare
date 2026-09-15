import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_slides_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboardingSlides = '/onboarding-slides';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    onboarding: (_) => const OnboardingPage(),
    onboardingSlides: (_) => const OnboardingSlidesPage(),
    login: (_) => const LoginPage(),
    register: (_) => const _PlaceholderPage(title: 'Register'),
    forgotPassword: (_) => const _PlaceholderPage(title: 'Forgot Password'),
    home: (_) => const _PlaceholderPage(title: 'Home'),
  };
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
