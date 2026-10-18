import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/health_measurement.dart';
import '../providers/health_controller.dart';

class HealthMeasurementsPage extends StatefulWidget {
  const HealthMeasurementsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<HealthMeasurementsPage> createState() => _HealthMeasurementsPageState();
}

class _HealthMeasurementsPageState extends State<HealthMeasurementsPage> {
  HealthController get _controller => widget.controller;

  List<HealthMeasurement> get _measurements {
    final measurements = _controller.healthMeasurements
        .where((measurement) => measurement.petId == widget.pet.petId)
        .toList();

    measurements.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return measurements;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onControllerChanged);
    _loadMeasurements();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMeasurements() async {
    await _controller.loadHealthRecords(widget.pet.petId);
  }

  Future<void> _addMeasurement() async {
    final measurement = await showDialog<HealthMeasurement>(
      context: context,
      builder: (_) => _HealthMeasurementDialog(petId: widget.pet.petId),
    );

    if (!mounted || measurement == null) {
      return;
    }

    final succeeded = await _controller.createHealthMeasurement(measurement);

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Health measurement added successfully.',
    );
  }

  Future<void> _editMeasurement(HealthMeasurement measurement) async {
    final updatedMeasurement = await showDialog<HealthMeasurement>(
      context: context,
      builder: (_) => _HealthMeasurementDialog(
        petId: widget.pet.petId,
        measurement: measurement,
      ),
    );

    if (!mounted || updatedMeasurement == null) {
      return;
    }

    final succeeded = await _controller.updateHealthMeasurement(
      updatedMeasurement,
    );

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Health measurement updated successfully.',
    );
  }

  Future<void> _deleteMeasurement(HealthMeasurement measurement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Measurement?'),
          content: Text(
            'Are you sure you want to delete '
            '"${measurement.type}" (${measurement.value} '
            '${measurement.unit})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final succeeded = await _controller.deleteHealthMeasurement(
      widget.pet.petId,
      measurement.measurementId,
    );

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Health measurement deleted successfully.',
    );
  }

  void _showOperationResult({
    required bool succeeded,
    required String successMessage,
  }) {
    final message = succeeded
        ? successMessage
        : (_controller.errorMessage ??
              'Unable to complete the health operation. Please try again.');

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final measurements = _measurements;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Health Measurements')),
      body: RefreshIndicator(
        onRefresh: _loadMeasurements,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _MeasurementPetHeader(pet: widget.pet),
            const SizedBox(height: 20),
            _MeasurementSectionHeading(count: measurements.length),
            const SizedBox(height: 12),
            if (_controller.isLoading && measurements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.errorMessage != null && measurements.isEmpty)
              _MeasurementErrorState(
                message: _controller.errorMessage!,
                onRetry: _loadMeasurements,
              )
            else if (measurements.isEmpty)
              const _MeasurementEmptyState()
            else
              ...measurements.map(
                (measurement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HealthMeasurementCard(
                    measurement: measurement,
                    onEdit: () => _editMeasurement(measurement),
                    onDelete: () => _deleteMeasurement(measurement),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading ? null : _addMeasurement,
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pet header
// -----------------------------------------------------------------------------

class _MeasurementPetHeader extends StatelessWidget {
  const _MeasurementPetHeader({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: pet.imageUrl.isEmpty
                ? const Icon(
                    Icons.pets_rounded,
                    size: 30,
                    color: AppTheme.deepBrown,
                  )
                : Image.network(
                    pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets_rounded,
                      size: 30,
                      color: AppTheme.deepBrown,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.species} • ${pet.breed}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  'Measurement history',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section heading
// -----------------------------------------------------------------------------

class _MeasurementSectionHeading extends StatelessWidget {
  const _MeasurementSectionHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recorded Measurements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'record' : 'records'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Measurement card
// -----------------------------------------------------------------------------

class _HealthMeasurementCard extends StatelessWidget {
  const _HealthMeasurementCard({
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthMeasurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (measurement.type.toLowerCase().trim()) {
      case 'weight':
        return Icons.monitor_weight_outlined;
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'height':
        return Icons.height_rounded;
      case 'heart rate':
      case 'heart_rate':
        return Icons.favorite_border_rounded;
      case 'respiratory rate':
      case 'respiratory_rate':
        return Icons.air_rounded;
      default:
        return Icons.monitor_heart_outlined;
    }
  }

  String get _formattedValue {
    final value = measurement.value;

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final recordedDate = localizations.formatMediumDate(measurement.recordedAt);

    final recordedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(measurement.recordedAt),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: AppTheme.deepBrown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.type,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recorded: $recordedDate at $recordedTime',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_MeasurementAction>(
                tooltip: 'Measurement actions',
                onSelected: (action) {
                  switch (action) {
                    case _MeasurementAction.edit:
                      onEdit();
                      break;
                    case _MeasurementAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _MeasurementAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _MeasurementAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _formattedValue,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  measurement.unit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.deepBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MeasurementAction { edit, delete }

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _MeasurementEmptyState extends StatelessWidget {
  const _MeasurementEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.24),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: AppTheme.deepBrown,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No measurements recorded',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a health measurement to keep track of your pet’s '
            'health over time.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Error state
// -----------------------------------------------------------------------------

class _MeasurementErrorState extends StatelessWidget {
  const _MeasurementErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.espresso),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Add/edit measurement dialog
// -----------------------------------------------------------------------------

class _HealthMeasurementDialog extends StatefulWidget {
  const _HealthMeasurementDialog({required this.petId, this.measurement});

  final String petId;
  final HealthMeasurement? measurement;

  @override
  State<_HealthMeasurementDialog> createState() =>
      _HealthMeasurementDialogState();
}

class _HealthMeasurementDialogState extends State<_HealthMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _typeController;
  late final TextEditingController _valueController;
  late final TextEditingController _unitController;

  late DateTime _recordedAt;

  bool get _isEditing => widget.measurement != null;

  @override
  void initState() {
    super.initState();

    final measurement = widget.measurement;

    _typeController = TextEditingController(text: measurement?.type ?? '');

    _valueController = TextEditingController(
      text: measurement == null ? '' : _formatInitialValue(measurement.value),
    );

    _unitController = TextEditingController(text: measurement?.unit ?? '');

    _recordedAt = measurement?.recordedAt ?? DateTime.now();
  }

  String _formatInitialValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _valueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _selectRecordedAt() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt.isAfter(now) ? now : _recordedAt,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The recorded date and time cannot be in the future.'),
        ),
      );
      return;
    }

    setState(() {
      _recordedAt = selectedDateTime;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_recordedAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The recorded date and time cannot be in the future.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.measurement;
    final parsedValue = double.parse(_valueController.text.trim());

    final measurement = HealthMeasurement(
      measurementId: existing?.measurementId ?? '',
      petId: widget.petId,
      type: _typeController.text.trim(),
      value: parsedValue,
      unit: _unitController.text.trim(),
      recordedAt: _recordedAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(measurement);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Measurement' : 'Add Measurement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _typeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Measurement type',
                  hintText: 'e.g. Weight, Temperature, Heart Rate',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the measurement type.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Measurement value',
                  hintText: 'e.g. 12.5',
                  prefixIcon: Icon(Icons.calculate_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the measurement value.';
                  }

                  final parsed = double.tryParse(value.trim());

                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return 'Enter a number greater than zero.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unitController,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g. kg, °C, cm, bpm',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the measurement unit.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Recorded date and time'),
                subtitle: Text(
                  '${localizations.formatMediumDate(_recordedAt)} • '
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(_recordedAt))}',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _selectRecordedAt,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Save Changes' : 'Add Measurement'),
        ),
      ],
    );
  }
}
