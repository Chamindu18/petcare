import 'package:flutter/material.dart';

import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/usecases/hospital_usecases.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/repositories/firebase_veterinarian_repository.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/usecases/veterinarian_usecases.dart';

class VeterinarianDashboardPage extends StatefulWidget {
  const VeterinarianDashboardPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<VeterinarianDashboardPage> createState() =>
      _VeterinarianDashboardPageState();
}

class _VeterinarianDashboardPageState extends State<VeterinarianDashboardPage> {
  late final GetAppointmentsByVeterinarian _getAppointments;
  late final GetVeterinarianById _getVeterinarian;
  late final GetHospitalById _getHospital;

  List<Appointment> _appointments = [];
  Veterinarian? _veterinarian;
  Hospital? _hospital;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _getAppointments = GetAppointmentsByVeterinarian(
      FirebaseAppointmentRepository(),
    );

    _getVeterinarian = GetVeterinarianById(FirebaseVeterinarianRepository());

    _getHospital = GetHospitalById(FirebaseHospitalRepository());

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final vetId = widget.profile.vetId;
    final hospitalId = widget.profile.hospitalId;

    if (vetId == null ||
        vetId.isEmpty ||
        hospitalId == null ||
        hospitalId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Your veterinarian account is missing its '
            'veterinarian or hospital assignment.';
      });
      return;
    }

    try {
      // Load the three dashboard data sources concurrently.
      final results = await Future.wait([
        _getVeterinarian(vetId),
        _getHospital(hospitalId),
        _getAppointments(vetId: vetId, hospitalId: hospitalId),
      ]);

      final veterinarian = results[0] as Veterinarian?;
      final hospital = results[1] as Hospital?;
      final appointments = results[2] as List<Appointment>;

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;

      setState(() {
        _veterinarian = veterinarian;
        _hospital = hospital;
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load dashboard information. Please check your '
            'connection and try again.';
      });

      debugPrint('Veterinarian dashboard error: $error');
    }
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();

    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool _isUpcoming(Appointment appointment) {
    return appointment.dateTime.isAfter(DateTime.now()) &&
        appointment.status != 'cancelled' &&
        appointment.status != 'rejected';
  }

  List<Appointment> get _todayAppointments {
    return _appointments.where((appointment) {
      return _isToday(appointment.dateTime) &&
          appointment.status != 'cancelled' &&
          appointment.status != 'rejected';
    }).toList();
  }

  List<Appointment> get _upcomingAppointments {
    return _appointments.where(_isUpcoming).toList();
  }

  int get _pendingCount {
    return _appointments.where((appointment) {
      return appointment.status == 'pending';
    }).length;
  }

  String get _displayName {
    final profileName = widget.profile.fullName.trim();
    final veterinarianName = _veterinarian?.name.trim() ?? '';
    final displayName = widget.profile.displayName.trim();

    if (profileName.isNotEmpty) return profileName;
    if (veterinarianName.isNotEmpty) return veterinarianName;
    if (displayName.isNotEmpty) return displayName;

    return 'Veterinarian';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadDashboard, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          const SizedBox(
            height: 500,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Center(child: Text(_errorMessage!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeSection(),
        const SizedBox(height: 20),

        _buildProfessionalProfile(),
        const SizedBox(height: 20),

        _buildHospitalSection(),
        const SizedBox(height: 24),

        _buildSectionHeading('Appointment Overview'),
        const SizedBox(height: 12),

        _buildSummaryCards(),
        const SizedBox(height: 24),

        _buildSectionHeading(
          "Today's Appointments",
          count: _todayAppointments.length,
        ),
        const SizedBox(height: 12),

        if (_todayAppointments.isEmpty)
          _buildEmptyState(
            'No appointments scheduled for today.',
            Icons.event_available_outlined,
          )
        else
          ..._todayAppointments.map(_buildAppointmentCard),

        const SizedBox(height: 24),

        _buildSectionHeading(
          'Upcoming Appointments',
          count: _upcomingAppointments.length,
        ),
        const SizedBox(height: 12),

        if (_upcomingAppointments.isEmpty)
          _buildEmptyState(
            'No upcoming appointments.',
            Icons.calendar_month_outlined,
          )
        else
          ..._upcomingAppointments.take(10).map(_buildAppointmentCard),

        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------
  // Welcome section
  // ---------------------------------------------------------

  Widget _buildWelcomeSection() {
    final imageUrl = _veterinarian?.profileImageUrl ?? widget.profile.photoUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.person, size: 38),
                    ),
                  )
                : const Icon(Icons.medical_services_outlined, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _displayName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Veterinarian'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Professional profile
  // ---------------------------------------------------------

  Widget _buildProfessionalProfile() {
    final vet = _veterinarian;

    return _buildInformationCard(
      title: 'Professional Profile',
      icon: Icons.person_outline,
      children: [
        _informationRow(Icons.person_outline, 'Full Name', _displayName),
        _informationRow(Icons.email_outlined, 'Email', widget.profile.email),
        _informationRow(
          Icons.medical_information_outlined,
          'Specialty',
          vet?.specialty ?? 'Not specified',
        ),
        _informationRow(
          Icons.school_outlined,
          'Qualifications',
          vet?.qualifications ?? 'Not specified',
        ),
        _informationRow(
          Icons.work_history_outlined,
          'Experience',
          vet?.experienceYears == null
              ? 'Not specified'
              : '${vet!.experienceYears} years',
        ),
        if (vet?.bio != null && vet!.bio!.trim().isNotEmpty)
          _informationRow(Icons.info_outline, 'About', vet.bio!),
      ],
    );
  }

  // ---------------------------------------------------------
  // Hospital information
  // ---------------------------------------------------------

  Widget _buildHospitalSection() {
    final hospital = _hospital;

    return _buildInformationCard(
      title: 'Hospital Information',
      icon: Icons.local_hospital_outlined,
      children: [
        _informationRow(
          Icons.business_outlined,
          'Hospital',
          hospital?.name ?? 'Hospital information unavailable',
        ),
        _informationRow(
          Icons.location_on_outlined,
          'Location',
          hospital?.location ?? 'Not available',
        ),
        _informationRow(
          Icons.phone_outlined,
          'Contact',
          hospital?.contact ?? 'Not available',
        ),
        _informationRow(
          Icons.access_time_outlined,
          'Operating Hours',
          hospital?.hours ?? 'Not available',
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Appointment statistics
  // ---------------------------------------------------------

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Today',
            value: '${_todayAppointments.length}',
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Pending',
            value: '$_pendingCount',
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Upcoming',
            value: '${_upcomingAppointments.length}',
            icon: Icons.event_available_outlined,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Appointment list
  // ---------------------------------------------------------

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: const Icon(Icons.pets_outlined)),
        title: Text(
          _formatDateTime(appointment.dateTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Pet ID: ${appointment.petId}\n'
            'Service ID: ${appointment.serviceId}',
          ),
        ),
        trailing: _StatusChip(status: appointment.status),
        isThreeLine: true,
      ),
    );
  }

  // ---------------------------------------------------------
  // Shared UI components
  // ---------------------------------------------------------

  Widget _buildInformationCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _informationRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, {int? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (count != null)
          Text('$count', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '$hour:$minute $period';
  }
}

// =============================================================
// Summary card
// =============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Appointment status
// =============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
