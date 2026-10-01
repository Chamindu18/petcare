import '../entities/hospital.dart';
import '../repositories/hospital_repository.dart';

/// Gets all active hospitals.
class GetHospitals {
  const GetHospitals(this._repository);

  final HospitalRepository _repository;

  // Get hospitals through the repository.
  Future<List<Hospital>> call() {
    return _repository.getHospitals();
  }
}

/// Gets one hospital by its ID.
class GetHospitalById {
  const GetHospitalById(this._repository);

  final HospitalRepository _repository;

  // Get the selected hospital through the repository.
  Future<Hospital?> call(String hospitalId) {
    return _repository.getHospitalById(hospitalId);
  }
}
