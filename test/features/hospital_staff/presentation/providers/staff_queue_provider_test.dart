import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/appointments/domain/entities/appointment.dart';
import 'package:petcare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:petcare/features/queue/domain/entities/queue.dart';
import 'package:petcare/features/queue/domain/repositories/queue_repository.dart';
import 'package:petcare/features/hospital_staff/presentation/providers/staff_queue_provider.dart';
import 'package:petcare/features/hospital_staff/presentation/pages/staff_queue_page.dart';

final now = DateTime.utc(2026, 11, 4, 10);
Appointment appointment({
  String id = 'a',
  String hospital = 'h',
  String status = 'confirmed',
  String? queueId,
  DateTime? date,
}) => Appointment(
  appointmentId: id,
  ownerId: 'owner',
  petId: 'pet',
  hospitalId: hospital,
  serviceId: 'service',
  vetId: 'vet',
  dateTime: date ?? now,
  reason: 'Checkup',
  status: status,
  queueId: queueId,
  createdAt: now,
);
Queue entry({
  String id = 'q',
  int number = 1,
  String status = 'waiting',
  String hospital = 'h',
}) => Queue(
  queueId: id,
  appointmentId: 'a',
  hospitalId: hospital,
  ownerId: 'owner',
  petId: 'pet',
  queueNumber: number,
  currentServing: 0,
  position: 1,
  status: status,
  updatedAt: now,
);

class Appointments implements AppointmentRepository {
  List<Appointment> values = [];
  int reads = 0;
  Object? error;
  String? hospital;
  Completer<void>? hold;
  @override
  Future<List<Appointment>> getAppointmentsByHospital(String hospitalId) async {
    reads++;
    hospital = hospitalId;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return values;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Queues implements StaffQueueCommandRepository {
  List<Queue> values = [];
  Object? error;
  Object? commandError;
  Completer<void>? hold;
  int reads = 0, checks = 0, transitions = 0;
  String? hospital;
  DateTime? date;
  StaffQueueStatus? expected, next;
  @override
  Future<List<Queue>> getHospitalQueue({
    required String hospitalId,
    required DateTime date,
  }) async {
    reads++;
    hospital = hospitalId;
    this.date = date;
    if (error != null) throw error!;
    return values;
  }

  @override
  Future<Queue> checkInAppointment({
    required String appointmentId,
    required String hospitalId,
  }) async {
    checks++;
    hospital = hospitalId;
    if (hold != null) await hold!.future;
    if (commandError != null) throw commandError!;
    values = [entry()];
    return values.first;
  }

  @override
  Future<Queue> transitionStatus({
    required String queueId,
    required String hospitalId,
    required StaffQueueStatus expectedStatus,
    required StaffQueueStatus nextStatus,
  }) async {
    transitions++;
    hospital = hospitalId;
    expected = expectedStatus;
    next = nextStatus;
    if (commandError != null) throw commandError!;
    values = [entry(status: nextStatus.value)];
    return values.first;
  }
}

void main() {
  late Appointments appointments;
  late Queues queues;
  late StaffQueueProvider provider;
  setUp(() {
    appointments = Appointments();
    queues = Queues();
    provider = StaffQueueProvider(
      appointmentRepository: appointments,
      queueRepository: queues,
      assignedHospitalId: 'h',
      now: () => now,
    );
  });
  tearDown(() => provider.dispose());

  test(
    'filters eligible appointments and orders only assigned hospital queue',
    () async {
      appointments.values = [
        appointment(),
        appointment(id: 'other', hospital: 'other'),
        appointment(id: 'pending', status: 'pending'),
        appointment(id: 'linked', queueId: 'old'),
        appointment(
          id: 'yesterday',
          date: now.subtract(const Duration(days: 1)),
        ),
      ];
      queues.values = [
        entry(id: 'three', number: 3),
        entry(id: 'two', number: 2),
        entry(hospital: 'other'),
      ];
      await provider.refresh();
      expect(provider.entries.map((q) => q.queueNumber), [2, 3]);
      expect(provider.eligibleAppointments, isEmpty); // a is already in queue
      expect(appointments.hospital, 'h');
      expect(queues.hospital, 'h');
    },
  );
  test(
    'Colombo calendar date and eligibility agree across UTC midnight',
    () async {
      provider.dispose();
      final instant = DateTime.utc(2026, 11, 3, 20);
      provider = StaffQueueProvider(
        appointmentRepository: appointments,
        queueRepository: queues,
        assignedHospitalId: 'h',
        now: () => instant,
      );
      appointments.values = [appointment(date: DateTime.utc(2026, 11, 4, 2))];
      await provider.refresh();
      expect(queues.date!.day, 4);
      expect(provider.eligibleAppointments, hasLength(1));
    },
  );
  test('check-in blocks duplicates and refreshes both datasets', () async {
    appointments.values = [appointment()];
    await provider.refresh();
    queues.hold = Completer<void>();
    final pending = provider.checkIn(provider.eligibleAppointments.single);
    expect(provider.isProcessing, isTrue);
    expect(await provider.checkIn(appointment()), isFalse);
    await provider.refresh();
    expect(appointments.reads, 1);
    queues.hold!.complete();
    expect(await pending, isTrue);
    expect(queues.checks, 1);
    expect(appointments.reads, 2);
    expect(queues.reads, 2);
    expect(provider.eligibleAppointments, isEmpty);
    expect(provider.isProcessing, isFalse);
  });
  test('advances through called and consultation before completion', () async {
    queues.values = [entry()];
    await provider.refresh();
    expect(await provider.advance(provider.entries.single), isTrue);
    expect(queues.expected, StaffQueueStatus.waiting);
    expect(queues.next, StaffQueueStatus.called);
    expect(await provider.advance(provider.entries.single), isTrue);
    expect(queues.expected, StaffQueueStatus.called);
    expect(queues.next, StaffQueueStatus.inConsultation);
    expect(await provider.advance(provider.entries.single), isTrue);
    expect(queues.next, StaffQueueStatus.completed);
    expect(await provider.advance(provider.entries.single), isFalse);
    expect(queues.transitions, 3);
  });
  test(
    'stale transaction refreshes and displays actionable conflict',
    () async {
      queues.values = [entry()];
      await provider.refresh();
      queues.commandError = StateError('status has changed');
      expect(await provider.advance(provider.entries.single), isFalse);
      expect(provider.actionMessage, contains('has changed'));
      expect(queues.reads, 2);
      expect(provider.canAct, isTrue);
    },
  );
  test(
    'permission errors clear sensitive data and retry can recover',
    () async {
      queues.values = [entry()];
      await provider.refresh();
      queues.error = FirebaseException(
        plugin: 'test',
        code: 'permission-denied',
      );
      await provider.refresh();
      expect(provider.errorMessage, contains('access denied'));
      expect(provider.entries, isEmpty);
      expect(provider.canAct, isFalse);
      queues.error = null;
      await provider.refresh();
      expect(provider.canAct, isTrue);
    },
  );
  test('an open queue cannot mutate a previous hospital day', () async {
    provider.dispose();
    var clock = now;
    provider = StaffQueueProvider(
      appointmentRepository: appointments,
      queueRepository: queues,
      assignedHospitalId: 'h',
      now: () => clock,
    );
    queues.values = [entry()];
    await provider.refresh();
    clock = clock.add(const Duration(days: 1));
    expect(await provider.advance(provider.entries.single), isFalse);
    expect(queues.transitions, 0);
    expect(provider.actionMessage, contains('has changed'));
    expect(queues.date!.day, 5);
  });

  test('foreign or ineligible check-in never reaches the repository', () async {
    appointments.values = [appointment()];
    await provider.refresh();
    expect(await provider.checkIn(appointment(hospital: 'other')), isFalse);
    expect(queues.checks, 0);
  });
  test('network errors and disposal during reads are safe', () async {
    appointments.error = Exception('offline');
    await provider.refresh();
    expect(provider.errorMessage, contains('Unable to load'));
    appointments.error = null;
    appointments.hold = Completer<void>();
    final pending = provider.refresh();
    provider.dispose();
    appointments.hold!.complete();
    await pending;
    // Avoid disposing the same notifier twice in teardown.
    provider = StaffQueueProvider(
      appointmentRepository: appointments,
      queueRepository: queues,
      assignedHospitalId: 'h',
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StaffQueuePage(
          hospitalId: 'h',
          appointmentRepository: appointments,
          queueRepository: queues,
        ),
      ),
    ),
  );

  testWidgets('loading, empty, permission denied and retry states', (
    tester,
  ) async {
    appointments.hold = Completer<void>();
    await pump(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    appointments.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('No patients checked in today.'), findsOneWidget);
    queues.error = FirebaseException(plugin: 'test', code: 'permission-denied');
    await tester.tap(find.byTooltip('Refresh queue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hospital access denied'), findsOneWidget);
    queues.error = null;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.text('No patients checked in today.'), findsOneWidget);
  });
  testWidgets(
    'check-in disables actions while pending and renders next valid action',
    (tester) async {
      appointments.values = [appointment(date: DateTime.now())];
      await pump(tester);
      await tester.pumpAndSettle();
      queues.hold = Completer<void>();
      await tester.tap(find.text('Check In'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check In'))
            .onPressed,
        isNull,
      );
      queues.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Check In'), findsNothing);
      await tester.ensureVisible(find.text('Call Patient'));
      await tester.tap(find.text('Call Patient'));
      await tester.pumpAndSettle();
      expect(find.text('Called'), findsOneWidget);
      expect(find.text('Start Consultation'), findsOneWidget);
      await tester.ensureVisible(find.text('Start Consultation'));
      await tester.tap(find.text('Start Consultation'));
      await tester.pumpAndSettle();
      expect(find.text('Complete Consultation'), findsOneWidget);
      await tester.ensureVisible(find.text('Complete Consultation'));
      await tester.tap(find.text('Complete Consultation'));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Complete Consultation'), findsNothing);
    },
  );
  testWidgets('queue order, unknown status and narrow layout', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    queues.values = [
      entry(id: 'later', number: 2, status: 'unexpected'),
      entry(number: 1),
    ];
    await pump(tester);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Queue #1')).dy,
      lessThan(tester.getTopLeft(find.text('Queue #2')).dy),
    );
    expect(find.text('Unknown status: refresh required'), findsOneWidget);
    expect(find.text('Call Patient'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'conflict feedback refreshes queue and preserves valid next action',
    (tester) async {
      queues.values = [entry()];
      queues.commandError = StateError('status has changed');
      await pump(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Call Patient'));
      await tester.tap(find.text('Call Patient'));
      await tester.pumpAndSettle();
      expect(find.textContaining('has changed'), findsOneWidget);
      expect(queues.reads, 2);
      expect(find.text('Call Patient'), findsOneWidget);
      expect(find.text('Complete Consultation'), findsNothing);
    },
  );

  testWidgets('generic load error offers retry and returning to tab reloads', (
    tester,
  ) async {
    queues.error = Exception('offline');
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load'), findsOneWidget);
    queues.error = null;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.text('No patients checked in today.'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaffQueuePage(
            hospitalId: 'h',
            appointmentRepository: appointments,
            queueRepository: queues,
            isActive: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final previousReads = queues.reads;
    await pump(tester);
    await tester.pumpAndSettle();
    expect(queues.reads, previousReads + 1);
  });
}
