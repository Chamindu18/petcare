import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/veterinarian_availability.dart';
import '../../domain/repositories/appointment_availability_repository.dart';
import '../models/appointment_model.dart';

/// Reads appointment data required to calculate veterinarian availability.
class FirebaseAppointmentAvailabilityRepository
    implements AppointmentAvailabilityRepository {
  FirebaseAppointmentAvailabilityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointmentsCollection =>
      _firestore.collection('appointment_schedule');

  CollectionReference<Map<String, dynamic>> get _servicesCollection =>
      _firestore.collection('services');

  @override
  Future<VeterinarianAvailability> getAvailabilityForVeterinarian({
    required String veterinarianId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final previousDayStart = dayStart.subtract(const Duration(days: 1));

    final snapshot = await _appointmentsCollection
        .where('vetId', isEqualTo: veterinarianId)
        .get();

    final appointments = <Appointment>[];
    final appointmentDurations = <String, Duration>{};

    for (final document in snapshot.docs) {
      final data = document.data();
      final appointment = AppointmentModel.fromMap({
        ...data,
        'appointmentId': document.id,
        'ownerId': '',
        'petId': '',
        'reason': '',
        'createdAt': data['dateTime'],
      });

      final startsOnSelectedDay =
          !appointment.dateTime.isBefore(dayStart) &&
          appointment.dateTime.isBefore(dayEnd);
      final startsOnPreviousDay =
          !appointment.dateTime.isBefore(previousDayStart) &&
          appointment.dateTime.isBefore(dayStart);

      if (!startsOnSelectedDay && !startsOnPreviousDay) {
        continue;
      }

      final serviceDocument = await _servicesCollection
          .doc(appointment.serviceId)
          .get();

      final rawDuration =
          data['durationMinutes'] ?? serviceDocument.data()?['duration'];
      final occupiedDuration = rawDuration is num && rawDuration > 0
          ? Duration(minutes: rawDuration.toInt())
          : null;

      // A previous-day appointment can only affect the selected day when it
      // provably crosses midnight. Unknown legacy durations cannot be proven
      // to cross; the trusted reservation still rejects any real conflict.
      if (startsOnPreviousDay &&
          (occupiedDuration == null ||
              !appointment.dateTime.add(occupiedDuration).isAfter(dayStart))) {
        continue;
      }

      if (occupiedDuration != null) {
        appointmentDurations[appointment.appointmentId] = occupiedDuration;
      }

      appointments.add(appointment);
    }

    return VeterinarianAvailability(
      appointments: appointments,
      appointmentDurations: appointmentDurations,
    );
  }
}
