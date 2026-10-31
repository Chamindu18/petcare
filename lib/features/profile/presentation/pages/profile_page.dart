import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.profileRepository,
    this.authRepository,
    this.photoUrl,
  });

  final ProfileRepository? profileRepository;
  final AuthRepository? authRepository;
  final String? photoUrl;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileProvider _profileProvider;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository: widget.profileRepository ?? FirebaseProfileRepository(),
    );

    _authRepository = widget.authRepository ?? FirebaseAuthRepository();

    _profileProvider.startListening();
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of your PetCare+ account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    try {
      await _authRepository.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListenableBuilder(
        listenable: _profileProvider,
        builder: (context, _) {
          if (_profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_profileProvider.errorMessage != null) {
            return _ErrorState(onRetry: _profileProvider.startListening);
          }

          final profile = _profileProvider.profile;

          if (profile == null) {
            return _ErrorState(onRetry: _profileProvider.startListening);
          }

          return _ProfileContent(
            profile: profile,
            photoUrl: widget.photoUrl,
            onLogout: _confirmLogout,
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onLogout,
    this.photoUrl,
  });

  final UserProfile profile;
  final VoidCallback onLogout;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _ProfileHeader(profile: profile, photoUrl: photoUrl),

        const SizedBox(height: 28),

        _SettingsSection(
          title: 'Account',
          subtitle: 'Manage your personal account details.',
          children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Personal Information',
              subtitle: 'Update your name and contact details',
              onTap: () {
                Navigator.of(context)
                    .pushNamed(AppRouter.editProfile, arguments: profile);
              },
            ),
          ],
        ),

        const SizedBox(height: 22),

        _SettingsSection(
          title: 'Preferences',
          subtitle: 'Manage your application preferences.',
          children: [
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: profile.notificationEnabled
                  ? 'Notifications are enabled'
                  : 'Notifications are disabled',
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRouter.notificationSettings, arguments: profile);
              },
            ),
          ],
        ),

        const SizedBox(height: 22),

        _SettingsSection(
          title: 'Security',
          subtitle: 'Manage your account protection and privacy.',
          children: [
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy & Security',
              subtitle: 'Manage account security and data privacy',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.privacySecurity);
              },
            ),
          ],
        ),

        const SizedBox(height: 22),

        _SettingsSection(
          title: 'Support',
          subtitle: 'Application information and assistance.',
          children: [
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get help with using PetCare+',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.helpSupport);
              },
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About PetCare+',
              subtitle: 'Application information and version',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.aboutPetCare);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        _LogoutButton(onPressed: onLogout),

        const SizedBox(height: 16),

        Center(
          child: Text(
            'PetCare+',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, this.photoUrl});

  final UserProfile profile;
  final String? photoUrl;

  String get _displayName {
    return profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim()
        : profile.fullName.trim();
  }

  String get _roleLabel {
    switch (profile.role) {
      case 'owner':
        return 'Pet Owner';
      case 'veterinarian':
        return 'Veterinarian';
      case 'veterinary_staff':
        return 'Veterinary Staff';
      case 'adoption_provider':
        return 'Adoption Provider';
      default:
        return 'PetCare+ Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: normalizedPhotoUrl == null || normalizedPhotoUrl.isEmpty
                  ? _buildAvatarFallback()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        normalizedPhotoUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        semanticLabel: 'Profile photo',
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback();
                        },
                      ),
                    ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),

                  const SizedBox(height: 9),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          size: 14,
                          color: AppTheme.deepBrown,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _roleLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.deepBrown,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return const Icon(
      Icons.person_rounded,
      size: 36,
      color: AppTheme.deepBrown,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.deepBrown),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        minVerticalPadding: 12,

        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.deepBrown, size: 23),
        ),

        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w700),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.deepBrown, height: 1.4),
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.deepBrown,
          size: 24,
        ),

        onTap: onTap,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 78,
      endIndent: 16,
      color: AppTheme.secondary.withValues(alpha: 0.40),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(
            color: AppTheme.error.withValues(alpha: 0.8),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.error,
            ),

            const SizedBox(height: 16),

            Text(
              'Unable to load your profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
