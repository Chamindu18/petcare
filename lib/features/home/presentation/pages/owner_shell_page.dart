import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/cloudinary_config.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../health/data/repositories/firebase_health_measurement_repository.dart';
import '../../../health/data/repositories/firebase_medical_condition_repository.dart';
import '../../../health/data/repositories/firebase_treatment_repository.dart';
import '../../../health/data/repositories/firebase_vaccination_repository.dart';
import '../../../health/domain/usecases/create_health_measurement.dart';
import '../../../health/domain/usecases/create_medical_condition.dart';
import '../../../health/domain/usecases/create_treatment.dart';
import '../../../health/domain/usecases/create_vaccination.dart';
import '../../../health/domain/usecases/delete_health_measurement.dart';
import '../../../health/domain/usecases/delete_medical_condition.dart';
import '../../../health/domain/usecases/delete_treatment.dart';
import '../../../health/domain/usecases/delete_vaccination.dart';
import '../../../health/domain/usecases/get_health_measurements.dart';
import '../../../health/domain/usecases/get_medical_conditions.dart';
import '../../../health/domain/usecases/get_treatments.dart';
import '../../../health/domain/usecases/get_vaccinations.dart';
import '../../../health/domain/usecases/update_health_measurement.dart';
import '../../../health/domain/usecases/update_medical_condition.dart';
import '../../../health/domain/usecases/update_treatment.dart';
import '../../../health/domain/usecases/update_vaccination.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../pets/data/repositories/cloudinary_pet_image_repository.dart';
import '../../../pets/data/repositories/firebase_pet_repository.dart';
import '../../../pets/domain/usecases/create_pet.dart';
import '../../../pets/domain/usecases/delete_pet.dart';
import '../../../pets/domain/usecases/delete_pet_image.dart';
import '../../../pets/domain/usecases/get_pets.dart';
import '../../../pets/domain/usecases/update_pet.dart';
import '../../../pets/domain/usecases/upload_pet_image.dart';
import '../../../pets/presentation/pages/my_pets_page.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../ai_assistant/presentation/pages/ai_hub_page.dart';
import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';
import '../../../appointments/presentation/pages/my_appointments_page.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../services/data/repositories/firebase_service_repository.dart';
import '../../../veterinary/data/repositories/firebase_veterinarian_repository.dart';

import 'home_page.dart';

class OwnerShellPage extends StatefulWidget {
  const OwnerShellPage({
    super.key,
    this.petsController,
    this.healthController,
    this.appointmentProvider,
    this.auth,
    this.notificationRepository,
    this.profileRepository,
    this.authRepository,
  });

  final PetsController? petsController;
  final HealthController? healthController;
  final AppointmentProvider? appointmentProvider;
  final FirebaseAuth? auth;
  final NotificationRepository? notificationRepository;
  final ProfileRepository? profileRepository;
  final AuthRepository? authRepository;

  @override
  State<OwnerShellPage> createState() => _OwnerShellPageState();
}

class _OwnerShellPageState extends State<OwnerShellPage> {
  int _currentIndex = 0;

  late final PetsController _petsController;
  bool _ownsPetsController = false;

  late final HealthController _healthController;
  bool _ownsHealthController = false;

  late final AppointmentProvider _appointmentProvider;
  bool _ownsAppointmentProvider = false;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // Pet controller
    // ------------------------------------------------------------
    if (widget.petsController != null) {
      _petsController = widget.petsController!;
      _ownsPetsController = false;
    } else {
      final repository = FirebasePetRepository(
        auth: widget.auth ?? FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      final imageRepository = CloudinaryPetImageRepository(
        cloudName: CloudinaryConfig.cloudName,
        uploadPreset: CloudinaryConfig.uploadPreset,
      );

      _petsController = PetsController(
        CreatePet(repository),
        GetPets(repository),
        UpdatePet(repository),
        DeletePet(repository),
        UploadPetImage(imageRepository),
        DeletePetImage(imageRepository),
      );

      _ownsPetsController = true;
    }

    // ------------------------------------------------------------
    // Health controller
    // ------------------------------------------------------------
    if (widget.healthController != null) {
      _healthController = widget.healthController!;
      _ownsHealthController = false;
    } else {
      final medicalConditionRepository = FirebaseMedicalConditionRepository();
      final vaccinationRepository = FirebaseVaccinationRepository();
      final treatmentRepository = FirebaseTreatmentRepository();
      final healthMeasurementRepository = FirebaseHealthMeasurementRepository();

      _healthController = HealthController(
        createMedicalCondition: CreateMedicalCondition(
          medicalConditionRepository,
        ),
        getMedicalConditions: GetMedicalConditions(medicalConditionRepository),
        updateMedicalCondition: UpdateMedicalCondition(
          medicalConditionRepository,
        ),
        deleteMedicalCondition: DeleteMedicalCondition(
          medicalConditionRepository,
        ),
        createVaccination: CreateVaccination(vaccinationRepository),
        getVaccinations: GetVaccinations(vaccinationRepository),
        updateVaccination: UpdateVaccination(vaccinationRepository),
        deleteVaccination: DeleteVaccination(vaccinationRepository),
        createTreatment: CreateTreatment(treatmentRepository),
        getTreatments: GetTreatments(treatmentRepository),
        updateTreatment: UpdateTreatment(treatmentRepository),
        deleteTreatment: DeleteTreatment(treatmentRepository),
        createHealthMeasurement: CreateHealthMeasurement(
          healthMeasurementRepository,
        ),
        getHealthMeasurements: GetHealthMeasurements(
          healthMeasurementRepository,
        ),
        updateHealthMeasurement: UpdateHealthMeasurement(
          healthMeasurementRepository,
        ),
        deleteHealthMeasurement: DeleteHealthMeasurement(
          healthMeasurementRepository,
        ),
      );

      _ownsHealthController = true;
    }

    // ------------------------------------------------------------
    // Appointment provider
    // ------------------------------------------------------------
    if (widget.appointmentProvider != null) {
      _appointmentProvider = widget.appointmentProvider!;
      _ownsAppointmentProvider = false;
    } else {
      final appointmentRepository = FirebaseAppointmentRepository();
      final petRepository = FirebasePetRepository();
      final hospitalRepository = FirebaseHospitalRepository();
      final serviceRepository = FirebaseServiceRepository();
      final veterinarianRepository = FirebaseVeterinarianRepository();

      _appointmentProvider = AppointmentProvider(
        getAppointments: GetAppointments(appointmentRepository),
        petRepository: petRepository,
        hospitalRepository: hospitalRepository,
        serviceRepository: serviceRepository,
        veterinarianRepository: veterinarianRepository,
      );

      _ownsAppointmentProvider = true;
    }
  }

  @override
  void dispose() {
    if (_ownsPetsController) {
      _petsController.dispose();
    }

    if (_ownsHealthController) {
      _healthController.dispose();
    }

    if (_ownsAppointmentProvider) {
      _appointmentProvider.dispose();
    }

    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _appointmentProvider.loadAppointments();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      _appointmentProvider.loadAppointments();
    }
  }

  void _openAddPet() {
    Navigator.pushNamed(context, AppRouter.addPet, arguments: _petsController);
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth ?? FirebaseAuth.instance;
    final user = auth.currentUser;

    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Pet Owner';

    final photoUrl = user?.photoURL?.trim();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            petsController: _petsController,
            onMyPetsTap: () => _onTabSelected(1),
            onAddPetTap: _openAddPet,
            userName: userName,
            photoUrl: photoUrl,
            notificationRepository: widget.notificationRepository,
            onAppointmentsTap: () => _onTabSelected(2),
            onAskAITap: () => _onTabSelected(3),
            onVeterinariansTap: () {
              Navigator.pushNamed(context, AppRouter.veterinarianDiscovery);
            },
          ),
          MyPetsPage(
            controller: _petsController,
            healthController: _healthController,
            ownsController: false,
            ownsHealthController: false,
          ),
          MyAppointmentsPage(provider: _appointmentProvider),
          AIHubPage(
            pets: _petsController.pets,
            healthController: _healthController,
          ),
          ProfilePage(
            profileRepository: widget.profileRepository,
            authRepository: widget.authRepository,
          ),
        ],
      ),
      bottomNavigationBar: _OwnerBottomNavigation(
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
      ),
    );
  }
}

class _OwnerBottomNavigation extends StatelessWidget {
  const _OwnerBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _OwnerNavItem(label: 'Home', icon: Icons.home_rounded),
    _OwnerNavItem(label: 'My Pets', icon: Icons.pets_rounded),
    _OwnerNavItem(label: 'Appointments', icon: Icons.calendar_month_rounded),
    _OwnerNavItem(label: 'AI Hub', icon: Icons.psychology_rounded),
    _OwnerNavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.secondary.withValues(alpha: 0.22),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];

              return Expanded(
                child: _OwnerNavigationItem(
                  item: item,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OwnerNavigationItem extends StatelessWidget {
  const _OwnerNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _OwnerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.primary
        : AppTheme.deepBrown.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 22, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerNavItem {
  const _OwnerNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
