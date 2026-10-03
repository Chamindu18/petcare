import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Gets all active services for a hospital.
class GetServicesByHospital {
  const GetServicesByHospital(this._repository);

  final ServiceRepository _repository;

  // Get services through the repository.
  Future<List<Service>> call(String hospitalId) {
    return _repository.getServicesByHospital(hospitalId);
  }
}

/// Gets one service by its ID.
class GetServiceById {
  const GetServiceById(this._repository);

  final ServiceRepository _repository;

  // Get the selected service through the repository.
  Future<Service?> call(String serviceId) {
    return _repository.getServiceById(serviceId);
  }
}
