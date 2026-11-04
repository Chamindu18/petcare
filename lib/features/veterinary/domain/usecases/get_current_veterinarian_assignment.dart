import '../entities/veterinarian.dart';
import '../repositories/veterinarian_assignment_repository.dart';

class GetCurrentVeterinarianAssignment {
  const GetCurrentVeterinarianAssignment(this.repository);
  final VeterinarianAssignmentRepository repository;
  Future<Veterinarian?> call() => repository.getCurrentAssignment();
}
