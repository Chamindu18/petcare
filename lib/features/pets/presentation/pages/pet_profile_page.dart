import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/pet.dart';

class PetProfilePage extends StatelessWidget {
  const PetProfilePage({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pet Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PetHeader(pet: pet),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Pet Information',
                icon: Icons.pets_outlined,
              ),
              const SizedBox(height: 12),
              _PetInformationCard(pet: pet),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Health Overview',
                icon: Icons.favorite_border_rounded,
              ),
              const SizedBox(height: 12),
              const _HealthOverviewGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            child: pet.imageUrl.isEmpty
                ? const Icon(
                    Icons.pets_rounded,
                    size: 52,
                    color: AppTheme.deepBrown,
                  )
                : Image.network(
                    pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.pets_rounded,
                        size: 52,
                        color: AppTheme.deepBrown,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            pet.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pet.species} • ${pet.breed}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown),
          ),
        ],
      ),
    );
  }
}

class _PetInformationCard extends StatelessWidget {
  const _PetInformationCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: _ageLabel,
            ),
          ),
          Expanded(
            child: _InfoItem(
              icon: Icons.person_outline_rounded,
              label: 'Gender',
              value: pet.gender,
            ),
          ),
          Expanded(
            child: _InfoItem(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: '${_formatWeight(pet.weight)} kg',
            ),
          ),
        ],
      ),
    );
  }

  String get _ageLabel {
    final age = pet.ageInYears;

    return age == 1 ? '1 year' : '$age years';
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toString();
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.deepBrown, size: 24),
        const SizedBox(height: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppTheme.deepBrown),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HealthOverviewGrid extends StatelessWidget {
  const _HealthOverviewGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (title: 'Medical Conditions', icon: Icons.medical_information_outlined),
      (title: 'Vaccinations', icon: Icons.vaccines_outlined),
      (title: 'Treatments', icon: Icons.medication_outlined),
      (title: 'Health Measurements', icon: Icons.monitor_heart_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _HealthCard(title: item.title, icon: item.icon);
      },
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBrown, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'No records yet',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepBrown, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
