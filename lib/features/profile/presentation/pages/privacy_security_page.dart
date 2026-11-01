import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  void _openPasswordReset(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.forgotPassword);
  }

  void _openHelpSupport(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.helpSupport);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _SecurityIntroduction(),

          const SizedBox(height: 28),

          _SectionHeading(
            title: 'Account Security',
            subtitle: 'Manage access to your PetCare+ account.',
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                _SecurityActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Reset Password',
                  subtitle: 'Request a password reset link.',
                  onTap: () => _openPasswordReset(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _InformationNote(
            icon: Icons.info_outline_rounded,
            message:
                'When you request a password reset, PetCare+ uses your '
                'registered email address to send the reset instructions. '
                'Never share your password or reset link with anyone.',
          ),

          const SizedBox(height: 28),

          _SectionHeading(
            title: 'Your Information',
            subtitle: 'Understand the information used by PetCare+.',
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const _PrivacyInformationTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Account Information',
                  description:
                      'Your account profile contains details such as your '
                      'name, email address and contact number. These details '
                      'help identify your PetCare+ account.',
                ),

                const _SectionDivider(),

                const _PrivacyInformationTile(
                  icon: Icons.pets_rounded,
                  title: 'Pet Care Information',
                  description:
                      'PetCare+ supports pet profiles, health records and '
                      'appointment information. These records are associated '
                      'with your account and the relevant application features.',
                ),

                const _SectionDivider(),

                const _PrivacyInformationTile(
                  icon: Icons.shield_outlined,
                  title: 'Data Access',
                  description:
                      'Access to account information is controlled through '
                      'authentication, account ownership checks and the '
                      'application security rules.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _SectionHeading(
            title: 'Protect Your Account',
            subtitle: 'A few steps to keep your account safe.',
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const _SecurityTip(
                    icon: Icons.password_rounded,
                    title: 'Keep your password private',
                    description:
                        'Do not share your password with other people.',
                  ),

                  const SizedBox(height: 18),

                  const _SecurityTip(
                    icon: Icons.phonelink_lock_rounded,
                    title: 'Use trusted devices',
                    description:
                        'Avoid signing in on devices you do not trust.',
                  ),

                  const SizedBox(height: 18),

                  const _SecurityTip(
                    icon: Icons.logout_rounded,
                    title: 'Sign out on shared devices',
                    description:
                        'Always sign out when you finish using PetCare+ '
                        'on a shared device.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          Card(
            child: _SecurityActionTile(
              icon: Icons.help_outline_rounded,
              title: 'Need Help?',
              subtitle: 'Get assistance with your account.',
              onTap: () => _openHelpSupport(context),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'PetCare+ • Privacy & Security',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.deepBrown.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityIntroduction extends StatelessWidget {
  const _SecurityIntroduction();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppTheme.deepBrown,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Account Protection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Manage your account security and understand how '
                    'your information is used within PetCare+.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                ?.copyWith(color: AppTheme.deepBrown, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SecurityActionTile extends StatelessWidget {
  const _SecurityActionTile({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

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
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.deepBrown, height: 1.4),
        ),
      ),

      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.deepBrown,
      ),

      onTap: onTap,
    );
  }
}

class _PrivacyInformationTile extends StatelessWidget {
  const _PrivacyInformationTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppTheme.deepBrown, size: 21),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: AppTheme.secondary.withValues(alpha: 0.40),
    );
  }
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.deepBrown,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  const _SecurityTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.deepBrown, size: 22),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.deepBrown, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
