import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app/theme/app_theme.dart';
import 'package:petcare/features/appointments/domain/entities/appointment_slot.dart';
import 'package:petcare/features/appointments/presentation/widgets/appointment_slot_picker.dart';

void main() {
  testWidgets('shows only periods within hours and distinguishes slot states', (
    tester,
  ) async {
    final day = DateTime(2026, 11, 20);
    AppointmentSlot slot(int hour, int minute) {
      final start = DateTime(day.year, day.month, day.day, hour, minute);
      return AppointmentSlot(
        startTime: start,
        endTime: start.add(const Duration(minutes: 15)),
      );
    }

    final slots = [slot(11, 45), slot(12, 0), slot(12, 15), slot(17, 0)];
    AppointmentSlot? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AppointmentSlotPicker(
              slots: slots,
              availableStarts: {slots[0].startTime, slots[2].startTime},
              now: DateTime(2026, 11, 20, 11, 50),
              selectedStart: null,
              onSelected: (slot) => selected = slot,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Past'), findsNothing);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    await tester.tap(find.text('Available'));
    expect(selected?.startTime, slots[2].startTime);
    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();
    expect(find.text('Past'), findsOneWidget);
    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();
    expect(find.text('Booked'), findsOneWidget);
  });
}
