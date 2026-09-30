import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/pets/presentation/pages/pet_profile_page.dart';
import '../../features/pets/presentation/providers/pets_controller.dart';
import '../../features/adoption/presentation/pages/adoption_pet_details_page.dart';
import '../../features/adoption/domain/entities/adoption_listing.dart';
import '../../features/adoption/presentation/pages/adoption_request_page.dart';
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
import '../../features/home/presentation/pages/owner_shell_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/pets/data/repositories/firebase_pet_repository.dart';
import '../../features/pets/domain/usecases/create_pet.dart';
import '../../features/pets/domain/usecases/delete_pet.dart';
import '../../features/pets/domain/usecases/get_pets.dart';
import '../../features/pets/domain/usecases/update_pet.dart';
import '../../features/pets/presentation/pages/add_edit_pet_page.dart';
import '../../features/pets/presentation/pages/my_pets_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/profile/presentation/pages/privacy_security_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/about_petcare_page.dart';

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
  static const String myPets = '/my-pets';
  static const String addPet = '/add-pet';
  static const String adoptionPetDetails = '/adoption-pet-details';
  static const String adoptionRequest = '/adoption-request';
  static const String editProfile = '/edit-profile';
  static const String notificationSettings = '/notification-settings';
  static const String privacySecurity = '/privacy-security';
  static const String helpSupport = '/help-support';
  static const String aboutPetCare = '/about-petcare';
  static const String petProfile = '/pet-profile';

  // Public routes are handled here.
  // Protected routes are handled in onGenerateRoute()
  // so that authentication checks cannot be bypassed.
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),

    onboarding: (_) => const OnboardingPage(),

    onboardingSlides: (_) => const OnboardingSlidesPage(),

    login: (_) => const LoginPage(),

    register: (_) => const RegisterPage(),

    forgotPassword: (_) => const ForgotPasswordPage(),

    checkEmail: (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';

      return CheckEmailPage(email: email);
    },

    resetPassword: (context) {
      final code = ModalRoute.of(context)?.settings.arguments as String?;

      return ResetPasswordPage(code: code);
    },

    passwordResetSuccess: (_) => const PasswordResetSuccessPage(),

    registrationSuccess: (_) => const RegistrationSuccessPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return _onGenerateRoute(settings, FirebaseAuth.instance);
  }

  static RouteFactory routeGenerator({FirebaseAuth? auth}) {
    return (settings) =>
        _onGenerateRoute(settings, auth ?? FirebaseAuth.instance);
  }

  static Route<dynamic>? _onGenerateRoute(
    RouteSettings settings,
    FirebaseAuth auth,
  ) {
    final isAuthenticated = auth.currentUser != null;

    final protectedRoutes = {
      home,
      myPets,
      notifications,
      addPet,
      adoptionPetDetails,
      adoptionRequest,
      editProfile,
      notificationSettings,
      privacySecurity,
      helpSupport,
      aboutPetCare,
      petProfile,
    };

    // Protect routes that require authentication.
    if (protectedRoutes.contains(settings.name) && !isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => const LoginPage(),
        settings: settings,
      );
    }

    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => OwnerShellPage(),
          settings: settings,
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsPage(),
          settings: settings,
        );

      case myPets:
        return MaterialPageRoute(
          builder: (_) {
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
          settings: settings,
        );

      case petProfile:
        final args = settings.arguments;

        return MaterialPageRoute(
          builder: (_) {
            if (args is! PetProfileRouteArgs) {
              return const Scaffold(
                body: Center(child: Text('Unable to open pet profile.')),
              );
            }

            return PetProfilePage(pet: args.pet, controller: args.controller);
          },
          settings: settings,
        );

      case addPet:
        return MaterialPageRoute(
          builder: (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;

            if (arguments is AddEditPetRouteArgs) {
              return AddEditPetPage(
                controller: arguments.controller,
                pet: arguments.pet,
              );
            }

            if (arguments is PetsController) {
              return AddEditPetPage(controller: arguments);
            }

            return const Scaffold(
              body: Center(child: Text('Unable to open Add Pet.')),
            );
          },
          settings: settings,
        );

      case adoptionPetDetails:
        final listingId = settings.arguments as String?;

        return MaterialPageRoute(
          builder: (_) {
            if (listingId == null || listingId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Adoption listing ID is required.')),
              );
            }

            return AdoptionPetDetailsPage(listingId: listingId);
          },
          settings: settings,
        );

      case adoptionRequest:
        final listing = settings.arguments as AdoptionListing?;

        return MaterialPageRoute(
          builder: (_) {
            if (listing == null) {
              return const Scaffold(
                body: Center(child: Text('Adoption listing is required.')),
              );
            }

            return AdoptionRequestPage(listing: listing);
          },
          settings: settings,
        );

      case editProfile:
        final profile = settings.arguments as UserProfile?;

        return MaterialPageRoute(
          builder: (_) {
            if (profile == null) {
              return const Scaffold(
                body: Center(child: Text('Unable to open Edit Profile.')),
              );
            }

            return EditProfilePage(profile: profile);
          },
          settings: settings,
        );

      case notificationSettings:
        final profile = settings.arguments as UserProfile?;

        return MaterialPageRoute(
          builder: (_) {
            if (profile == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Unable to open Notification Settings.'),
                ),
              );
            }

            return NotificationSettingsPage(profile: profile);
          },
          settings: settings,
        );

      case privacySecurity:
        return MaterialPageRoute(
          builder: (_) => const PrivacySecurityPage(),
          settings: settings,
        );

      case helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportPage(),
          settings: settings,
        );

      case aboutPetCare:
        return MaterialPageRoute(
          builder: (_) => const AboutPetCarePage(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
