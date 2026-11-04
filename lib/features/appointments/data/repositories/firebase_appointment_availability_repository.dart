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

    final snapshot = await _appointmentsCollection
        .where('vetId', isEqualTo: veterinarianId)
        .get();

    final appointments = <Appointment>[];
    final appointmentDurations = <String, Duration>{};

    for (final document in snapshot.docs) {
      final appointment = AppointmentModel.fromMap({
        ...document.data(),
        'appointmentId': document.id,
        'ownerId': '',
        'petId': '',
        'reason': '',
        'createdAt': document.data()['dateTime'],
      });

      // A service can cross midnight. Include the preceding day's starts so
      // the slot generator can compare their full intervals with this day.
      if (!_isOnDate(
        appointment.dateTime,
        dayStart.subtract(const Duration(days: 1)),
        dayEnd,
      )) {
        continue;
      }

      final serviceDocument = await _servicesCollection
          .doc(appointment.serviceId)
          .get();

      final serviceData = serviceDocument.data();

      final duration =
          document.data()['durationMinutes'] ?? serviceData?['duration'];

      if (duration is num && duration > 0) {
        appointmentDurations[appointment.appointmentId] = Duration(
          minutes: duration.toInt(),
        );
      }
      final occupiedDuration = appointmentDurations[appointment.appointmentId];
      if (occupiedDuration == null ||
          appointment.dateTime.add(occupiedDuration).isAfter(dayStart)) {
        appointments.add(appointment);
      }
    }

    return VeterinarianAvailability(
      appointments: appointments,
      appointmentDurations: appointmentDurations,
    );
  }

  bool _isOnDate(
    DateTime appointmentDateTime,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    return !appointmentDateTime.isBefore(dayStart) &&
        appointmentDateTime.isBefore(dayEnd);
  }
}
