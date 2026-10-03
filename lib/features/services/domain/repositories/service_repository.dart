import '../entities/service.dart';

///  how the application accesses hospital services.
abstract interface class ServiceRepository {
  // Get active services for a specific hospital.
  Future<List<Service>> getServicesByHospital(String hospitalId);

  // Get one service by its ID.
  Future<Service?> getServiceById(String serviceId);
}
