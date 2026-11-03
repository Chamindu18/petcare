import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';
import '../../../profile/data/repositories/firebase_profile_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Read-only account and hospital information for veterinary staff.
///
/// The assigned hospital ID must come from HospitalStaffAccessGate.
/// This screen must never provide hospital-assignment editing controls.
class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({
    super.key,
    required this.hospitalId,
    this.profileRepository,
    this.hospitalRepository,
    this.authRepository,
  });

  final String hospitalId;
  final ProfileRepository? profileRepository;
  final HospitalRepository? hospitalRepository;
  final AuthRepository? authRepository;

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  late ProfileProvider _profileProvider;
  late HospitalRepository _hospitalRepository;
  late AuthRepository _authRepository;

  late Future<_HospitalLoadResult> _hospitalFuture;

  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository: widget.profileRepository ?? FirebaseProfileRepository(),
    );

    _hospitalRepository =
        widget.hospitalRepository ?? FirebaseHospitalRepository();

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();

    _profileProvider.startListening();
    _loadHospital();
  }

  @override
  void didUpdateWidget(covariant StaffProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileRepository != widget.profileRepository) {
      _profileProvider.dispose();

      _profileProvider = ProfileProvider(
        repository: widget.profileRepository ?? FirebaseProfileRepository(),
      );

      _profileProvider.startListening();
    }

    if (oldWidget.authRepository != widget.authRepository) {
      _authRepository = widget.authRepository ?? FirebaseAuthRepository();
    }

    if (oldWidget.hospitalId != widget.hospitalId ||
        oldWidget.hospitalRepository != widget.hospitalRepository) {
      _hospitalRepository =
          widget.hospitalRepository ?? FirebaseHospitalRepository();

      _loadHospital();
    }
  }

  /// Converts repository failures into a typed result so no asynchronous
  /// exception escapes before the hospital section is mounted.
  void _loadHospital() {
    final hospitalId = widget.hospitalId;
    _hospitalFuture = _fetchHospital(hospitalId);
  }

  Future<_HospitalLoadResult> _fetchHospital(String hospitalId) async {
    try {
      final hospital = await _hospitalRepository.getHospitalById(hospitalId);

      // Defensively verify the result belongs to the assigned hospital.
      if (hospital == null ||
          !hospital.active ||
          hospital.hospitalId != hospitalId) {
        return const _HospitalLoadResult.unavailable();
      }

      return _HospitalLoadResult.success(hospital);
    } catch (error) {
      debugPrint('Staff profile hospital loading failed: $error');
      return const _HospitalLoadResult.failure();
    }
  }

  void _retryHospital() {
    setState(_loadHospital);
  }

  Future<void> _confirmLogout() async {
    if (_isSigningOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of your PetCare+ account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted || _isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);

    try {
      await _authRepository.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } catch (error) {
      debugPrint('Staff logout failed: ${error.runtimeType}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Staff Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.deepBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your account and assigned hospital information.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Account Details'),
          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: _profileProvider,
            builder: (context, _) {
              if (_profileProvider.isLoading) {
                return const _InformationCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (_profileProvider.errorMessage != null) {
                return _buildErrorCard(
                  message: 'Unable to load your account details.',
                  onRetry: _profileProvider.startListening,
                );
              }

              final profile = _profileProvider.profile;

              if (profile == null ||
                  profile.role.trim().toLowerCase() != 'veterinary_staff') {
                return _buildErrorCard(
                  message: 'Your veterinary staff profile is unavailable.',
                  onRetry: _profileProvider.startListening,
                );
              }

              return _buildAccountDetails(profile);
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle('Assigned Hospital'),
          const SizedBox(height: 12),

          FutureBuilder<_HospitalLoadResult>(
            future: _hospitalFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _InformationCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final result = snapshot.data;

              if (snapshot.hasError || result == null || result.hasError) {
                return _buildErrorCard(
                  message: 'Unable to load hospital details.',
                  onRetry: _retryHospital,
                );
              }

              if (result.hospital == null) {
                return _buildErrorCard(
                  message: 'Your assigned hospital is currently unavailable.',
                  onRetry: _retryHospital,
                );
              }

              return _buildHospitalDetails(result.hospital!);
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle('Account Actions'),
          const SizedBox(height: 12),

          _InformationCard(
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text('Hospital assignment'),
                  subtitle: Text('Managed by authorized administration'),
                ),
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSigningOut ? null : _confirmLogout,
                    icon: _isSigningOut
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(_isSigningOut ? 'Logging out...' : 'Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(UserProfile profile) {
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : profile.displayName.trim();

    return _InformationCard(
      child: Column(
        children: [
          _DetailTile(
            icon: Icons.person_outline_rounded,
            title: 'Full Name',
            value: name,
          ),
          const Divider(),
          _DetailTile(
            icon: Icons.email_outlined,
            title: 'Email Address',
            value: profile.email,
          ),
          const Divider(),
          const _DetailTile(
            icon: Icons.badge_outlined,
            title: 'Account Role',
            value: 'Veterinary Staff',
          ),
          if (profile.phone.trim().isNotEmpty) ...[
            const Divider(),
            _DetailTile(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              value: profile.phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHospitalDetails(Hospital hospital) {
    return _InformationCard(
      child: Column(
        children: [
          _DetailTile(
            icon: Icons.local_hospital_outlined,
            title: 'Hospital Name',
            value: hospital.name,
          ),
          const Divider(),
          _DetailTile(
            icon: Icons.tag_rounded,
            title: 'Hospital ID',
            value: hospital.hospitalId,
          ),
          const Divider(),
          _DetailTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: hospital.location,
          ),
          const Divider(),
          _DetailTile(
            icon: Icons.phone_outlined,
            title: 'Contact Information',
            value: hospital.contact,
          ),
          const Divider(),
          _DetailTile(
            icon: Icons.access_time_rounded,
            title: 'Operating Hours',
            value: hospital.hours,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard({
    required String message,
    required VoidCallback onRetry,
  }) {
    return _InformationCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.deepBrown),
    );
  }
}

class _HospitalLoadResult {
  const _HospitalLoadResult.success(this.hospital) : hasError = false;

  const _HospitalLoadResult.unavailable() : hospital = null, hasError = false;

  const _HospitalLoadResult.failure() : hospital = null, hasError = true;

  final Hospital? hospital;
  final bool hasError;
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'Not provided' : value.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(displayValue),
    );
  }
}
