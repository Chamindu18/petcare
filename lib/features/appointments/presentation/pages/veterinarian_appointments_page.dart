import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_appointment_repository.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';

enum _AppointmentFilter {
  all('All'),
  today('Today'),
  pending('Pending'),
  upcoming('Upcoming');

  const _AppointmentFilter(this.label);

  final String label;
}

class VeterinarianAppointmentsPage extends StatefulWidget {
  const VeterinarianAppointmentsPage({
    super.key,
    required this.vetId,
    required this.hospitalId,
  });

  final String vetId;
  final String hospitalId;

  @override
  State<VeterinarianAppointmentsPage> createState() =>
      _VeterinarianAppointmentsPageState();
}

class _VeterinarianAppointmentsPageState
    extends State<VeterinarianAppointmentsPage> {
  late final GetAppointmentsByVeterinarian _getAppointments;

  List<Appointment> _appointments = [];
  _AppointmentFilter _selectedFilter = _AppointmentFilter.all;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _getAppointments(
        vetId: widget.vetId,
        hospitalId: widget.hospitalId,
      );

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Veterinarian appointments error: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load appointments. Please try again.';
        _isLoading = false;
      });
    }
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isTerminal(Appointment appointment) {
    final status = appointment.status.toLowerCase();
    return status == 'cancelled' || status == 'rejected';
  }

  List<Appointment> get _filteredAppointments {
    final now = DateTime.now();

    return _appointments.where((appointment) {
      switch (_selectedFilter) {
        case _AppointmentFilter.all:
          return true;

        case _AppointmentFilter.today:
          return _sameDay(appointment.dateTime, now) &&
              !_isTerminal(appointment);

        case _AppointmentFilter.pending:
          return appointment.status.toLowerCase() == 'pending';

        case _AppointmentFilter.upcoming:
          return appointment.dateTime.isAfter(now) &&
              !_sameDay(appointment.dateTime, now) &&
              !_isTerminal(appointment);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _filteredAppointments;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.espresso,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh appointments',
            onPressed: _isLoading ? null : _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildContent(appointments)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: _AppointmentFilter.values.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: selected,
              selectedColor: AppTheme.secondary,
              backgroundColor: AppTheme.white,
              labelStyle: TextStyle(
                color: AppTheme.espresso,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? AppTheme.primary : AppTheme.secondary,
              ),
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(List<Appointment> appointments) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return _messageState(
        icon: Icons.cloud_off_rounded,
        message: _errorMessage!,
        action: TextButton.icon(
          onPressed: _loadAppointments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }

    if (appointments.isEmpty) {
      return _messageState(
        icon: Icons.event_available_outlined,
        message:
            'No ${_selectedFilter.label.toLowerCase()} appointments found.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _appointmentCard(appointments[index]);
        },
      ),
    );
  }

  Widget _appointmentCard(Appointment appointment) {
    final date = appointment.dateTime;
    final time = TimeOfDay.fromDateTime(date).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppTheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment #${_shortId(appointment.appointmentId)}',
                  style: const TextStyle(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year} · $time',
                  style: const TextStyle(
                    color: AppTheme.deepBrown,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  appointment.reason.isEmpty
                      ? 'No reason provided'
                      : appointment.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.deepBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(appointment.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final color = switch (normalized) {
      'confirmed' || 'completed' => AppTheme.success,
      'pending' => AppTheme.warning,
      'cancelled' || 'rejected' => AppTheme.error,
      _ => AppTheme.information,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.secondary),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.deepBrown, fontSize: 14),
            ),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    return id.length <= 7 ? id.toUpperCase() : id.substring(0, 7).toUpperCase();
  }
}
