import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/treatment.dart';
import '../providers/health_controller.dart';

class TreatmentsPage extends StatefulWidget {
  const TreatmentsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends State<TreatmentsPage> {
  HealthController get _controller => widget.controller;

  List<Treatment> get _treatments {
    final treatments = _controller.treatments
        .where((treatment) => treatment.petId == widget.pet.petId)
        .toList();

    treatments.sort((a, b) {
      final aDate = a.startDate;
      final bDate = b.startDate;

      if (aDate == null && bDate == null) {
        return a.name.compareTo(b.name);
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return treatments;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onControllerChanged);
    _loadTreatments();
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

  Future<void> _loadTreatments() async {
    await _controller.loadHealthRecords(widget.pet.petId);
  }

  Future<void> _addTreatment() async {
    final treatment = await showDialog<Treatment>(
      context: context,
      builder: (_) => _TreatmentDialog(petId: widget.pet.petId),
    );

    if (!mounted || treatment == null) {
      return;
    }

    await _controller.createTreatment(treatment);

    if (!mounted) {
      return;
    }

    _showOperationResult(successMessage: 'Treatment added successfully.');
  }

  Future<void> _editTreatment(Treatment treatment) async {
    final updatedTreatment = await showDialog<Treatment>(
      context: context,
      builder: (_) =>
          _TreatmentDialog(petId: widget.pet.petId, treatment: treatment),
    );

    if (!mounted || updatedTreatment == null) {
      return;
    }

    await _controller.updateTreatment(updatedTreatment);

    if (!mounted) {
      return;
    }

    _showOperationResult(successMessage: 'Treatment updated successfully.');
  }

  Future<void> _deleteTreatment(Treatment treatment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Treatment?'),
          content: Text('Are you sure you want to delete "${treatment.name}"?'),
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

    await _controller.deleteTreatment(widget.pet.petId, treatment.treatmentId);

    if (!mounted) {
      return;
    }

    _showOperationResult(successMessage: 'Treatment deleted successfully.');
  }

  void _showOperationResult({required String successMessage}) {
    final errorMessage = _controller.errorMessage;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage ?? successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final treatments = _treatments;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Treatments')),
      body: RefreshIndicator(
        onRefresh: _loadTreatments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _TreatmentPetHeader(pet: widget.pet),
            const SizedBox(height: 20),
            _TreatmentSectionHeading(count: treatments.length),
            const SizedBox(height: 12),
            if (_controller.isLoading && treatments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.errorMessage != null && treatments.isEmpty)
              _TreatmentErrorState(
                message: _controller.errorMessage!,
                onRetry: _loadTreatments,
              )
            else if (treatments.isEmpty)
              const _TreatmentEmptyState()
            else
              ...treatments.map(
                (treatment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TreatmentCard(
                    treatment: treatment,
                    onEdit: () => _editTreatment(treatment),
                    onDelete: () => _deleteTreatment(treatment),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading ? null : _addTreatment,
        icon: const Icon(Icons.add),
        label: const Text('Add Treatment'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pet header
// -----------------------------------------------------------------------------

class _TreatmentPetHeader extends StatelessWidget {
  const _TreatmentPetHeader({required this.pet});

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
                  'Treatment history',
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
// Treatment section heading
// -----------------------------------------------------------------------------

class _TreatmentSectionHeading extends StatelessWidget {
  const _TreatmentSectionHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Treatment History',
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
// Treatment card
// -----------------------------------------------------------------------------

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({
    required this.treatment,
    required this.onEdit,
    required this.onDelete,
  });

  final Treatment treatment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _statusLabel => _formatLabel(treatment.status);

  String get _sourceLabel {
    if (treatment.source == 'vet_confirmed' ||
        treatment.source == 'veterinarian_confirmed') {
      return 'Veterinarian-confirmed';
    }

    return 'Owner-reported';
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color get _statusColor {
    switch (treatment.status) {
      case 'active':
      case 'ongoing':
        return AppTheme.success;
      case 'completed':
        return AppTheme.deepBrown;
      case 'discontinued':
        return AppTheme.error;
      default:
        return AppTheme.deepBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final startDate = treatment.startDate;
    final endDate = treatment.endDate;

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
                  Icons.medication_outlined,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (startDate != null)
                      Text(
                        'Started: ${localizations.formatMediumDate(startDate)}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.deepBrown),
                      ),
                    if (startDate == null)
                      Text(
                        'Start date not recorded',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.deepBrown),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_TreatmentAction>(
                tooltip: 'Treatment actions',
                onSelected: (action) {
                  switch (action) {
                    case _TreatmentAction.edit:
                      onEdit();
                      break;
                    case _TreatmentAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _TreatmentAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _TreatmentAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TreatmentTag(
                label: _statusLabel,
                icon: Icons.flag_outlined,
                color: _statusColor,
              ),
              _TreatmentTag(
                label: _sourceLabel,
                icon: Icons.verified_user_outlined,
                color: AppTheme.deepBrown,
              ),
            ],
          ),
          if (endDate != null) ...[
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
                    'End date: ${localizations.formatMediumDate(endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.espresso),
                  ),
                ),
              ],
            ),
          ],
          if (treatment.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              treatment.notes,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

enum _TreatmentAction { edit, delete }

// -----------------------------------------------------------------------------
// Treatment tag
// -----------------------------------------------------------------------------

class _TreatmentTag extends StatelessWidget {
  const _TreatmentTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _TreatmentEmptyState extends StatelessWidget {
  const _TreatmentEmptyState();

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
              Icons.medication_outlined,
              color: AppTheme.deepBrown,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No treatments recorded',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a treatment to keep your pet’s treatment history '
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

class _TreatmentErrorState extends StatelessWidget {
  const _TreatmentErrorState({required this.message, required this.onRetry});

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
// Add/edit treatment dialog
// -----------------------------------------------------------------------------

class _TreatmentDialog extends StatefulWidget {
  const _TreatmentDialog({required this.petId, this.treatment});

  final String petId;
  final Treatment? treatment;

  @override
  State<_TreatmentDialog> createState() => _TreatmentDialogState();
}

class _TreatmentDialogState extends State<_TreatmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  late String _status;
  late String _source;

  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.treatment != null;

  @override
  void initState() {
    super.initState();

    final treatment = widget.treatment;

    _nameController = TextEditingController(text: treatment?.name ?? '');
    _notesController = TextEditingController(text: treatment?.notes ?? '');

    _status = treatment?.status ?? 'active';

    _source = switch (treatment?.source) {
      'vet_confirmed' || 'veterinarian_confirmed' => 'vet_confirmed',
      _ => 'owner_reported',
    };

    _startDate = treatment?.startDate;
    _endDate = treatment?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selectedDate;
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The end date cannot be before the start date.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.treatment;

    final treatment = Treatment(
      treatmentId: existing?.treatmentId ?? '',
      petId: widget.petId,
      name: _nameController.text.trim(),
      status: _status,
      source: _source,
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(treatment);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Treatment' : 'Add Treatment'),
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
                  labelText: 'Treatment name',
                  hintText: 'e.g. Antibiotic treatment',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the treatment name.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Treatment status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'discontinued',
                    child: Text('Discontinued'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: const InputDecoration(
                  labelText: 'Record source',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'owner_reported',
                    child: Text('Owner-reported'),
                  ),
                  DropdownMenuItem(
                    value: 'vet_confirmed',
                    child: Text('Veterinarian-confirmed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _source = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Start date'),
                subtitle: Text(
                  _startDate == null
                      ? 'Not recorded'
                      : localizations.formatMediumDate(_startDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_startDate != null)
                      IconButton(
                        tooltip: 'Clear start date',
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Select start date',
                      onPressed: _selectStartDate,
                      icon: const Icon(Icons.edit_calendar_outlined),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('End date'),
                subtitle: Text(
                  _endDate == null
                      ? 'Not recorded'
                      : localizations.formatMediumDate(_endDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_endDate != null)
                      IconButton(
                        tooltip: 'Clear end date',
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Select end date',
                      onPressed: _selectEndDate,
                      icon: const Icon(Icons.edit_calendar_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
          child: Text(_isEditing ? 'Save Changes' : 'Add Treatment'),
        ),
      ],
    );
  }
}
