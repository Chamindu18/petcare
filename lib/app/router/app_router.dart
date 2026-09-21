import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/onboarding_slides_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/pets/data/repositories/firebase_pet_repository.dart';
import '../../features/pets/domain/usecases/create_pet.dart';
import '../../features/pets/domain/usecases/delete_pet.dart';
import '../../features/pets/domain/usecases/get_pets.dart';
import '../../features/pets/domain/usecases/update_pet.dart';
import '../../features/pets/presentation/pages/my_pets_page.dart';
import '../../features/pets/presentation/providers/pets_controller.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboardingSlides = '/onboarding-slides';

  static const String login = '/login';
  static const String register = '/register';

  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String registrationSuccess = '/registration-success';

  static const String home = '/home';
  static const String myPets = '/my-pets';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    onboarding: (_) => const OnboardingPage(),
    onboardingSlides: (_) => const OnboardingSlidesPage(),

    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),

    forgotPassword: (_) => const ForgotPasswordPage(),

    resetPassword: (context) {
      final code = ModalRoute.of(context)?.settings.arguments as String?;

      return ResetPasswordPage(code: code);
    },

    passwordResetSuccess: (_) =>
        const _PlaceholderPage(title: 'Password Reset Success'),

    registrationSuccess: (_) =>
        const _PlaceholderPage(title: 'Registration Success'),

    home: (_) => const _PlaceholderPage(title: 'Home'),

    myPets: (_) {
      final repository = FirebasePetRepository(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      final controller = PetsController(
        CreatePet(repository),
        GetPets(repository),
        UpdatePet(repository),
        DeletePet(repository),
      );

      return MyPetsPage(controller: controller);
    },
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