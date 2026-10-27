import 'package:flutter/material.dart';

import '../../../hospitals/domain/entities/hospital.dart';
import '../../domain/entities/veterinarian.dart';

class VeterinarianProfileRouteArgs {
  const VeterinarianProfileRouteArgs({
    required this.veterinarian,
    required this.hospital,
  });

  final Veterinarian veterinarian;
  final Hospital? hospital;
}

class VeterinarianProfilePage extends StatelessWidget {
  const VeterinarianProfilePage({
    super.key,
    required this.veterinarian,
    required this.hospital,
    required this.onBookAppointment,
  });

  final Veterinarian veterinarian;
  final Hospital? hospital;
  final VoidCallback onBookAppointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Veterinarian Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(veterinarian: veterinarian),
            const SizedBox(height: 24),
            if (veterinarian.specialty != null &&
                veterinarian.specialty!.isNotEmpty)
              _InfoSection(
                title: 'Specialty',
                icon: Icons.medical_services_outlined,
                child: Text(
                  veterinarian.specialty!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            if (veterinarian.qualifications != null &&
                veterinarian.qualifications!.isNotEmpty)
              _InfoSection(
                title: 'Qualifications',
                icon: Icons.school_outlined,
                child: Text(
                  veterinarian.qualifications!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            if (veterinarian.experienceYears != null)
              _InfoSection(
                title: 'Experience',
                icon: Icons.work_outline,
                child: Text(
                  '${veterinarian.experienceYears} years',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            if (hospital != null)
              _InfoSection(
                title: 'Hospital',
                icon: Icons.local_hospital_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital!.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hospital!.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hospital!.location,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (hospital!.contact.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hospital!.contact,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            if (veterinarian.bio != null && veterinarian.bio!.isNotEmpty)
              _InfoSection(
                title: 'About',
                icon: Icons.info_outline,
                child: Text(
                  veterinarian.bio!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBookAppointment,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.veterinarian});

  final Veterinarian veterinarian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundImage:
                veterinarian.profileImageUrl != null &&
                    veterinarian.profileImageUrl!.isNotEmpty
                ? NetworkImage(veterinarian.profileImageUrl!)
                : null,
            child:
                veterinarian.profileImageUrl == null ||
                    veterinarian.profileImageUrl!.isEmpty
                ? const Icon(Icons.person, size: 54)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            veterinarian.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (veterinarian.specialty != null &&
              veterinarian.specialty!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              veterinarian.specialty!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 28), child: child),
        ],
      ),
    );
  }
}
