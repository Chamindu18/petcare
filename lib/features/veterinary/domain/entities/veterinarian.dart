/// Represents a veterinarian working at a hospital.
class Veterinarian {
  const Veterinarian({
    required this.vetId,
    required this.hospitalId,
    required this.name,
    this.specialty,
    required this.active,
  });

  final String vetId;
  final String hospitalId;
  final String name;
  final String? specialty;
  final bool active;
}
