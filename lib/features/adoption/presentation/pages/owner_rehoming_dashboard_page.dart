import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class OwnerRehomingDashboardPage extends StatelessWidget {
  const OwnerRehomingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Adoption & Rehoming')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Manage your rehoming listings and adoption requests.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.deepBrown,
            ),
          ),
          const SizedBox(height: 20),
          _DashboardAction(
            icon: Icons.search_rounded,
            title: 'Browse available pets',
            subtitle: 'Discover pets listed by owners and adoption providers.',
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.adoptionListings,
            ),
          ),
          _DashboardAction(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create a rehoming listing',
            subtitle: 'Publish a pet listing for potential adopters.',
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.createEditAdoptionListing,
            ),
          ),
          _DashboardAction(
            icon: Icons.pets_rounded,
            title: 'My rehoming listings',
            subtitle: 'View and edit listings you own.',
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.myAdoptionListings,
            ),
          ),
          _DashboardAction(
            icon: Icons.inbox_outlined,
            title: 'Requests for my listings',
            subtitle: 'Review requests sent to your rehoming listings.',
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.adoptionRequests,
            ),
          ),
          _DashboardAction(
            icon: Icons.assignment_outlined,
            title: 'My adoption requests',
            subtitle: 'Track requests you submitted for other pets.',
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.myAdoptionRequests,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Icon(icon, color: AppTheme.deepBrown, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
