import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/appointment_slot.dart';

/// Displays only the periods that contain starts within the hospital's hours.
/// Availability is supplied by the repository; this widget never infers it.
class AppointmentSlotPicker extends StatefulWidget {
  const AppointmentSlotPicker({
    required this.slots,
    required this.availableStarts,
    required this.now,
    required this.selectedStart,
    required this.onSelected,
    super.key,
  });

  final List<AppointmentSlot> slots;
  final Set<DateTime> availableStarts;
  final DateTime now;
  final DateTime? selectedStart;
  final ValueChanged<AppointmentSlot> onSelected;

  @override
  State<AppointmentSlotPicker> createState() => _AppointmentSlotPickerState();
}

enum _Period { morning, afternoon, evening }

extension on _Period {
  String get label => switch (this) {
    _Period.morning => 'Morning',
    _Period.afternoon => 'Afternoon',
    _Period.evening => 'Evening',
  };
}

_Period _periodFor(DateTime start) => switch (start.hour) {
  < 12 => _Period.morning,
  < 17 => _Period.afternoon,
  _ => _Period.evening,
};

class _AppointmentSlotPickerState extends State<AppointmentSlotPicker> {
  _Period? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final groups = <_Period, List<AppointmentSlot>>{};
    for (final slot in widget.slots) {
      groups.putIfAbsent(_periodFor(slot.startTime), () => []).add(slot);
    }
    final periods = _Period.values.where(groups.containsKey).toList();
    if (periods.isEmpty) return const SizedBox.shrink();

    final selectedPeriod = periods.contains(_selectedPeriod)
        ? _selectedPeriod!
        : periods.firstWhere(
            (period) => groups[period]!.any(
              (slot) =>
                  widget.availableStarts.contains(slot.startTime) &&
                  slot.startTime.isAfter(widget.now),
            ),
            orElse: () => periods.first,
          );
    final visibleSlots = groups[selectedPeriod]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment times',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final period in periods)
                ChoiceChip(
                  label: Text(period.label),
                  selected: period == selectedPeriod,
                  onSelected: (_) => setState(() => _selectedPeriod = period),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.white,
                  labelStyle: TextStyle(
                    color: period == selectedPeriod
                        ? AppTheme.white
                        : AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: period == selectedPeriod
                        ? AppTheme.primary
                        : AppTheme.secondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 480
                ? 4
                : constraints.maxWidth >= 320
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 64,
              ),
              itemCount: visibleSlots.length,
              itemBuilder: (context, index) {
                final slot = visibleSlots[index];
                final past = !slot.startTime.isAfter(widget.now);
                final available =
                    !past && widget.availableStarts.contains(slot.startTime);
                final selected =
                    available && widget.selectedStart == slot.startTime;
                final state = past
                    ? 'Past'
                    : selected
                    ? 'Selected'
                    : available
                    ? 'Available'
                    : 'Booked';
                final foreground = selected
                    ? AppTheme.white
                    : available
                    ? AppTheme.espresso
                    : AppTheme.deepBrown.withValues(alpha: 0.65);
                return Semantics(
                  button: true,
                  enabled: available,
                  selected: selected,
                  label:
                      '${TimeOfDay.fromDateTime(slot.startTime).format(context)}, $state',
                  child: Material(
                    color: selected
                        ? AppTheme.primary
                        : available
                        ? AppTheme.white
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: available ? () => widget.onSelected(slot) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : available
                                ? AppTheme.secondary
                                : AppTheme.deepBrown.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              TimeOfDay.fromDateTime(slot.startTime)
                                  .format(context),
                              style: TextStyle(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state,
                              style: TextStyle(color: foreground, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
