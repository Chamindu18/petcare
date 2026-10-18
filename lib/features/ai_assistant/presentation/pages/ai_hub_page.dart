import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class AIHubPage extends StatelessWidget {
  const AIHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetCare AI'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PetCare AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Smart advice. Healthier days. Happier pets.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(Icons.pets)),

                    SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Select Pet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Pet information will appear here'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRouter.aiChat);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.psychology),
                    SizedBox(width: 10),
                    Text('Ask me anything...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('Health')),
                Chip(label: Text('Behavior')),
                Chip(label: Text('Nutrition')),
                Chip(label: Text('General')),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Quick Tools',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _ToolTile(
              title: 'Health Summary',
              subtitle: 'Understand pet health records',
              icon: Icons.description,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.healthSummary);
              },
            ),

            _ToolTile(
              title: 'Preventive Care',
              subtitle: 'Upcoming care insights',
              icon: Icons.health_and_safety,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.preventiveInsights);
              },
            ),

            _ToolTile(
              title: 'Vet Visit Prep',
              subtitle: 'Prepare for appointments',
              icon: Icons.pets,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.vetVisitPreparation);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
