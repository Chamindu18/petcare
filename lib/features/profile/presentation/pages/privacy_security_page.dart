import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  void _openPasswordReset(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouter.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account security and learn how PetCare+ protects '
            'your information.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.lock_reset_rounded,
                color: AppTheme.deepBrown,
              ),
              title: const Text('Reset Password'),
              subtitle: const Text(
                'Send a password reset link to your email address.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openPasswordReset(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'QR Health Passport',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.deepBrown,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'QR sharing uses a secure reference or token rather '
                      'than placing medical information directly in the QR '
                      'code. Access is limited to the appropriate '
                      'appointment and authorization context.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Your PetCare+ information is handled according to the '
                'access permissions and security controls defined for '
                'your account and the features you use.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
