import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_appointment_repository.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../../services/data/repositories/firebase_service_repository.dart';
import '../../../services/domain/entities/service.dart';
import '../../../services/domain/usecases/service_usecases.dart';
import '../../../veterinary/data/repositories/firebase_veterinarian_repository.dart';
import '../../../veterinary/domain/entities/veterinarian.dart';
import '../../../veterinary/domain/usecases/veterinarian_usecases.dart';

class BookAppointmentRouteArgs {
  const BookAppointmentRouteArgs({
    required this.hospitalId,
    this.veterinarianId,
  });

  final String hospitalId;
  final String? veterinarianId;
}

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({
    required this.hospitalId,
    this.veterinarianId,
    required this.petsController,
    super.key,
  });

  final String hospitalId;
  final String? veterinarianId;
  final PetsController petsController;

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  late final GetServicesByHospital _getServicesByHospital;
  late final GetVeterinariansByHospital _getVeterinariansByHospital;
  late final CreateAppointment _createAppointment;

  List<Service> _services = [];
  List<Veterinarian> _veterinarians = [];

  Pet? _selectedPet;
  Service? _selectedService;
  Veterinarian? _selectedVeterinarian;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Reuse the existing service, veterinarian, and appointment contracts.
    _getServicesByHospital = GetServicesByHospital(FirebaseServiceRepository());

    _getVeterinariansByHospital = GetVeterinariansByHospital(
      FirebaseVeterinarianRepository(),
    );

    _createAppointment = CreateAppointment(FirebaseAppointmentRepository());

    _loadBookingData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.petsController.loadPets();

      final services = await _getServicesByHospital(widget.hospitalId);
      final veterinarians = await _getVeterinariansByHospital(
        widget.hospitalId,
      );

      if (!mounted) {
        return;
      }

      Veterinarian? selectedVeterinarian;

      if (widget.veterinarianId != null) {
        for (final veterinarian in veterinarians) {
          if (veterinarian.vetId == widget.veterinarianId) {
            selectedVeterinarian = veterinarian;
            break;
          }
        }
      }

      setState(() {
        _services = services;
        _veterinarians = veterinarians;
        _selectedVeterinarian = selectedVeterinarian;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load booking information.';
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = selectedTime;
    });
  }

  DateTime? get _selectedDateTime {
    final date = _selectedDate;
    final time = _selectedTime;

    if (date == null || time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool get _canSubmit {
    return _selectedPet != null &&
        _selectedService != null &&
        _selectedVeterinarian != null &&
        _selectedDateTime != null &&
        !_isSubmitting;
  }

  Future<void> _submitAppointment() async {
    if (!_canSubmit) {
      return;
    }

    final pet = _selectedPet!;
    final service = _selectedService!;
    final veterinarian = _selectedVeterinarian!;
    final dateTime = _selectedDateTime!;

    if (dateTime.isBefore(DateTime.now())) {
      _showMessage('Please select a future appointment time.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final appointment = Appointment(
        // Firestore generates the real appointment ID.
        appointmentId: '',

        // The repository gets the authenticated owner's ID.
        ownerId: '',

        petId: pet.petId,
        hospitalId: widget.hospitalId,
        serviceId: service.serviceId,
        vetId: veterinarian.vetId,
        dateTime: dateTime,
        reason: _reasonController.text.trim(),

        // Keep the currently agreed booking status.
        status: 'pending',

        queueId: null,
        createdAt: DateTime.now(),
      );

      // Create the appointment and receive the persisted appointment.
      final createdAppointment = await _createAppointment(appointment);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      // Send the created appointment to the confirmation page.
      Navigator.pushReplacementNamed(
        context,
        AppRouter.appointmentConfirmation,
        arguments: createdAppointment,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _showMessage('Unable to create the appointment. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton(
          onPressed: _canSubmit ? _submitAppointment : null,
          child: _isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                )
              : const Text('Book Appointment'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadBookingData);
    }

    if (widget.petsController.pets.isEmpty) {
      return const _EmptyPetsState();
    }

    return ListenableBuilder(
      listenable: widget.petsController,
      builder: (context, _) {
        return Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              const _PageIntro(),
              const SizedBox(height: 24),

              _SectionTitle(icon: Icons.pets_rounded, title: 'Select Pet'),
              const SizedBox(height: 10),
              _buildPetDropdown(),

              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.medical_services_rounded,
                title: 'Select Service',
              ),
              const SizedBox(height: 10),
              _buildServiceDropdown(),

              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.person_rounded,
                title: 'Select Veterinarian',
              ),
              const SizedBox(height: 10),
              _buildVeterinarianDropdown(),

              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.calendar_month_rounded,
                title: 'Date & Time',
              ),
              const SizedBox(height: 10),
              _buildDateTimeSelector(),

              const SizedBox(height: 22),

              _SectionTitle(
                icon: Icons.notes_rounded,
                title: 'Reason for Visit',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the reason for the visit',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              _BookingSummary(
                petName: _selectedPet?.name,
                serviceName: _selectedService?.name,
                veterinarianName: _selectedVeterinarian?.name,
                dateTime: _selectedDateTime,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetDropdown() {
    final pets = widget.petsController.pets;

    return DropdownButtonFormField<Pet>(
      initialValue: _selectedPet,
      decoration: const InputDecoration(hintText: 'Choose a pet'),
      items: pets.map((pet) {
        return DropdownMenuItem<Pet>(value: pet, child: Text(pet.name));
      }).toList(),
      onChanged: (pet) {
        setState(() {
          _selectedPet = pet;
        });
      },
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<Service>(
      initialValue: _selectedService,
      decoration: const InputDecoration(hintText: 'Choose a service'),
      items: _services.map((service) {
        return DropdownMenuItem<Service>(
          value: service,
          child: Text(service.name),
        );
      }).toList(),
      onChanged: _services.isEmpty
          ? null
          : (service) {
              setState(() {
                _selectedService = service;
              });
            },
    );
  }

  Widget _buildVeterinarianDropdown() {
    return DropdownButtonFormField<Veterinarian>(
      initialValue: _selectedVeterinarian,
      decoration: const InputDecoration(hintText: 'Choose a veterinarian'),
      items: _veterinarians.map((veterinarian) {
        return DropdownMenuItem<Veterinarian>(
          value: veterinarian,
          child: Text(
            veterinarian.specialty == null ||
                    veterinarian.specialty!.trim().isEmpty
                ? veterinarian.name
                : '${veterinarian.name} • ${veterinarian.specialty}',
          ),
        );
      }).toList(),
      onChanged: _veterinarians.isEmpty
          ? null
          : (veterinarian) {
              setState(() {
                _selectedVeterinarian = veterinarian;
              });
            },
    );
  }

  Widget _buildDateTimeSelector() {
    final dateText = _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

    final timeText = _selectedTime == null
        ? 'Select time'
        : _selectedTime!.format(context);

    return Row(
      children: [
        Expanded(
          child: _DateTimeButton(
            icon: Icons.calendar_today_rounded,
            label: dateText,
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateTimeButton(
            icon: Icons.access_time_rounded,
            label: timeText,
            onTap: _selectTime,
          ),
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule a visit',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your pet, service, veterinarian and preferred time.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.deepBrown, height: 1.45),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.petName,
    required this.serviceName,
    required this.veterinarianName,
    required this.dateTime,
  });

  final String? petName;
  final String? serviceName;
  final String? veterinarianName;
  final DateTime? dateTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Pet', value: petName ?? 'Not selected'),
            _SummaryRow(label: 'Service', value: serviceName ?? 'Not selected'),
            _SummaryRow(
              label: 'Veterinarian',
              value: veterinarianName ?? 'Not selected',
            ),
            _SummaryRow(
              label: 'Date & time',
              value: dateTime == null
                  ? 'Not selected'
                  : '${dateTime!.day}/${dateTime!.month}/${dateTime!.year} '
                        '${TimeOfDay.fromDateTime(dateTime!).format(context)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.deepBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyPetsState extends StatelessWidget {
  const _EmptyPetsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Please add a pet before booking an appointment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.espresso,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
