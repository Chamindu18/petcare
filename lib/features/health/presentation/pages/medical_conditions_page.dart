import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/medical_condition.dart';
import '../providers/health_controller.dart';

class MedicalConditionsPage extends StatefulWidget {
  const MedicalConditionsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<MedicalConditionsPage> createState() => _MedicalConditionsPageState();
}

class _MedicalConditionsPageState extends State<MedicalConditionsPage> {
  HealthController get _controller => widget.controller;

  List<MedicalCondition> get _conditions => _controller.medicalConditions
      .where((condition) => condition.petId == widget.pet.petId)
      .toList();

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onControllerChanged);
    _loadConditions();
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

  Future<void> _loadConditions() async {
    await _controller.loadHealthRecords(widget.pet.petId);
  }

  Future<void> _addCondition() async {
    final condition = await showDialog<MedicalCondition>(
      context: context,
      builder: (_) => _MedicalConditionDialog(petId: widget.pet.petId),
    );

    if (!mounted || condition == null) {
      return;
    }

    await _controller.createMedicalCondition(condition);

    if (!mounted) {
      return;
    }

    _showOperationResult(
      successMessage: 'Medical condition added successfully.',
    );
  }

  Future<void> _editCondition(MedicalCondition condition) async {
    final updatedCondition = await showDialog<MedicalCondition>(
      context: context,
      builder: (_) => _MedicalConditionDialog(
        petId: widget.pet.petId,
        condition: condition,
      ),
    );

    if (!mounted || updatedCondition == null) {
      return;
    }

    await _controller.updateMedicalCondition(updatedCondition);

    if (!mounted) {
      return;
    }

    _showOperationResult(
      successMessage: 'Medical condition updated successfully.',
    );
  }

  Future<void> _deleteCondition(MedicalCondition condition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Medical Condition?'),
          content: Text('Are you sure you want to delete "${condition.name}"?'),
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

    await _controller.deleteMedicalCondition(
      widget.pet.petId,
      condition.conditionId,
    );

    if (!mounted) {
      return;
    }

    _showOperationResult(
      successMessage: 'Medical condition deleted successfully.',
    );
  }

  void _showOperationResult({required String successMessage}) {
    final errorMessage = _controller.errorMessage;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage ?? successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final conditions = _conditions;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Medical Conditions')),
      body: RefreshIndicator(
        onRefresh: _loadConditions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _PetHeader(pet: widget.pet),
            const SizedBox(height: 20),
            _SectionHeading(title: 'Medical History', count: conditions.length),
            const SizedBox(height: 12),
            if (_controller.isLoading && conditions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.errorMessage != null && conditions.isEmpty)
              _ErrorState(
                message: _controller.errorMessage!,
                onRetry: _loadConditions,
              )
            else if (conditions.isEmpty)
              const _EmptyState()
            else
              ...conditions.map(
                (condition) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MedicalConditionCard(
                    condition: condition,
                    onEdit: () => _editCondition(condition),
                    onDelete: () => _deleteCondition(condition),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading ? null : _addCondition,
        icon: const Icon(Icons.add),
        label: const Text('Add Condition'),
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet});

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
                  'Medical history',
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
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

class _MedicalConditionCard extends StatelessWidget {
  const _MedicalConditionCard({
    required this.condition,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicalCondition condition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _sourceLabel {
    if (condition.source == 'vet_confirmed' ||
        condition.source == 'veterinarian_confirmed') {
      return 'Veterinarian-confirmed';
    }

    return 'Owner-reported';
  }

  String get _statusLabel {
    return condition.status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisDate = MaterialLocalizations.of(context)
        .formatMediumDate(condition.diagnosisDate);

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
                  Icons.medical_information_outlined,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Diagnosed: $diagnosisDate',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ConditionAction>(
                tooltip: 'Condition actions',
                onSelected: (action) {
                  switch (action) {
                    case _ConditionAction.edit:
                      onEdit();
                      break;
                    case _ConditionAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ConditionAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _ConditionAction.delete,
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
              _ConditionTag(label: _statusLabel, icon: Icons.flag_outlined),
              _ConditionTag(
                label: _sourceLabel,
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
          if (condition.vetId?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'Veterinarian ID: ${condition.vetId}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ],
          if (condition.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              condition.notes,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionTag extends StatelessWidget {
  const _ConditionTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.deepBrown),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.medical_information_outlined,
              color: AppTheme.deepBrown,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No medical conditions recorded',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a condition to keep your pet’s medical history in one place.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown, height: 1.4),
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

enum _ConditionAction { edit, delete }

class _MedicalConditionDialog extends StatefulWidget {
  const _MedicalConditionDialog({required this.petId, this.condition});

  final String petId;
  final MedicalCondition? condition;

  @override
  State<_MedicalConditionDialog> createState() =>
      _MedicalConditionDialogState();
}

class _MedicalConditionDialogState extends State<_MedicalConditionDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _vetIdController;
  late final TextEditingController _notesController;

  late String _status;
  late String _source;
  late DateTime _diagnosisDate;

  bool get _isEditing => widget.condition != null;

  @override
  void initState() {
    super.initState();

    final condition = widget.condition;

    _nameController = TextEditingController(text: condition?.name ?? '');
    _vetIdController = TextEditingController(text: condition?.vetId ?? '');
    _notesController = TextEditingController(text: condition?.notes ?? '');

    _status = condition?.status == 'resolved' ? 'resolved' : 'active';

    _source = switch (condition?.source) {
      'vet_confirmed' || 'veterinarian_confirmed' => 'vet_confirmed',
      _ => 'owner_reported',
    };

    _diagnosisDate = condition?.diagnosisDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vetIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDiagnosisDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate.isAfter(now) ? now : _diagnosisDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _diagnosisDate = selectedDate;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final existing = widget.condition;

    final condition = MedicalCondition(
      conditionId: existing?.conditionId ?? '',
      petId: widget.petId,
      name: _nameController.text.trim(),
      status: _status,
      source: _source,
      diagnosisDate: _diagnosisDate,
      vetId:
          _source == 'vet_confirmed' && _vetIdController.text.trim().isNotEmpty
          ? _vetIdController.text.trim()
          : null,
      notes: _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(condition);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Medical Condition' : 'Add Medical Condition',
      ),
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
                  labelText: 'Condition name',
                  hintText: 'e.g. Skin allergy',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the condition name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
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
                value: _source,
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
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Diagnosis date'),
                subtitle: Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(_diagnosisDate),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _selectDiagnosisDate,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vetIdController,
                decoration: const InputDecoration(
                  labelText: 'Veterinarian ID (optional)',
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
          child: Text(_isEditing ? 'Save Changes' : 'Add Condition'),
        ),
      ],
    );
  }
}
