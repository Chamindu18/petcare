import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../appointments/domain/utils/appointment_date_classifier.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/repositories/hospital_repository.dart';

/// Resolves an appointment load without leaving an unhandled asynchronous error.
class _AppointmentLoadResult {
  const _AppointmentLoadResult.success(this.appointments) : hasError = false;

  const _AppointmentLoadResult.failure()
    : appointments = const <Appointment>[],
      hasError = true;

  final List<Appointment> appointments;
  final bool hasError;
}

/// Hospital-scoped staff overview. The hospital ID must come from a verified
/// staff assignment; Firestore rules enforce that scope independently.
class StaffHospitalOverviewPage extends StatefulWidget {
  const StaffHospitalOverviewPage({
    super.key,
    required this.hospitalId,
    this.repository,
    this.appointmentRepository,
    this.onOpenAppointments,
  });

  final String hospitalId;
  final HospitalRepository? repository;
  final AppointmentRepository? appointmentRepository;
  final VoidCallback? onOpenAppointments;

  @override
  State<StaffHospitalOverviewPage> createState() =>
      _StaffHospitalOverviewPageState();
}

class _StaffHospitalOverviewPageState extends State<StaffHospitalOverviewPage> {
  late HospitalRepository _hospitalRepository;
  late AppointmentRepository _appointmentRepository;
  late Future<Hospital?> _hospitalFuture;
  late Future<_AppointmentLoadResult> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _configureRepositories();
    _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant StaffHospitalOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hospitalId != widget.hospitalId ||
        oldWidget.repository != widget.repository ||
        oldWidget.appointmentRepository != widget.appointmentRepository) {
      _configureRepositories();
      _loadDashboard();
    }
  }

  void _configureRepositories() {
    _hospitalRepository = widget.repository ?? FirebaseHospitalRepository();
    _appointmentRepository =
        widget.appointmentRepository ?? FirebaseAppointmentRepository();
  }

  void _loadDashboard() {
    final hospitalId = widget.hospitalId;
    _hospitalFuture = _hospitalRepository.getHospitalById(hospitalId);
    _appointmentsFuture = _loadAppointmentsSafely(hospitalId);
  }

  Future<_AppointmentLoadResult> _loadAppointmentsSafely(
    String hospitalId,
  ) async {
    try {
      final appointments = await _appointmentRepository
          .getAppointmentsByHospital(hospitalId);

      // Defense in depth if a repository accidentally returns another
      // hospital's appointments. Firestore rules remain authoritative.
      final scopedAppointments = appointments
          .where((appointment) => appointment.hospitalId == hospitalId)
          .toList(growable: false);
      return _AppointmentLoadResult.success(scopedAppointments);
    } catch (error, stackTrace) {
      debugPrint('Staff overview appointment loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const _AppointmentLoadResult.failure();
    }
  }

  void _refresh() {
    setState(_loadDashboard);
  }

  Future<void> _refreshAndWait() async {
    _refresh();
    try {
      await Future.wait<Object?>([_hospitalFuture, _appointmentsFuture]);
    } catch (_) {
      // Errors are displayed by their respective dashboard sections.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hospital?>(
      future: _hospitalFuture,
      builder: (context, hospitalSnapshot) {
        if (hospitalSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (hospitalSnapshot.hasError) {
          return _buildMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load hospital',
            message:
                'We could not retrieve your hospital information. '
                'Please check your connection and try again.',
            actionLabel: 'Retry',
          );
        }

        final hospital = hospitalSnapshot.data;
        if (hospital == null || !hospital.active) {
          return _buildMessage(
            icon: Icons.local_hospital_outlined,
            title: 'Hospital unavailable',
            message:
                'The hospital assigned to your account could not '
                'be found or is currently inactive. '
                'Please contact your administrator.',
            actionLabel: 'Check Again',
          );
        }
        return _buildDashboard(hospital);
      },
    );
  }

  Widget _buildDashboard(Hospital hospital) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshAndWait,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hospital Workspace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your hospital operations at a glance.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            _buildHospitalCard(hospital),
            const SizedBox(height: 24),
            _sectionHeading('Appointment Overview'),
            const SizedBox(height: 12),
            FutureBuilder<_AppointmentLoadResult>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final result = snapshot.data;
                if (snapshot.hasError || result == null || result.hasError) {
                  return _buildAppointmentError();
                }
                return _buildAppointmentOverview(result.appointments);
              },
            ),
            const SizedBox(height: 24),
            _sectionHeading('Hospital Information'),
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
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Dashboard'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hospital.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.deepBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hospital ID: ${hospital.hospitalId}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentOverview(List<Appointment> appointments) {
    final now = DateTime.now();

    final pending = appointments
        .where((appointment) => _status(appointment) == 'pending')
        .length;
    final confirmed = appointments
        .where((appointment) => _status(appointment) == 'confirmed')
        .length;

    final today = appointments.where((appointment) {
      return AppointmentDateClassifier.classify(appointment, now: now) ==
          AppointmentDateCategory.today;
    }).length;

    final overdue = <Appointment>[];
    final upcoming = <Appointment>[];
    for (final appointment in appointments) {
      final category = AppointmentDateClassifier.classify(
        appointment,
        now: now,
      );
      if (category == AppointmentDateCategory.overdue) {
        overdue.add(appointment);
      } else if (category == AppointmentDateCategory.tomorrow ||
          category == AppointmentDateCategory.upcoming ||
          (category == AppointmentDateCategory.today &&
              !appointment.dateTime.isBefore(now))) {
        upcoming.add(appointment);
      }
    }
    overdue.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatisticCard(
                title: "Today's Appointments",
                value: today,
                icon: Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticCard(
                title: 'Pending',
                value: pending,
                icon: Icons.pending_actions_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatisticCard(
                title: 'Confirmed',
                value: confirmed,
                icon: Icons.event_available_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticCard(
                title: 'Total Appointments',
                value: appointments.length,
                icon: Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (overdue.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: _sectionHeading('Overdue Appointments')),
              if (widget.onOpenAppointments != null)
                TextButton(
                  onPressed: widget.onOpenAppointments,
                  child: const Text('View All Overdue'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${overdue.length} unresolved appointment${overdue.length == 1 ? '' : 's'} scheduled before today.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.deepOrange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...overdue
              .take(3)
              .map(
                (appointment) =>
                    _buildAppointmentPreview(appointment, isOverdue: true),
              ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(child: _sectionHeading('Upcoming Appointments')),
            if (widget.onOpenAppointments != null)
              TextButton(
                onPressed: widget.onOpenAppointments,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'No upcoming appointments scheduled.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...upcoming
              .take(3)
              .map((appointment) => _buildAppointmentPreview(appointment)),
      ],
    );
  }

  Widget _buildAppointmentPreview(
    Appointment appointment, {
    bool isOverdue = false,
  }) {
    final date = appointment.dateTime.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
    final time = TimeOfDay.fromDateTime(date).format(context);
    final status = _status(appointment);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue
                ? Colors.deepOrange.shade200
                : AppTheme.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.event_note_rounded,
              color: isOverdue ? Colors.deepOrange.shade800 : AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment #${_shortId(appointment.appointmentId)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateText  •  $time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pet ID: ${appointment.petId}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOverdue ? 'OVERDUE' : status.toUpperCase(),
              style: TextStyle(
                color: isOverdue
                    ? Colors.deepOrange.shade800
                    : status == 'confirmed'
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.primary),
          const SizedBox(height: 10),
          const Text(
            'Unable to load appointment statistics.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.deepBrown),
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
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  static String _status(Appointment appointment) =>
      appointment.status.trim().toLowerCase();

  static String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.deepBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.75)),
          ),
        ],
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
