import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class AboutPetCarePage extends StatelessWidget {
  const AboutPetCarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('About PetCare+')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'About PetCare+',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Information about the PetCare+ application.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PetCare+',
                    style: TextStyle(
                      color: AppTheme.espresso,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Healthier Pets. Happier Lives.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version',
                        style: TextStyle(
                          color: AppTheme.deepBrown,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '1.0.0',
                        style: TextStyle(
                          color: AppTheme.espresso,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
