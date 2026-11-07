import '../entities/veterinarian.dart';

abstract interface class VeterinarianAssignmentRepository {
  Future<Veterinarian?> getCurrentAssignment();
}
