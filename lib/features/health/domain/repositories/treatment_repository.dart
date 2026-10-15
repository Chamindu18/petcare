import '../entities/treatment.dart';

abstract interface class TreatmentRepository {
  Future<Treatment> createTreatment(Treatment treatment);

  Future<List<Treatment>> getTreatments(String petId);

  Future<Treatment?> getTreatmentById(String petId, String treatmentId);

  Future<void> updateTreatment(Treatment treatment);

  Future<void> deleteTreatment(String petId, String treatmentId);
}
