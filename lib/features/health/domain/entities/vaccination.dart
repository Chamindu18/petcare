class Vaccination {
  const Vaccination({
    required this.vaccinationId,
    required this.petId,
    required this.name,
    required this.dateGiven,
    this.nextDueDate,
    this.providerId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String vaccinationId;
  final String petId;

  /// Name of the vaccine actually administered.
  final String name;

  /// Date the vaccine was administered.
  final DateTime dateGiven;

  /// Next scheduled vaccination date, when applicable.
  final DateTime? nextDueDate;

  /// Veterinary/provider reference, when available.
  final String? providerId;

  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}