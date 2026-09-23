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
  late final TextEditingController _imageUrlController;
  late final TextEditingController _notesController;

  DateTime? _selectedDob;

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
      text: pet == null ? '' : pet.weight.toString(),
    );
    _imageUrlController = TextEditingController(text: pet?.imageUrl ?? '');
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
    _imageUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDob() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (!mounted || picked == null) return;

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
      imageUrl: _imageUrlController.text.trim(),
      notes: _notesController.text.trim(),
      status: widget.pet?.status ?? 'active',
    );

    if (_isEditing) {
      await widget.controller.update(pet);
    } else {
      await widget.controller.create(pet);
    }

    if (!mounted) return;

    if (widget.controller.errorMessage != null) {
      _showError(widget.controller.errorMessage!);
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
      return 'Please enter your pet\'s $fieldName';
    }

    return null;
  }

  String? _validateWeight(String? value) {
    final weight = double.tryParse(value?.trim() ?? '');

    if (value == null || value.trim().isEmpty) {
      return 'Please enter your pet\'s weight';
    }

    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }

    return null;
  }

  String? _validateImageUrl(String? value) {
    final imageUrl = value?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(imageUrl);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'Please enter a valid image URL';
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
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Update your pet\'s information'
                          : 'Tell us about your pet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEditing ? 'Keep your pet profile up to date.' : 'Add the basic details so you can start managing their care.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.deepBrown,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Pet Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Milo',
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Species'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _speciesController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateRequired(value, 'species'),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dog',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Breed'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _breedController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateRequired(value, 'breed'),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Golden Retriever',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Date of Birth'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: isLoading ? null : _selectDob,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _selectedDob == null
                              ? 'Select date of birth'
                              : _formatDate(_selectedDob!),
                          style: _selectedDob == null
                              ? theme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.deepBrown.withValues(
                                    alpha: 0.55,
                                  ),
                                )
                              : theme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.espresso,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Gender'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _genderController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateRequired(value, 'gender'),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Male or Female',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Weight (kg)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateWeight,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 12.5',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        suffixText: 'kg',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Image URL'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _imageUrlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: _validateImageUrl,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/pet.jpg',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Notes'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Any additional information...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 64),
                          child: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _savePet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
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
                              : Text(_isEditing ? 'Save Changes' : 'Save Pet'),
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
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w700),
    );
  }
}
