import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/pet.dart';
import '../providers/pets_controller.dart';

class AddEditPetPage extends StatefulWidget {
  const AddEditPetPage({required this.controller, super.key, this.pet});

  final PetsController controller;
  final Pet? pet;

  bool get isEditing => pet != null;

  @override
  State<AddEditPetPage> createState() => _AddEditPetPageState();
}

class _AddEditPetPageState extends State<AddEditPetPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _breedController;
  late final TextEditingController _genderController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  DateTime? _selectedDob;

  static const List<String> _speciesOptions = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Fish',
    'Other',
  ];

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();

    final pet = widget.pet;

    _nameController = TextEditingController(text: pet?.name ?? '');

    _speciesController = TextEditingController(text: pet?.species ?? '');

    _breedController = TextEditingController(text: pet?.breed ?? '');

    _genderController = TextEditingController(text: pet?.gender ?? '');

    _weightController = TextEditingController(
      text: pet == null ? '' : _formatWeight(pet.weight),
    );

    _notesController = TextEditingController(text: pet?.notes ?? '');

    _selectedDob = pet?.dob;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _genderController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toString();
  }

  Future<void> _selectDob() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final initialDate = _selectedDob != null && !_selectedDob!.isAfter(now)
        ? _selectedDob!
        : DateTime(now.year - 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDob = picked;
    });
  }

  Future<void> _savePet() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dob = _selectedDob;

    if (dob == null) {
      _showError('Please select your pet\'s date of birth.');
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());

    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight.');
      return;
    }

    final pet = Pet(
      petId: widget.pet?.petId ?? '',
      ownerId: widget.pet?.ownerId ?? '',
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      breed: _breedController.text.trim(),
      dob: dob,
      gender: _genderController.text.trim(),
      weight: weight,

      // Image upload will be implemented in the next slice.
      // Existing image is preserved when editing.
      imageUrl: widget.pet?.imageUrl ?? '',

      notes: _notesController.text.trim(),
      status: widget.pet?.status ?? 'active',
    );

    if (_isEditing) {
      await widget.controller.update(pet);
    } else {
      await widget.controller.create(pet);
    }

    if (!mounted) {
      return;
    }

    final errorMessage = widget.controller.errorMessage;

    if (errorMessage != null) {
      _showError(errorMessage);
      return;
    }

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your pet\'s name';
    }

    if (name.length < 2) {
      return 'Please enter a valid pet name';
    }

    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Please select your pet\'s $fieldName';
    }

    return null;
  }

  String? _validateWeight(String? value) {
    final rawValue = value?.trim() ?? '';

    if (rawValue.isEmpty) {
      return 'Please enter your pet\'s weight';
    }

    final weight = double.tryParse(rawValue);

    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isLoading = widget.controller.isLoading;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: Text(_isEditing ? 'Edit Pet' : 'Add Pet')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Update Your Pet'
                          : 'Create Your Pet Profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEditing
                          ? 'Keep your pet information up to date.'
                          : 'Let\'s get to know your furry friend!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.deepBrown,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Update their details whenever needed.'
                          : 'You can always add more pets later.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.deepBrown.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Photo placeholder.
                    // Real picker + Firebase Storage upload
                    // will be implemented in the next slice.
                    const _PhotoPlaceholder(),

                    const SizedBox(height: 20),

                    // Pet Name
                    const _FieldLabel(label: 'Pet Name', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Milo',
                        prefixIcon: Icon(
                          Icons.pets_outlined,
                          color: AppTheme.deepBrown,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Species + Breed
                    _TwoColumnFields(
                      left: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Species', required: true),
                          const SizedBox(height: 6),
                          _SelectionField(
                            value: _speciesController.text.isEmpty
                                ? null
                                : _speciesController.text,
                            hintText: 'Select species',
                            icon: Icons.pets_outlined,
                            options: _speciesOptions,
                            enabled: !isLoading,
                            onSelected: (value) {
                              setState(() {
                                _speciesController.text = value;
                              });
                            },
                            validator: (value) =>
                                _validateRequired(value, 'species'),
                          ),
                        ],
                      ),
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Breed', required: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _breedController,
                            enabled: !isLoading,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                _validateRequired(value, 'breed'),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Golden Retriever',
                              prefixIcon: Icon(
                                Icons.category_outlined,
                                color: AppTheme.deepBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // DOB + Gender
                    _TwoColumnFields(
                      left: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            label: 'Date of Birth',
                            required: true,
                          ),
                          const SizedBox(height: 6),
                          _DateField(
                            selectedDate: _selectedDob,
                            enabled: !isLoading,
                            onTap: _selectDob,
                            formatDate: _formatDate,
                          ),
                        ],
                      ),
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Gender', required: true),
                          const SizedBox(height: 6),
                          _SelectionField(
                            value: _genderController.text.isEmpty
                                ? null
                                : _genderController.text,
                            hintText: 'Select gender',
                            icon: Icons.person_outline_rounded,
                            options: _genderOptions,
                            enabled: !isLoading,
                            onSelected: (value) {
                              setState(() {
                                _genderController.text = value;
                              });
                            },
                            validator: (value) =>
                                _validateRequired(value, 'gender'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Weight + Initial Health Information
                    _TwoColumnFields(
                      left: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            label: 'Weight (kg)',
                            required: true,
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightController,
                            enabled: !isLoading,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateWeight,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 12.5',
                              prefixIcon: Icon(
                                Icons.monitor_weight_outlined,
                                color: AppTheme.deepBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(
                            label: 'Initial Health Information',
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesController,
                            enabled: !isLoading,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText:
                                  'Allergies, conditions or notes? (optional)',
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: AppTheme.deepBrown,
                              ),
                              contentPadding: EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create / Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: isLoading ? null : _savePet,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isEditing ? 'Save Changes' : 'Create Pet',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w700),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 40,
              color: AppTheme.deepBrown,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to upload',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'A clear photo helps us create a better pet profile.',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTheme.deepBrown, height: 1.3),
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

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.value,
    required this.hintText,
    required this.icon,
    required this.options,
    required this.enabled,
    required this.onSelected,
    required this.validator,
  });

  final String? value;
  final String hintText;
  final IconData icon;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: AppTheme.deepBrown,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.deepBrown),
      ),
      hint: Text(hintText, overflow: TextOverflow.ellipsis),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (value) {
              if (value != null) {
                onSelected(value);
              }
            }
          : null,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.selectedDate,
    required this.enabled,
    required this.onTap,
    required this.formatDate,
  });

  final DateTime? selectedDate;
  final bool enabled;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: AppTheme.deepBrown,
          ),
        ),
        child: Text(
          selectedDate == null ? 'Select date' : formatDate(selectedDate!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selectedDate == null
                ? AppTheme.deepBrown.withValues(alpha: 0.55)
                : AppTheme.espresso,
            fontWeight: selectedDate == null
                ? FontWeight.w400
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
