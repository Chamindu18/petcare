import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';
import '../../../../app/router/app_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.profileRepository, this.authRepository});

  final ProfileRepository? profileRepository;
  final AuthRepository? authRepository;

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

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

          return _ProfileContent(profile: profile, onLogout: _confirmLogout);
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onLogout});

  final UserProfile profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: 20),
        _SettingsCard(
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
            const _SettingsDivider(),
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
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy & Security',
              subtitle: 'Manage security and privacy information',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.privacySecurity);
              },
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {},
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About PetCare+',
              subtitle: 'App information',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppTheme.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.displayName.trim().isNotEmpty
        ? profile.displayName
        : profile.fullName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 34,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(width: 16),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.deepBrown),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppTheme.deepBrown),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.deepBrown,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 76, endIndent: 16);
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
