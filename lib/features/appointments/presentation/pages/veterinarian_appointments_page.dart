import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/utils/appointment_date_classifier.dart';
import '../widgets/veterinarian_appointment_card.dart';

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
    required this.appointments,
    required this.serviceNameFor,
    required this.isLoading,
    required this.onRefresh,
    this.errorMessage,
    this.actionErrorMessage,
    this.onOpenDetails,
    this.embedded = false,
  });

  final List<Appointment> appointments;
  final String? Function(String serviceId) serviceNameFor;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String? errorMessage;
  final String? actionErrorMessage;
  final ValueChanged<Appointment>? onOpenDetails;
  final bool embedded;

  @override
  State<VeterinarianAppointmentsPage> createState() =>
      _VeterinarianAppointmentsPageState();
}

class _VeterinarianAppointmentsPageState
    extends State<VeterinarianAppointmentsPage> {
  _AppointmentFilter _selectedFilter = _AppointmentFilter.all;
  DateTime? _now;

  DateTime get _referenceNow => _now ?? DateTime.now();

  List<Appointment> get _filteredAppointments {
    return widget.appointments.where((appointment) {
      final category = AppointmentDateClassifier.classify(
        appointment,
        now: _referenceNow,
      );

      return switch (_selectedFilter) {
        _AppointmentFilter.all => true,
        _AppointmentFilter.today => category == AppointmentDateCategory.today,
        _AppointmentFilter.pending =>
          appointment.status.trim().toLowerCase() == 'pending',
        _AppointmentFilter.upcoming =>
          category == AppointmentDateCategory.tomorrow ||
              category == AppointmentDateCategory.upcoming,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildFilters(),
        if (widget.actionErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: _buildInlineMessage(widget.actionErrorMessage!),
          ),
        Expanded(child: _buildContent(_filteredAppointments)),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PetCareSecondaryAppBar(
        title: 'Appointments',
        actions: [
          IconButton(
            tooltip: 'Refresh appointments',
            onPressed: widget.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: content,
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
                setState(() {
                  _now = DateTime.now();
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(List<Appointment> appointments) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (widget.errorMessage != null) {
      return _messageState(
        icon: Icons.cloud_off_rounded,
        message: widget.errorMessage!,
        action: TextButton.icon(
          onPressed: _refresh,
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
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];

          return VeterinarianAppointmentCard(
            appointment: appointment,
            serviceName: widget.serviceNameFor(appointment.serviceId),
            onTap: widget.onOpenDetails == null
                ? null
                : () => widget.onOpenDetails!(appointment),
          );
        },
      ),
    );
  }

  Widget _buildInlineMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, fontSize: 12),
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

  Future<void> _refresh() async {
    setState(() => _now = DateTime.now());
    await widget.onRefresh();
  }
}
