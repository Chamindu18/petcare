import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../appointments/domain/utils/appointment_date_classifier.dart';
import '../providers/staff_appointment_provider.dart';

/// Appointment management screen for an authenticated hospital staff member.
///
/// The hospital ID must come from the trusted staff assignment, not from
/// user-controlled input.
class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({
    super.key,
    required this.hospitalId,
    this.repository,
  });

  final String hospitalId;
  final AppointmentRepository? repository;

  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage> {
  late final StaffAppointmentProvider _provider;

  _AppointmentFilter _selectedFilter = _AppointmentFilter.all;
  _DateFilter _selectedDateFilter = _DateFilter.all;

  @override
  void initState() {
    super.initState();

    _provider = StaffAppointmentProvider(
      appointmentRepository:
          widget.repository ?? FirebaseAppointmentRepository(),
      assignedHospitalId: widget.hospitalId,
    );

    _provider.loadAppointments();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(
    Appointment appointment, {
    required bool confirm,
  }) async {
    if (!confirm) {
      final shouldReject = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Reject appointment?'),
            content: const Text(
              'Are you sure you want to reject this appointment? '
              'This action cannot be undone through the staff workflow.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );

      if (shouldReject != true || !mounted) {
        return;
      }
    }

    final success = confirm
        ? await _provider.confirmAppointment(appointment.appointmentId)
        : await _provider.rejectAppointment(appointment.appointmentId);

    if (!mounted) {
      return;
    }

    final message = success
        ? confirm
              ? 'Appointment confirmed successfully.'
              : 'Appointment rejected successfully.'
        : _provider.actionErrorMessage ??
              'Unable to update this appointment. Please try again.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

    if (!success) {
      _provider.clearErrors();
    }
  }

  /// Filters status and calendar period independently so staff can combine
  /// selections, for example Confirmed + Tomorrow.
  List<Appointment> _getFilteredAppointments(DateTime now) {
    return _provider.appointments
        .where((appointment) {
          if (!_matchesStatus(appointment, _selectedFilter)) return false;
          return _matchesDate(appointment, _selectedDateFilter, now);
        })
        .toList(growable: false);
  }

  bool _matchesStatus(Appointment appointment, _AppointmentFilter filter) {
    return filter == _AppointmentFilter.all ||
        appointment.status.trim().toLowerCase() == filter.status;
  }

  bool _matchesDate(Appointment appointment, _DateFilter filter, DateTime now) {
    if (filter == _DateFilter.all) return true;

    final category = AppointmentDateClassifier.classify(appointment, now: now);

    // Upcoming includes tomorrow as well as later future dates.
    if (filter == _DateFilter.upcoming) {
      return category == AppointmentDateCategory.tomorrow ||
          category == AppointmentDateCategory.upcoming;
    }

    return category == filter.category;
  }

  /// Counts a status within the currently selected calendar period.
  int _countForFilter(_AppointmentFilter filter, DateTime now) {
    return _provider.appointments.where((appointment) {
      return _matchesDate(appointment, _selectedDateFilter, now) &&
          _matchesStatus(appointment, filter);
    }).length;
  }

  /// Counts a period within the currently selected status filter.
  int _countForDateFilter(_DateFilter filter, DateTime now) {
    return _provider.appointments.where((appointment) {
      return _matchesStatus(appointment, _selectedFilter) &&
          _matchesDate(appointment, filter, now);
    }).length;
  }

  int _countToday(DateTime now) {
    return _provider.appointments.where((appointment) {
      return AppointmentDateClassifier.classify(appointment, now: now) ==
          AppointmentDateCategory.today;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.background,
      child: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final now = DateTime.now();
          final appointments = _getFilteredAppointments(now);

          if (_provider.isLoading && _provider.appointments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.errorMessage != null &&
              _provider.appointments.isEmpty) {
            return _LoadErrorState(
              message: _provider.errorMessage!,
              onRetry: _provider.loadAppointments,
            );
          }

          return RefreshIndicator(
            onRefresh: _provider.loadAppointments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              children: [
                _buildHeading(),
                const SizedBox(height: 20),
                _buildSummary(now),
                const SizedBox(height: 26),
                _buildFilterHeading(),
                const SizedBox(height: 12),
                _buildFilters(now),
                const SizedBox(height: 18),
                _buildDateFilterHeading(),
                const SizedBox(height: 12),
                _buildDateFilters(now),
                if (_provider.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(message: _provider.errorMessage!),
                ],
                const SizedBox(height: 20),
                if (appointments.isEmpty)
                  _EmptyAppointmentsState(
                    filter: _selectedFilter,
                    dateFilter: _selectedDateFilter,
                  )
                else
                  ...appointments.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StaffAppointmentCard(
                        appointment: appointment,
                        category: AppointmentDateClassifier.classify(
                          appointment,
                          now: now,
                        ),
                        isProcessing: _provider.isProcessing(
                          appointment.appointmentId,
                        ),
                        onConfirm: () =>
                            _handleDecision(appointment, confirm: true),
                        onReject: () =>
                            _handleDecision(appointment, confirm: false),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hospital Appointments',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Review and manage appointments for your assigned hospital.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.deepBrown.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.local_hospital_outlined,
              size: 17,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Hospital ID: ${widget.hospitalId}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(DateTime now) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            title: 'Today',
            value: _countToday(now),
            icon: Icons.today_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _SummaryMetric(
            title: 'Pending',
            value: _countForFilter(_AppointmentFilter.pending, now),
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _SummaryMetric(
            title: 'Confirmed',
            value: _countForFilter(_AppointmentFilter.confirmed, now),
            icon: Icons.event_available_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeading() {
    return Text(
      'Filter appointments',
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildFilters(DateTime now) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _AppointmentFilter.values.map((filter) {
          final selected = _selectedFilter == filter;
          final count = _countForFilter(filter, now);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${filter.label} ($count)'),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.16),
              backgroundColor: AppTheme.white,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.deepBrown,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.6)
                    : AppTheme.secondary.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFilterHeading() {
    return Text(
      'Filter by date',
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildDateFilters(DateTime now) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DateFilter.values.map((filter) {
          final selected = _selectedDateFilter == filter;
          final count = _countForDateFilter(filter, now);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${filter.label} ($count)'),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedDateFilter = filter);
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.16),
              backgroundColor: AppTheme.white,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.deepBrown,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.6)
                    : AppTheme.secondary.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _DateFilter {
  all('All dates', null),
  overdue('Overdue', AppointmentDateCategory.overdue),
  today('Today', AppointmentDateCategory.today),
  tomorrow('Tomorrow', AppointmentDateCategory.tomorrow),
  upcoming('Upcoming', AppointmentDateCategory.upcoming),
  history('History', AppointmentDateCategory.history);

  const _DateFilter(this.label, this.category);

  final String label;
  final AppointmentDateCategory? category;
}

enum _AppointmentFilter {
  all('All', ''),
  pending('Pending', 'pending'),
  confirmed('Confirmed', 'confirmed'),
  rejected('Rejected', 'rejected'),
  cancelled('Cancelled', 'cancelled');

  const _AppointmentFilter(this.label, this.status);

  final String label;
  final String status;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppTheme.primary),
          const SizedBox(height: 9),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.deepBrown.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAppointmentCard extends StatelessWidget {
  const _StaffAppointmentCard({
    required this.appointment,
    required this.category,
    required this.isProcessing,
    required this.onConfirm,
    required this.onReject,
  });

  final Appointment appointment;
  final AppointmentDateCategory category;
  final bool isProcessing;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = appointment.status.trim().toLowerCase() == 'pending';

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Appointment #${appointment.appointmentId.length > 8 ? appointment.appointmentId.substring(0, 8) : appointment.appointmentId}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _AppointmentStatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 10),
            _AppointmentDateLabel(category: category),
            const SizedBox(height: 16),
            _AppointmentInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(appointment.dateTime),
            ),
            const SizedBox(height: 10),
            _AppointmentInfoRow(
              icon: Icons.access_time_outlined,
              label: 'Time',
              value: _formatTime(appointment.dateTime),
            ),
            const SizedBox(height: 10),
            _AppointmentInfoRow(
              icon: Icons.pets_outlined,
              label: 'Pet ID',
              value: appointment.petId,
            ),
            const SizedBox(height: 10),
            _AppointmentInfoRow(
              icon: Icons.person_outline,
              label: 'Veterinarian ID',
              value: appointment.vetId,
            ),
            if (appointment.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _AppointmentInfoRow(
                icon: Icons.notes_outlined,
                label: 'Reason',
                value: appointment.reason,
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Confirm'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

/// Visual calendar grouping is separate from the persisted status.
class _AppointmentDateLabel extends StatelessWidget {
  const _AppointmentDateLabel({required this.category});

  final AppointmentDateCategory category;

  @override
  Widget build(BuildContext context) {
    final label = switch (category) {
      AppointmentDateCategory.overdue => 'Overdue',
      AppointmentDateCategory.today => 'Today',
      AppointmentDateCategory.tomorrow => 'Tomorrow',
      AppointmentDateCategory.upcoming => 'Upcoming',
      AppointmentDateCategory.history => 'History',
    };

    final color = category == AppointmentDateCategory.overdue
        ? Colors.deepOrange.shade800
        : AppTheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _AppointmentStatusChip extends StatelessWidget {
  const _AppointmentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    final Color color = switch (normalizedStatus) {
      'pending' => Colors.orange.shade800,
      'confirmed' => Colors.green.shade700,
      'rejected' || 'cancelled' => AppTheme.primary,
      _ => AppTheme.deepBrown,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AppointmentInfoRow extends StatelessWidget {
  const _AppointmentInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppTheme.deepBrown),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAppointmentsState extends StatelessWidget {
  const _EmptyAppointmentsState({
    required this.filter,
    required this.dateFilter,
  });

  final _AppointmentFilter filter;
  final _DateFilter dateFilter;

  @override
  Widget build(BuildContext context) {
    final message = dateFilter != _DateFilter.all
        ? 'No appointments match the selected date and status filters.'
        : filter == _AppointmentFilter.all
        ? 'Appointments for your hospital will appear here.'
        : 'There are no ${filter.label.toLowerCase()} appointments.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 58,
            color: AppTheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ),
        ],
      ),
    );
  }
}
