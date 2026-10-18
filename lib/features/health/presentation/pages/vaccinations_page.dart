import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/vaccination.dart';
import '../providers/health_controller.dart';

class VaccinationsPage extends StatefulWidget {
  const VaccinationsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
  HealthController get _controller => widget.controller;

  List<Vaccination> get _vaccinations =>
      _controller.vaccinations
          .where((vaccination) => vaccination.petId == widget.pet.petId)
          .toList()
        ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onControllerChanged);
    _loadVaccinations();
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

  Future<void> _loadVaccinations() async {
    await _controller.loadHealthRecords(widget.pet.petId);
  }

  Future<void> _addVaccination() async {
    final vaccination = await showDialog<Vaccination>(
      context: context,
      builder: (_) => _VaccinationDialog(petId: widget.pet.petId),
    );

    if (!mounted || vaccination == null) {
      return;
    }

    final succeeded = await _controller.createVaccination(vaccination);

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Vaccination added successfully.',
    );
  }

  Future<void> _editVaccination(Vaccination vaccination) async {
    final updatedVaccination = await showDialog<Vaccination>(
      context: context,
      builder: (_) =>
          _VaccinationDialog(petId: widget.pet.petId, vaccination: vaccination),
    );

    if (!mounted || updatedVaccination == null) {
      return;
    }

    final succeeded = await _controller.updateVaccination(updatedVaccination);

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Vaccination updated successfully.',
    );
  }

  Future<void> _deleteVaccination(Vaccination vaccination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Vaccination?'),
          content: Text(
            'Are you sure you want to delete '
            '"${vaccination.name}"?',
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

    final succeeded = await _controller.deleteVaccination(
      widget.pet.petId,
      vaccination.vaccinationId,
    );

    if (!mounted) {
      return;
    }

    _showOperationResult(
      succeeded: succeeded,
      successMessage: 'Vaccination deleted successfully.',
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
    final vaccinations = _vaccinations;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Vaccinations')),
      body: RefreshIndicator(
        onRefresh: _loadVaccinations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _VaccinationPetHeader(pet: widget.pet),
            const SizedBox(height: 20),
            _VaccinationSectionHeading(count: vaccinations.length),
            const SizedBox(height: 12),
            if (_controller.isLoading && vaccinations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.errorMessage != null && vaccinations.isEmpty)
              _VaccinationErrorState(
                message: _controller.errorMessage!,
                onRetry: _loadVaccinations,
              )
            else if (vaccinations.isEmpty)
              const _VaccinationEmptyState()
            else
              ...vaccinations.map(
                (vaccination) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VaccinationCard(
                    vaccination: vaccination,
                    onEdit: () => _editVaccination(vaccination),
                    onDelete: () => _deleteVaccination(vaccination),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading ? null : _addVaccination,
        icon: const Icon(Icons.add),
        label: const Text('Add Vaccination'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pet header
// -----------------------------------------------------------------------------

class _VaccinationPetHeader extends StatelessWidget {
  const _VaccinationPetHeader({required this.pet});

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
                  'Vaccination history',
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

class _VaccinationSectionHeading extends StatelessWidget {
  const _VaccinationSectionHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Vaccination History',
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
// Vaccination card
// -----------------------------------------------------------------------------

class _VaccinationCard extends StatelessWidget {
  const _VaccinationCard({
    required this.vaccination,
    required this.onEdit,
    required this.onDelete,
  });

  final Vaccination vaccination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  DateTime _dateOnly(DateTime date) {
    return DateUtils.dateOnly(date);
  }

  String _dueLabel() {
    final nextDueDate = vaccination.nextDueDate;

    if (nextDueDate == null) {
      return 'No next dose scheduled';
    }

    final today = _dateOnly(DateTime.now());
    final dueDate = _dateOnly(nextDueDate);

    if (dueDate.isBefore(today)) {
      return 'Overdue';
    }

    if (dueDate.isAtSameMomentAs(today)) {
      return 'Due today';
    }

    return 'Upcoming';
  }

  Color _dueColor() {
    switch (_dueLabel()) {
      case 'Overdue':
        return AppTheme.error;
      case 'Due today':
        return AppTheme.warning;
      case 'Upcoming':
        return AppTheme.deepBrown;
      default:
        return AppTheme.success;
    }
  }

  IconData _dueIcon() {
    switch (_dueLabel()) {
      case 'Overdue':
        return Icons.warning_amber_rounded;
      case 'Due today':
        return Icons.event_busy_outlined;
      case 'Upcoming':
        return Icons.event_available_outlined;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    final dateGiven = localizations.formatMediumDate(vaccination.dateGiven);

    final nextDueDate = vaccination.nextDueDate;

    final formattedDueDate = nextDueDate == null
        ? null
        : localizations.formatMediumDate(nextDueDate);

    final dueLabel = _dueLabel();
    final dueColor = _dueColor();

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
                child: const Icon(
                  Icons.vaccines_outlined,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccination.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Administered: $dateGiven',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_VaccinationAction>(
                tooltip: 'Vaccination actions',
                onSelected: (action) {
                  switch (action) {
                    case _VaccinationAction.edit:
                      onEdit();
                      break;
                    case _VaccinationAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _VaccinationAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _VaccinationAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: dueColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_dueIcon(), color: dueColor, size: 16),
                const SizedBox(width: 5),
                Text(
                  dueLabel,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: dueColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (formattedDueDate != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: AppTheme.deepBrown,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next due date: $formattedDueDate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (vaccination.providerId?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'Provider ID: ${vaccination.providerId}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ],
          if (vaccination.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              vaccination.notes,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

enum _VaccinationAction { edit, delete }

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _VaccinationEmptyState extends StatelessWidget {
  const _VaccinationEmptyState();

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
              Icons.vaccines_outlined,
              color: AppTheme.deepBrown,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No vaccinations recorded',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a vaccination to keep your pet’s vaccination history '
            'in one place.',
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

class _VaccinationErrorState extends StatelessWidget {
  const _VaccinationErrorState({required this.message, required this.onRetry});

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
// Add/edit vaccination dialog
// -----------------------------------------------------------------------------

class _VaccinationDialog extends StatefulWidget {
  const _VaccinationDialog({required this.petId, this.vaccination});

  final String petId;
  final Vaccination? vaccination;

  @override
  State<_VaccinationDialog> createState() => _VaccinationDialogState();
}

class _VaccinationDialogState extends State<_VaccinationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _providerIdController;
  late final TextEditingController _notesController;

  late DateTime _dateGiven;
  DateTime? _nextDueDate;

  bool get _isEditing => widget.vaccination != null;

  @override
  void initState() {
    super.initState();

    final vaccination = widget.vaccination;

    _nameController = TextEditingController(text: vaccination?.name ?? '');

    _providerIdController = TextEditingController(
      text: vaccination?.providerId ?? '',
    );

    _notesController = TextEditingController(text: vaccination?.notes ?? '');

    _dateGiven = vaccination?.dateGiven ?? DateTime.now();
    _nextDueDate = vaccination?.nextDueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateGiven() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateGiven.isAfter(now) ? now : _dateGiven,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _dateGiven = selectedDate;
    });
  }

  Future<void> _selectNextDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? _dateGiven.add(const Duration(days: 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _nextDueDate = selectedDate;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Do not allow future administration dates, including when editing
    // an existing record that might already contain a future date.
    if (DateUtils.dateOnly(_dateGiven)
        .isAfter(DateUtils.dateOnly(DateTime.now()))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The vaccination date cannot be in the future.'),
        ),
      );
      return;
    }

    // Compare calendar dates rather than full timestamps.
    // A next due date on the same day as administration is allowed.
    if (_nextDueDate != null &&
        DateUtils.dateOnly(_nextDueDate!)
            .isBefore(DateUtils.dateOnly(_dateGiven))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The next due date cannot be before the vaccination date.',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.vaccination;

    final vaccination = Vaccination(
      vaccinationId: existing?.vaccinationId ?? '',
      petId: widget.petId,
      name: _nameController.text.trim(),
      dateGiven: _dateGiven,
      nextDueDate: _nextDueDate,
      providerId: _providerIdController.text.trim().isEmpty
          ? null
          : _providerIdController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(vaccination);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Vaccination' : 'Add Vaccination'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Vaccine name',
                  hintText: 'e.g. Rabies vaccine',
                  prefixIcon: Icon(Icons.vaccines_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the vaccine name.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date administered'),
                subtitle: Text(localizations.formatMediumDate(_dateGiven)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _selectDateGiven,
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Schedule next dose'),
                subtitle: const Text(
                  'Set a reminder date for the next vaccination.',
                ),
                value: _nextDueDate != null,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      _nextDueDate ??= _dateGiven.add(
                        const Duration(days: 365),
                      );
                    } else {
                      _nextDueDate = null;
                    }
                  });
                },
              ),
              if (_nextDueDate != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('Next due date'),
                  subtitle: Text(localizations.formatMediumDate(_nextDueDate!)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _selectNextDueDate,
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _providerIdController,
                decoration: const InputDecoration(
                  labelText: 'Provider ID (optional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
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
          child: Text(_isEditing ? 'Save Changes' : 'Add Vaccination'),
        ),
      ],
    );
  }
}
