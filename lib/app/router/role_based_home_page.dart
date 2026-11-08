import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/adoption/data/repositories/firebase_adoption_listing_repository.dart';
import '../../features/adoption/data/repositories/firebase_adoption_request_repository.dart';
import '../../features/adoption/presentation/pages/adoption_provider_dashboard_page.dart';
import '../../features/adoption/presentation/providers/my_adoption_listings_provider.dart';
import '../../features/adoption/presentation/providers/received_adoption_requests_provider.dart';
import '../../features/home/presentation/pages/owner_shell_page.dart';
import '../../features/hospital_staff/data/repositories/firebase_hospital_staff_assignment_repository.dart';
import '../../features/hospital_staff/domain/entities/hospital_staff_assignment.dart';
import '../../features/hospital_staff/domain/repositories/hospital_staff_assignment_repository.dart';
import '../../features/hospital_staff/presentation/pages/staff_shell_page.dart';
import '../../features/hospital_staff/presentation/widgets/hospital_staff_access_gate.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/veterinary/presentation/pages/veterinarian_dashboard_page.dart';
import '../../shared/enums/user_role.dart';

class RoleBasedHomePage extends StatefulWidget {
  const RoleBasedHomePage({
    super.key,
    this.auth,
    this.profileRepository,
    this.hospitalStaffAssignmentRepository,
    this.ownerDashboardBuilder,
    this.adoptionProviderDashboardBuilder,
    this.staffWorkspaceBuilder,
  });

  final FirebaseAuth? auth;
  final ProfileRepository? profileRepository;
  final HospitalStaffAssignmentRepository? hospitalStaffAssignmentRepository;

  // Optional overrides for isolated routing tests.
  // The production dashboards are used when these are null.
  final Widget Function()? ownerDashboardBuilder;
  final Widget Function()? adoptionProviderDashboardBuilder;

  /// Optional override for the hospital staff workspace.
  ///
  /// The workspace is only built after the staff assignment has been
  /// successfully verified by HospitalStaffAccessGate.
  final Widget Function(
    BuildContext context,
    HospitalStaffAssignment assignment,
  )?
  staffWorkspaceBuilder;

  @override
  State<RoleBasedHomePage> createState() => _RoleBasedHomePageState();
}

class _RoleBasedHomePageState extends State<RoleBasedHomePage> {
  late final ProfileProvider _profileProvider;

  Widget? _destination;
  String? _destinationKey;
  String? _startupError;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository:
          widget.profileRepository ??
          FirebaseProfileRepository(auth: widget.auth),
    );

    _profileProvider.addListener(_handleProfileChange);

    try {
      _profileProvider.startListening();
    } catch (_) {
      _startupError = 'Unable to verify your account. Please try again.';
    }
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_handleProfileChange);
    _profileProvider.dispose();
    super.dispose();
  }

  void _handleProfileChange() {
    if (!mounted) return;

    if (_profileProvider.isLoading || _profileProvider.errorMessage != null) {
      setState(() {
        _destination = null;
        _destinationKey = null;
      });
      return;
    }

    final role = UserRoleX.tryParseFirestore(_profileProvider.profile?.role);
    final roleKey =
        '${_profileProvider.profile?.uid ?? '__unknown'}:'
        '${role?.firestoreValue ?? '__unknown'}';

    if (_destination != null && _destinationKey == roleKey) {
      return;
    }

    final destination = _destinationForRole(role, _profileProvider.profile);

    setState(() {
      _destination = destination;
      _destinationKey = roleKey;
    });
  }

  Widget _destinationForRole(UserRole? role, UserProfile? profile) {
    if (role == null) {
      return const _HomeMessagePage(
        title: 'Account role unavailable',
        message:
            'We could not determine your account role. '
            'Access to role-specific features has not been granted.',
      );
    }

    switch (role) {
      case UserRole.owner:
        return widget.ownerDashboardBuilder?.call() ?? const OwnerShellPage();

      case UserRole.adoptionProvider:
        final dashboardBuilder = widget.adoptionProviderDashboardBuilder;

        if (dashboardBuilder != null) {
          return dashboardBuilder();
        }

        return AdoptionProviderDashboardPage(
          listingsProvider: MyAdoptionListingsProvider(
            repository: FirebaseAdoptionListingRepository(auth: widget.auth),
          ),
          requestsProvider: ReceivedAdoptionRequestsProvider(
            repository: FirebaseAdoptionRequestRepository(auth: widget.auth),
          ),
        );

      case UserRole.veterinaryStaff:
        return HospitalStaffAccessGate(
          repository:
              widget.hospitalStaffAssignmentRepository ??
              FirebaseHospitalStaffAssignmentRepository(auth: widget.auth),
          workspaceBuilder: (context, assignment) {
            final builder = widget.staffWorkspaceBuilder;

            if (builder != null) {
              return builder(context, assignment);
            }

            return StaffShellPage(assignment: assignment);
          },
        );

      case UserRole.veterinarian:
        if (profile == null) {
          return const _HomeMessagePage(
            title: 'Profile unavailable',
            message:
                'Your veterinarian profile could not be loaded. '
                'Please try again.',
          );
        }

        return VeterinarianDashboardPage(profile: profile);
    }
  }

  void _retry() {
    setState(() {
      _startupError = null;
      _destination = null;
      _destinationKey = null;
    });

    try {
      _profileProvider.startListening();
    } catch (_) {
      setState(() {
        _startupError = 'Unable to verify your account. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return _HomeMessagePage(
        title: 'Unable to verify account',
        message: _startupError!,
        onRetry: _retry,
      );
    }

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
      return _HomeMessagePage(
        title: 'Unable to load profile',
        message: 'Please check your connection and try again.',
        onRetry: _retry,
      );
    }

    return _destination ??
        const _HomeMessagePage(
          title: 'Account role unavailable',
          message: 'Your account role could not be determined.',
        );
  }
}

class _HomeMessagePage extends StatelessWidget {
  const _HomeMessagePage({
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
