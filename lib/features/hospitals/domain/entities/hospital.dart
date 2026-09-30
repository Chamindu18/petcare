/// Represents a hospital in the domain layer.
class Hospital {
  const Hospital({
    required this.hospitalId,
    required this.name,
    required this.location,
    required this.contact,
    required this.hours,
    required this.active,
  });

  final String hospitalId;
  final String name;
  final String location;
  final String contact;
  final String hours;
  final bool active;
}
