import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../services/data/repositories/firebase_service_repository.dart';
import '../../../services/domain/usecases/service_usecases.dart';
import '../../../veterinary/data/repositories/firebase_veterinarian_repository.dart';
import '../../../veterinary/domain/usecases/veterinarian_usecases.dart';
import '../../data/repositories/firebase_hospital_repository.dart';
import '../../domain/usecases/hospital_usecases.dart';
import '../providers/hospital_details_provider.dart';

class HospitalDetailsPage extends StatefulWidget {
  const HospitalDetailsPage({
    required this.hospitalId,
    super.key,
  });

  final String hospitalId;

  @override
  State<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage> {
  late final HospitalDetailsProvider _provider;

  @override
  void initState() {
    super.initState();

    
    _provider = HospitalDetailsProvider(
      getHospitalById: GetHospitalById(
        FirebaseHospitalRepository(),
      ),
      getServicesByHospital: GetServicesByHospital(
        FirebaseServiceRepository(),
      ),
      getVeterinariansByHospital: GetVeterinariansByHospital(
        FirebaseVeterinarianRepository(),
      ),
    );

    _provider.loadHospital(widget.hospitalId);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hospital Details'),
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_provider.errorMessage != null) {
            return _ErrorState(
              message: _provider.errorMessage!,
              onRetry: () => _provider.loadHospital(
                widget.hospitalId,
              ),
            );
          }

          final hospital = _provider.hospital;

          if (hospital == null) {
            return const _ErrorState(
              message: 'Hospital not found.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => _provider.loadHospital(
              widget.hospitalId,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                32,
              ),
              children: [
                _HospitalHeader(
                  name: hospital.name,
                  location: hospital.location,
                  contact: hospital.contact,
                  hours: hospital.hours,
                ),

                const SizedBox(height: 24),

                _SectionTitle(
                  title: 'Services',
                  count: _provider.services.length,
                ),

                const SizedBox(height: 12),

                if (_provider.services.isEmpty)
                  const _EmptySection(
                    message: 'No services are currently available.',
                  )
                else
                  ..._provider.services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _ServiceCard(
                        name: service.name,
                        description: service.description,
                        duration: service.duration,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                _SectionTitle(
                  title: 'Veterinarians',
                  count: _provider.veterinarians.length,
                ),

                const SizedBox(height: 12),

                if (_provider.veterinarians.isEmpty)
                  const _EmptySection(
                    message:
                        'No veterinarians are currently available.',
                  )
                else
                  ..._provider.veterinarians.map(
                    (veterinarian) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _VeterinarianCard(
                        name: veterinarian.name,
                        specialty: veterinarian.specialty,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Opens O16 and passes the selected hospital.
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.bookAppointment,
                      arguments: widget.hospitalId,
                    );
                  },
                  child: const Text('Book an Appointment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HospitalHeader extends StatelessWidget {
  const _HospitalHeader({
    required this.name,
    required this.location,
    required this.contact,
    required this.hours,
  });

  final String name;
  final String location;
  final String contact;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                size: 32,
                color: AppTheme.deepBrown,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
            ),

            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.location_on_outlined,
              text: location,
            ),

            const SizedBox(height: 10),

            _InfoRow(
              icon: Icons.phone_outlined,
              text: contact,
            ),

            const SizedBox(height: 10),

            _InfoRow(
              icon: Icons.access_time_outlined,
              text: hours,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppTheme.deepBrown,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.name,
    required this.description,
    required this.duration,
  });

  final String name;
  final String description;
  final int? duration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.medical_services_outlined,
              color: AppTheme.deepBrown,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: AppTheme.espresso,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description),
                  ],

                  if (duration != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$duration minutes',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppTheme.deepBrown,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VeterinarianCard extends StatelessWidget {
  const _VeterinarianCard({
    required this.name,
    required this.specialty,
  });

  final String name;
  final String? specialty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary,
          child: const Icon(
            Icons.person_outline,
            color: AppTheme.deepBrown,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: AppTheme.espresso,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: specialty == null || specialty!.isEmpty
            ? null
            : Text(specialty!),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.deepBrown,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(
            color: AppTheme.deepBrown,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppTheme.error,
            ),

            const SizedBox(height: 16),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}