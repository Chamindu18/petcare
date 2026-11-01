import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../domain/entities/ai_pet_context.dart';
import '../providers/ai_provider.dart';

class HealthSummaryPage extends StatefulWidget {
  const HealthSummaryPage({super.key, this.contextData});

  final AIPetContext? contextData;

  @override
  State<HealthSummaryPage> createState() => _HealthSummaryPageState();
}

class _HealthSummaryPageState extends State<HealthSummaryPage> {
  final AIProvider provider = AIProvider();

  @override
  void initState() {
    super.initState();

    if (widget.contextData == null) {
      provider.generateHealthSummary();
    } else {
      provider.loadContextSummary(widget.contextData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Summary')),
      body: Stack(
        children: [
          const Positioned.fill(child: PetCareBackground()),
          AnimatedBuilder(
            animation: provider,
            builder: (_, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.contextData == null) {
                return const Center(child: Text('Please select a pet first.'));
              }

              final pet = widget.contextData!.pet;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _PetOverviewCard(
                      name: pet.name,
                      species: pet.species,
                      breed: pet.breed,
                      weight: pet.weight,
                      imageUrl: pet.imageUrl,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _StatTile(
                          icon: Icons.description_rounded,
                          title: 'Conditions',
                          value: '${widget.contextData!.conditions.length}',
                        ),
                        _StatTile(
                          icon: Icons.vaccines_rounded,
                          title: 'Vaccinations',
                          value: '${widget.contextData!.vaccinations.length}',
                        ),
                        _StatTile(
                          icon: Icons.medication_rounded,
                          title: 'Treatments',
                          value: '${widget.contextData!.treatments.length}',
                        ),
                        _StatTile(
                          icon: Icons.monitor_weight_rounded,
                          title: 'Measurements',
                          value: '${widget.contextData!.measurements.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI Recommendation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Continue monitoring your pet's health, "
                            'maintain vaccination schedules, and keep '
                            'treatment records updated.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PetOverviewCard extends StatelessWidget {
  const _PetOverviewCard({
    required this.name,
    required this.species,
    required this.breed,
    required this.weight,
    required this.imageUrl,
  });

  final String name;
  final String species;
  final String breed;
  final double weight;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.secondary.withValues(alpha: 0.15),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.pets_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      );
                    },
                  )
                : const Icon(
                    Icons.pets_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$species • $breed'),
                const SizedBox(height: 4),
                Text(
                  '$weight kg',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}
