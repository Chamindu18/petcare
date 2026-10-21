import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../providers/selected_pet_provider.dart';

class AIHubPage extends StatefulWidget {
  const AIHubPage({super.key});

  @override
  State<AIHubPage> createState() => _AIHubPageState();
}

class _AIHubPageState extends State<AIHubPage> {
  final SelectedPetProvider _petProvider = SelectedPetProvider();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: PetCareBackground()),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Image.asset(
                      'assets/branding/petcare_logo.png',
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'PetCare AI Assistant',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Smart advice. Healthier days. Happier pets.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: AppTheme.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: AnimatedBuilder(
                            animation: _petProvider,
                            builder: (context, _) {
                              final pet = _petProvider.selectedPet;

                              if (pet == null) {
                                return const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Pet',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text('No pet selected'),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${pet.breed} • ${pet.ageInYears} years',
                                  ),

                                  Text('${pet.weight} kg'),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.aiChat);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.secondary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Ask me anything...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _topicChip('Health'),
                      _topicChip('Behavior'),
                      _topicChip('Nutrition'),
                      _topicChip('General'),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Quick Tools',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _ToolTile(
                    title: 'Health Summary',
                    subtitle: 'Understand pet health records',
                    icon: Icons.description_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.healthSummary);
                    },
                  ),

                  _ToolTile(
                    title: 'Preventive Care',
                    subtitle: 'Upcoming care insights',
                    icon: Icons.health_and_safety_rounded,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.preventiveInsights,
                      );
                    },
                  ),

                  _ToolTile(
                    title: 'Vet Visit Prep',
                    subtitle: 'Prepare for appointments',
                    icon: Icons.medical_services_rounded,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.vetVisitPreparation,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Text(title),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
