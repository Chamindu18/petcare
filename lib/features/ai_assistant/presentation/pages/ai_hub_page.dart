import 'package:flutter/material.dart';
import 'package:petcare/features/ai_assistant/presentation/pages/ai_chat_page.dart';
import 'package:petcare/features/pets/domain/entities/pet.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/petcare_background.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../domain/usecases/create_pet_context.dart';
import '../../domain/entities/ai_pet_context.dart';
import 'health_summary_page.dart';
import 'preventive_insights_page.dart';
import 'vet_visit_preparation_page.dart';

class AIHubPage extends StatefulWidget {
  const AIHubPage({super.key, this.pets, this.healthController});

  final List<Pet>? pets;
  final HealthController? healthController;

  @override
  State<AIHubPage> createState() => _AIHubPageState();
}

class _AIHubPageState extends State<AIHubPage> {
  Pet? selectedPet;

  @override
  void initState() {
    super.initState();

    if (widget.pets != null && widget.pets!.isNotEmpty) {
      selectedPet = widget.pets!.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildContext();
      });
    }
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

                  Text(
                    'Selected Pet',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

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
                          width: 70,
                          height: 70,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: selectedPet?.imageUrl.isNotEmpty == true
                              ? Image.network(
                                  selectedPet!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) {
                                    return Container(
                                      color: AppTheme.primary,
                                      child: const Icon(
                                        Icons.pets,
                                        color: AppTheme.white,
                                        size: 32,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppTheme.primary,
                                  child: const Icon(
                                    Icons.pets,
                                    color: AppTheme.white,
                                    size: 32,
                                  ),
                                ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: widget.pets == null || widget.pets!.isEmpty
                              ? const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No pets available',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedPet?.name ?? 'Select a pet',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<Pet>(
                                            value: selectedPet,
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                            ),
                                            items: widget.pets!
                                                .map(
                                                  (pet) =>
                                                      DropdownMenuItem<Pet>(
                                                        value: pet,
                                                        child: Text(pet.name),
                                                      ),
                                                )
                                                .toList(),
                                            onChanged: (pet) async {
                                              if (pet == null) return;

                                              setState(() {
                                                selectedPet = pet;
                                              });

                                              await _buildContext();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    Text(
                                      selectedPet?.species ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      '${selectedPet?.ageInYears ?? 0} years • '
                                      '${selectedPet?.weight ?? 0} kg',
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AIChatPage(
                            contextData: _currentContext,
                            pets: widget.pets,
                            healthController: widget.healthController,
                          ),
                        ),
                      );
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
                      if (_currentContext == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a pet first.'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 200),
                            backgroundColor: Colors.brown,
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HealthSummaryPage(contextData: _currentContext),
                        ),
                      );
                    },
                  ),

                  _ToolTile(
                    title: 'Preventive Care',
                    subtitle: 'Upcoming care insights',
                    icon: Icons.health_and_safety_rounded,
                    onTap: () {
                      if (_currentContext == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a pet first.'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 200),
                            backgroundColor: Colors.brown,
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreventiveInsightsPage(
                            contextData: _currentContext,
                          ),
                        ),
                      );
                    },
                  ),

                  _ToolTile(
                    title: 'Vet Visit Prep',
                    subtitle: 'Prepare for appointments',
                    icon: Icons.medical_services_rounded,
                    onTap: () {
                      if (_currentContext == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a pet first.'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 200),
                            backgroundColor: Colors.brown,
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VetVisitPreparationPage(
                            contextData: _currentContext,
                          ),
                        ),
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

  final CreatePetContext _createPetContext = const CreatePetContext();

  AIPetContext? _currentContext;
  Future<void> _buildContext() async {
    if (selectedPet == null || widget.healthController == null) {
      return;
    }

    await widget.healthController!.loadHealthRecords(selectedPet!.petId);

    _currentContext = _createPetContext(
      pet: selectedPet!,
      conditions: widget.healthController!.medicalConditions,
      vaccinations: widget.healthController!.vaccinations,
      treatments: widget.healthController!.treatments,
      measurements: widget.healthController!.healthMeasurements,
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
