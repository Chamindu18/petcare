import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../providers/health_controller.dart';
import 'health_analytics_page.dart';
import 'health_measurements_page.dart';
import 'medical_conditions_page.dart';
import 'treatments_page.dart';
import 'vaccinations_page.dart';

class HealthRecordsPage extends StatefulWidget {
  const HealthRecordsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerChanged);
    _loadRecords();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadRecords() async {
    await widget.controller.loadHealthRecords(widget.pet.petId);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _openHealthAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            HealthAnalyticsPage(pet: widget.pet, controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Health Records')),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _PetHealthHeader(pet: widget.pet),
            const SizedBox(height: 20),

            // Open the dedicated Health Analytics screen.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openHealthAnalytics,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View Health Analytics'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepBrown,
                  backgroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(
                    color: AppTheme.secondary.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (controller.errorMessage != null)
                _HealthErrorCard(
                  message: controller.errorMessage!,
                  onRetry: _loadRecords,
                ),
              _HealthSummaryGrid(pet: widget.pet, controller: controller),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pet header
// -----------------------------------------------------------------------------

class _PetHealthHeader extends StatelessWidget {
  const _PetHealthHeader({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: pet.imageUrl.isEmpty
                ? const Icon(
                    Icons.pets_rounded,
                    size: 32,
                    color: AppTheme.deepBrown,
                  )
                : Image.network(
                    pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.pets_rounded,
                        size: 32,
                        color: AppTheme.deepBrown,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.species} • ${pet.breed}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 6),
                Text(
                  'Health information',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive health summary grid
// -----------------------------------------------------------------------------

class _HealthSummaryGrid extends StatelessWidget {
  const _HealthSummaryGrid({required this.pet, required this.controller});

  final Pet pet;
  final HealthController controller;

  @override
  Widget build(BuildContext context) {
    final petId = pet.petId;

    final items = [
      _HealthSummaryItem(
        title: 'Medical Conditions',
        count: controller.medicalConditions
            .where((record) => record.petId == petId)
            .length,
        icon: Icons.medical_information_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  MedicalConditionsPage(pet: pet, controller: controller),
            ),
          );
        },
      ),
      _HealthSummaryItem(
        title: 'Vaccinations',
        count: controller.vaccinations
            .where((record) => record.petId == petId)
            .length,
        icon: Icons.vaccines_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  VaccinationsPage(pet: pet, controller: controller),
            ),
          );
        },
      ),
      _HealthSummaryItem(
        title: 'Treatments',
        count: controller.treatments
            .where((record) => record.petId == petId)
            .length,
        icon: Icons.medication_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TreatmentsPage(pet: pet, controller: controller),
            ),
          );
        },
      ),
      _HealthSummaryItem(
        title: 'Health Measurements',
        count: controller.healthMeasurements
            .where((record) => record.petId == petId)
            .length,
        icon: Icons.monitor_heart_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  HealthMeasurementsPage(pet: pet, controller: controller),
            ),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        return _HealthSummaryCard(item: items[index]);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Summary card
// -----------------------------------------------------------------------------

class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({required this.item});

  final _HealthSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
            ),
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
                child: Icon(item.icon, color: AppTheme.deepBrown, size: 24),
              ),
              const Spacer(),
              Text(
                '${item.count}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Summary item model
// -----------------------------------------------------------------------------

class _HealthSummaryItem {
  const _HealthSummaryItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
}

// -----------------------------------------------------------------------------
// Error card
// -----------------------------------------------------------------------------

class _HealthErrorCard extends StatelessWidget {
  const _HealthErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
