import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/veterinarian.dart';
import '../providers/veterinarian_workspace_controller.dart';
import 'veterinarian_edit_profile_page.dart';

class VeterinarianSelfProfilePage extends StatefulWidget {
  const VeterinarianSelfProfilePage({
    super.key,
    required this.controller,
    required this.profile,
    this.authRepository,
    this.embedded = false,
  });

  final VeterinarianWorkspaceController controller;
  final UserProfile profile;
  final AuthRepository? authRepository;
  final bool embedded;

  @override
  State<VeterinarianSelfProfilePage> createState() =>
      _VeterinarianSelfProfilePageState();
}

class _VeterinarianSelfProfilePageState
    extends State<VeterinarianSelfProfilePage> {
  late AuthRepository _authRepository;

  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  @override
  void didUpdateWidget(covariant VeterinarianSelfProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.authRepository != widget.authRepository) {
      _authRepository = widget.authRepository ?? FirebaseAuthRepository();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final content = _buildContent(context);

        if (widget.embedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: const PetCareSecondaryAppBar(title: 'My Profile'),
          body: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final controller = widget.controller;

    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (controller.veterinarian == null) {
      return _buildUnavailableState(
        context,
        message:
            controller.loadErrorMessage ??
            'Your veterinarian profile could not be loaded.',
      );
    }

    final veterinarian = controller.veterinarian!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        _buildHeader(veterinarian, controller.hospital),
        const SizedBox(height: 22),
        _sectionTitle('Professional details'),
        const SizedBox(height: 10),
        _buildProfessionalDetails(veterinarian),
        const SizedBox(height: 22),
        _sectionTitle('Account details'),
        const SizedBox(height: 10),
        _buildAccountDetails(),
        const SizedBox(height: 22),
        _sectionTitle('Assigned hospital'),
        const SizedBox(height: 10),
        _buildHospitalDetails(controller.hospital),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isSigningOut ? null : _confirmLogout,
            icon: _isSigningOut
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(_isSigningOut ? 'Logging out...' : 'Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: BorderSide(color: AppTheme.error.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Veterinarian veterinarian, Hospital? hospital) {
    final displayName = veterinarian.name.trim().isNotEmpty
        ? veterinarian.name.trim()
        : _profileName;
    final imageUrl = _imageUrl(veterinarian);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.white,
                backgroundImage: imageUrl == null
                    ? null
                    : NetworkImage(imageUrl),
                child: imageUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: AppTheme.deepBrown,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (veterinarian.specialty?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        veterinarian.specialty!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.deepBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_hospital_outlined,
                          size: 14,
                          color: AppTheme.deepBrown,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            hospital?.name ?? 'Assigned hospital unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.deepBrown,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDetails(Veterinarian veterinarian) {
    return _InformationCard(
      children: [
        _DetailTile(
          icon: Icons.medical_services_outlined,
          label: 'Specialty',
          value: veterinarian.specialty,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.school_outlined,
          label: 'Qualifications',
          value: veterinarian.qualifications,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.work_outline_rounded,
          label: 'Experience',
          value: veterinarian.experienceYears == null
              ? null
              : '${veterinarian.experienceYears} years',
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.info_outline_rounded,
          label: 'About',
          value: veterinarian.bio,
        ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    return _InformationCard(
      children: [
        _DetailTile(
          icon: Icons.person_outline_rounded,
          label: 'Account name',
          value: _profileName,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.email_outlined,
          label: 'Email address',
          value: widget.profile.email,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.phone_outlined,
          label: 'Phone number',
          value: widget.profile.phone,
        ),
        const Divider(height: 1),
        const _DetailTile(
          icon: Icons.badge_outlined,
          label: 'Account role',
          value: 'Veterinarian',
        ),
      ],
    );
  }

  Widget _buildHospitalDetails(Hospital? hospital) {
    if (hospital == null) {
      return _InformationCard(
        children: [
          _DetailTile(
            icon: Icons.local_hospital_outlined,
            label: 'Hospital',
            value: 'Hospital details are currently unavailable.',
          ),
        ],
      );
    }

    return _InformationCard(
      children: [
        _DetailTile(
          icon: Icons.local_hospital_outlined,
          label: 'Hospital',
          value: hospital.name,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: hospital.location,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.phone_outlined,
          label: 'Contact',
          value: hospital.contact,
        ),
        const Divider(height: 1),
        _DetailTile(
          icon: Icons.access_time_rounded,
          label: 'Operating hours',
          value: hospital.hours,
        ),
      ],
    );
  }

  Widget _buildUnavailableState(
    BuildContext context, {
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppTheme.secondary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.deepBrown, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: widget.controller.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
    );
  }

  String get _profileName {
    final fullName = widget.profile.fullName.trim();

    if (fullName.isNotEmpty) return fullName;

    final displayName = widget.profile.displayName.trim();
    return displayName.isNotEmpty ? displayName : 'Veterinarian';
  }

  String? _imageUrl(Veterinarian veterinarian) {
    final vetImage = veterinarian.profileImageUrl?.trim();
    if (vetImage != null && vetImage.isNotEmpty) return vetImage;

    final accountImage = widget.profile.photoUrl?.trim();
    return accountImage == null || accountImage.isEmpty ? null : accountImage;
  }

  Future<void> _openEditProfile() async {
    final sessionRevision = widget.controller.sessionRevision;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => sessionRevision != widget.controller.sessionRevision || widget.controller.veterinarian == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(
                    child: Text('Profile access is no longer available.'),
                  ),
                )
              : VeterinarianEditProfilePage(controller: widget.controller),
        ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
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

    if (shouldLogout != true || !mounted || _isSigningOut) return;

    setState(() => _isSigningOut = true);

    try {
      await _authRepository.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } catch (error) {
      debugPrint('Veterinarian logout failed: ${error.runtimeType}');

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
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary, size: 21),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.deepBrown,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        normalized == null || normalized.isEmpty ? 'Not provided' : normalized,
        style: const TextStyle(
          color: AppTheme.espresso,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}
