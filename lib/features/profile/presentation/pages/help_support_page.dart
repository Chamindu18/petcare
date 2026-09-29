import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Help & Support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find information about using PetCare+ and getting support '
            'when you need it.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        color: AppTheme.deepBrown,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Using PetCare+',
                        style: TextStyle(
                          color: AppTheme.espresso,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PetCare+ helps you manage pet profiles and health '
                    'information, appointments, notifications, and adoption '
                    'activities from one place.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.contact_support_outlined,
                        color: AppTheme.deepBrown,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Need Support?',
                        style: TextStyle(
                          color: AppTheme.espresso,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For support or questions about the application, use '
                    'the support channel provided by your PetCare+ team.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
