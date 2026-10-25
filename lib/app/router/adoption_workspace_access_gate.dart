import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../shared/enums/user_role.dart';

/// Allows only explicitly listed roles into shared adoption screens.
/// Listing ownership and request authorization are still enforced by Firestore.
class AdoptionWorkspaceAccessGate extends StatefulWidget {
  const AdoptionWorkspaceAccessGate({
    super.key,
    required this.childBuilder,
    this.allowedRoles = const {'owner', 'adoption_provider'},
    this.auth,
    this.profileRepository,
  });

  final WidgetBuilder childBuilder;
  final Set<String> allowedRoles;
  final FirebaseAuth? auth;
  final ProfileRepository? profileRepository;

  @override
  State<AdoptionWorkspaceAccessGate> createState() =>
      _AdoptionWorkspaceAccessGateState();
}

class _AdoptionWorkspaceAccessGateState
    extends State<AdoptionWorkspaceAccessGate> {
  late final ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _profileProvider = ProfileProvider(
      repository:
          widget.profileRepository ??
          FirebaseProfileRepository(auth: widget.auth),
    );
    _profileProvider.startListening();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profileProvider,
      builder: (context, _) {
        if (_profileProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_profileProvider.errorMessage != null) {
          return const _AccessMessage(
            title: 'Unable to verify access',
            message: 'Please check your connection and try again.',
          );
        }

        final role = UserRoleX.tryParseFirestore(
          _profileProvider.profile?.role,
        );
        if (role == null || !widget.allowedRoles.contains(role.firestoreValue)) {
          return const _AccessMessage(
            title: 'Adoption access required',
            message: 'This adoption screen is not available for your account.',
          );
        }
        return widget.childBuilder(context);
      },
    );
  }
}

class _AccessMessage extends StatelessWidget {
  const _AccessMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.deepBrown,
          ),
        ),
      ),
    ),
  );
}
