import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';

/// Displays the real hospital information for the assigned staff member.
///
/// The hospital ID comes from the verified staff assignment. Staff members
/// cannot select or change the hospital displayed by this page.
class StaffHospitalOverviewPage extends StatefulWidget {
  const StaffHospitalOverviewPage({
    super.key,
    required this.hospitalId,
    this.repository,
  });

  final String hospitalId;
  final HospitalRepository? repository;

  @override
  State<StaffHospitalOverviewPage> createState() =>
      _StaffHospitalOverviewPageState();
}

class _StaffHospitalOverviewPageState extends State<StaffHospitalOverviewPage> {
  late HospitalRepository _repository;
  late Future<Hospital?> _hospitalFuture;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? FirebaseHospitalRepository();
    _loadHospital();
  }

  @override
  void didUpdateWidget(covariant StaffHospitalOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.hospitalId != widget.hospitalId ||
        oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? FirebaseHospitalRepository();
      _loadHospital();
    }
  }

  void _loadHospital() {
    _hospitalFuture = _repository.getHospitalById(widget.hospitalId);
  }

  void _retry() {
    setState(_loadHospital);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hospital?>(
      future: _hospitalFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load hospital',
            message:
                'We could not retrieve your hospital information. '
                'Please check your connection and try again.',
            actionLabel: 'Retry',
          );
        }

        final hospital = snapshot.data;

        if (hospital == null || !hospital.active) {
          return _buildMessage(
            icon: Icons.local_hospital_outlined,
            title: 'Hospital unavailable',
            message:
                'The hospital assigned to your account could not be found '
                'or is currently inactive. Please contact your administrator.',
            actionLabel: 'Check Again',
          );
        }

        return _buildHospitalDetails(hospital);
      },
    );
  }

  Widget _buildHospitalDetails(Hospital hospital) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hospital Workspace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your assigned hospital and operational information.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),

            // Assigned hospital information.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: AppTheme.primary,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 9, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hospital.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hospital ID: ${hospital.hospitalId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.deepBrown.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Hospital Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 12),

            _HospitalInformationTile(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: hospital.location,
            ),
            const SizedBox(height: 12),

            _HospitalInformationTile(
              icon: Icons.phone_outlined,
              title: 'Contact Information',
              value: hospital.contact,
            ),
            const SizedBox(height: 12),

            _HospitalInformationTile(
              icon: Icons.access_time_rounded,
              title: 'Operating Hours',
              value: hospital.hours,
            ),

            const SizedBox(height: 24),

            Text(
              'Hospital Operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the dashboard sections to manage appointments, '
              'monitor veterinarian schedules, and coordinate the '
              'hospital queue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.deepBrown.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: AppTheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.deepBrown.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalInformationTile extends StatelessWidget {
  const _HospitalInformationTile({
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBrown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.75),
                    height: 1.4,
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
