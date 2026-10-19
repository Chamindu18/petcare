import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../shared/enums/user_role.dart';

class AdoptionProviderAccessGate extends StatefulWidget {
  const AdoptionProviderAccessGate({
    super.key,
    required this.childBuilder,
    this.auth,
    this.profileRepository,
  });

  final WidgetBuilder childBuilder;
  final FirebaseAuth? auth;
  final ProfileRepository? profileRepository;

  @override
  State<AdoptionProviderAccessGate> createState() =>
      _AdoptionProviderAccessGateState();
}

class _AdoptionProviderAccessGateState
    extends State<AdoptionProviderAccessGate> {
  late final ProfileProvider _profileProvider;
  String? _startupError;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository:
          widget.profileRepository ??
          FirebaseProfileRepository(auth: widget.auth),
    );

    try {
      _profileProvider.startListening();
    } catch (_) {
      _startupError = 'Unable to verify your account access.';
    }
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _startupError = null;
    });

    try {
      _profileProvider.startListening();
    } catch (_) {
      setState(() {
        _startupError = 'Unable to verify your account access.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return _AccessMessagePage(
        title: 'Unable to verify access',
        message: _startupError!,
        onRetry: _retry,
      );
    }

    return ListenableBuilder(
      listenable: _profileProvider,
      builder: (context, _) {
        if (_profileProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          );
        }

        if (_profileProvider.errorMessage != null) {
          return _AccessMessagePage(
            title: 'Unable to verify access',
            message: 'Please check your connection and try again.',
            onRetry: _retry,
          );
        }

        final role = UserRoleX.tryParseFirestore(
          _profileProvider.profile?.role,
        );

        if (role != UserRole.adoptionProvider) {
          return const _AccessMessagePage(
            title: 'Provider access required',
            message: 'This area is available only to adoption providers.',
          );
        }

        return widget.childBuilder(context);
      },
    );
  }
}

class _AccessMessagePage extends StatelessWidget {
  const _AccessMessagePage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppTheme.deepBrown,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.deepBrown),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
