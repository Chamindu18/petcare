class Treatment {
  const Treatment({
    required this.treatmentId,
    required this.petId,
    required this.name,
    required this.status,
    required this.source,
    this.startDate,
    this.endDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String treatmentId;
  final String petId;

  /// Name or description of the treatment.
  final String name;

  /// Current treatment status.
  final String status;

  /// Indicates whether the record was owner-reported or veterinarian-confirmed.
  final String source;

  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
