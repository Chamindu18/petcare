import 'package:flutter/material.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const _PlaceholderPage(title: 'Splash'),
    onboarding: (_) => const _PlaceholderPage(title: 'Onboarding'),
    login: (_) => const _PlaceholderPage(title: 'Login'),
    register: (_) => const _PlaceholderPage(title: 'Register'),
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
