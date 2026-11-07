class AppointmentSlot {
  const AppointmentSlot({required this.startTime, required this.endTime});

  final DateTime startTime;
  final DateTime endTime;

  Duration get duration => endTime.difference(startTime);
}
