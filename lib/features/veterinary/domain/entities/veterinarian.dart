/// Represents a veterinarian working at one hospital.
class Veterinarian {
  const Veterinarian({
    required this.vetId,
    required this.hospitalId,
    required this.name,
    this.profileImageUrl,
    this.specialty,
    this.qualifications,
    this.experienceYears,
    this.bio,
    required this.active,
  });

  final String vetId;

  /// Each veterinarian belongs to exactly one hospital.
  final String hospitalId;

  final String name;
  final String? profileImageUrl;
  final String? specialty;
  final String? qualifications;
  final int? experienceYears;
  final String? bio;
  final bool active;
}
