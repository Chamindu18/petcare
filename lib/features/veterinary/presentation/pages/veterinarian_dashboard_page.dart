import 'package:flutter/material.dart';

import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';
import '../../../profile/domain/entities/user_profile.dart';

class VeterinarianDashboardPage extends StatefulWidget {
  const VeterinarianDashboardPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<VeterinarianDashboardPage> createState() =>
      _VeterinarianDashboardPageState();
}

class _VeterinarianDashboardPageState extends State<VeterinarianDashboardPage> {
  late final GetAppointmentsByVeterinarian _getAppointments;

  List<Appointment> _appointments = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _getAppointments = GetAppointmentsByVeterinarian(
      FirebaseAppointmentRepository(),
    );

    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final vetId = widget.profile.vetId;
    final hospitalId = widget.profile.hospitalId;

    if (vetId == null || hospitalId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Your veterinarian account is missing a veterinarian '
            'or hospital assignment.';
      });
      return;
    }

    try {
      final appointments = await _getAppointments(
        vetId: vetId,
        hospitalId: hospitalId,
      );

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your appointments. Please try again.';
      });
    }
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();

    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool _isUpcoming(Appointment appointment) {
    final now = DateTime.now();

    return appointment.dateTime.isAfter(now) &&
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veterinarian Dashboard')),
      body: RefreshIndicator(onRefresh: _loadAppointments, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          SizedBox(
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
          Center(child: Text(_errorMessage!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadAppointments();
              },
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final today = _todayAppointments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeSection(),
        const SizedBox(height: 20),
        _buildSummaryCards(),
        const SizedBox(height: 24),
        _buildSectionTitle('Today\'s Appointments', '${today.length}'),
        const SizedBox(height: 12),
        if (today.isEmpty)
          _buildEmptyState('No appointments scheduled for today.')
        else
          ...today.map(_buildAppointmentCard),
        const SizedBox(height: 24),
        _buildSectionTitle('Upcoming', '${_upcomingAppointments.length}'),
        const SizedBox(height: 12),
        if (_upcomingAppointments.isEmpty)
          _buildEmptyState('No upcoming appointments.')
        else
          ..._upcomingAppointments.take(10).map(_buildAppointmentCard),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final name = widget.profile.fullName.trim().isEmpty
        ? widget.profile.displayName
        : widget.profile.fullName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome,', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('Veterinarian', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

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
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Pending',
            value: '$_pendingCount',
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: 12),
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

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(count, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_formatTime(appointment.dateTime).split(':').first),
        ),
        title: Text(
          _formatTime(appointment.dateTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Pet: ${appointment.petId}\n'
            'Service: ${appointment.serviceId}',
          ),
        ),
        trailing: _StatusChip(status: appointment.status),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

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
