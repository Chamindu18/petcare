/// Represents a veterinary service offered by a hospital.
class Service {
  const Service({
    required this.serviceId,
    required this.hospitalId,
    required this.name,
    required this.description,
    this.duration,
    required this.active,
  });

  final String serviceId;
  final String hospitalId;
  final String name;
  final String description;
  final int? duration;
  final bool active;
}
