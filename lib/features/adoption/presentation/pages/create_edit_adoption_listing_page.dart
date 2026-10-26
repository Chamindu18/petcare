import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_listing_repository.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';
import '../../domain/usecases/create_adoption_listing.dart';
import '../../domain/usecases/update_adoption_listing.dart';
import '../providers/adoption_listing_controller.dart';

class CreateEditAdoptionListingPage extends StatefulWidget {
  const CreateEditAdoptionListingPage({
    super.key,
    this.adoptionListingRepository,
    this.listing,
  });

  final AdoptionListingRepository? adoptionListingRepository;
  final AdoptionListing? listing;

  bool get isEditing => listing != null;

  @override
  State<CreateEditAdoptionListingPage> createState() =>
      _CreateEditAdoptionListingPageState();
}

class _CreateEditAdoptionListingPageState
    extends State<CreateEditAdoptionListingPage> {
  final _formKey = GlobalKey<FormState>();

  late final AdoptionListingController _controller;

  late final TextEditingController _petNameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactNoteController;
  late final TextEditingController _imageAssetController;

  String? _selectedSpecies;
  String? _selectedGender;
  bool _hasChanges = false;

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

    final listing = widget.listing;

    final repository =
        widget.adoptionListingRepository ?? FirebaseAdoptionListingRepository();

    _controller = AdoptionListingController(
      CreateAdoptionListing(repository),
      UpdateAdoptionListing(repository),
    );

    _petNameController = TextEditingController(text: listing?.petName ?? '');
    _breedController = TextEditingController(text: listing?.breed ?? '');
    _ageDescriptionController = TextEditingController(
      text: listing?.ageDescription ?? '',
    );
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _locationController = TextEditingController(text: listing?.location ?? '');
    _contactNoteController = TextEditingController(
      text: listing?.contactNote ?? '',
    );
    _imageAssetController = TextEditingController(
      text: listing?.imageAsset ?? '',
    );

    _selectedSpecies = listing?.species;
    _selectedGender = listing?.gender;

    for (final controller in [
      _petNameController,
      _breedController,
      _ageDescriptionController,
      _descriptionController,
      _locationController,
      _contactNoteController,
      _imageAssetController,
    ]) {
      controller.addListener(_markChanged);
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    _petNameController
      ..removeListener(_markChanged)
      ..dispose();
    _breedController
      ..removeListener(_markChanged)
      ..dispose();
    _ageDescriptionController
      ..removeListener(_markChanged)
      ..dispose();
    _descriptionController
      ..removeListener(_markChanged)
      ..dispose();
    _locationController
      ..removeListener(_markChanged)
      ..dispose();
    _contactNoteController
      ..removeListener(_markChanged)
      ..dispose();
    _imageAssetController
      ..removeListener(_markChanged)
      ..dispose();

    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges && mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _setSpecies(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedSpecies = value;
      _hasChanges = true;
    });
  }

  void _setGender(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedGender = value;
      _hasChanges = true;
    });
  }

  AdoptionListing _buildListing({required String status}) {
    final existing = widget.listing;
    final now = DateTime.now();

    return AdoptionListing(
      listingId: existing?.listingId ?? '',
      providerId: existing?.providerId ?? '',
      listingOwnerType: existing?.listingOwnerType ?? 'adoption_provider',
      listingOwnerId: existing?.listingOwnerId,
      petName: _petNameController.text.trim(),
      species: _selectedSpecies!.trim(),
      breed: _optionalValue(_breedController.text),
      ageDescription: _optionalValue(_ageDescriptionController.text),
      gender: _selectedGender!.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      imageAsset: _optionalValue(_imageAssetController.text),
      status: status,
      contactNote: _optionalValue(_contactNoteController.text),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save({required String status}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecies == null) {
      _showError('Please select a species.');
      return;
    }

    if (_selectedGender == null) {
      _showError('Please select a gender.');
      return;
    }

    final listing = _buildListing(status: status);

    final result = _isEditing
        ? await _controller.update(listing)
        : await _controller.create(listing) != null;

    if (!mounted) {
      return;
    }

    final errorMessage = _controller.errorMessage;

    if (errorMessage != null) {
      _showError(errorMessage);
      return;
    }

    if (!result) {
      _showError('Unable to save the adoption listing.');
      return;
    }

    _hasChanges = false;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            status == 'draft'
                ? 'Adoption listing saved as draft.'
                : 'Adoption listing published.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

    Navigator.pop(context);
  }

  Future<void> _handleBack() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
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
      return 'Please enter the pet name.';
    }

    if (name.length < 2) {
      return 'Please enter a valid pet name.';
    }

    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter $fieldName.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _controller.isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_controller.isLoading) {
          _handleBack();
        }
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final isLoading = _controller.isLoading;

          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              leading: IconButton(
                onPressed: isLoading ? null : _handleBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                _isEditing
                    ? 'Edit Adoption Listing'
                    : 'Create Adoption Listing',
              ),
            ),
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
                            ? 'Update Your Listing'
                            : 'Create Your Listing',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.espresso,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isEditing
                            ? 'Keep the adoption information accurate and up to date.'
                            : 'Provide the details adopters need to understand this listing.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.deepBrown, height: 1.45),
                      ),
                      const SizedBox(height: 20),

                      const _FieldLabel(
                        label: 'Pet / Listing Name',
                        required: true,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _petNameController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Buddy',
                          prefixIcon: Icon(
                            Icons.pets_outlined,
                            color: AppTheme.deepBrown,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SelectionField(
                              label: 'Species',
                              value: _selectedSpecies,
                              hintText: 'Select species',
                              icon: Icons.pets_outlined,
                              options: _speciesOptions,
                              enabled: !isLoading,
                              onSelected: _setSpecies,
                              validator: (value) =>
                                  _validateRequired(value, 'species'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel(label: 'Breed'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _breedController,
                                  enabled: !isLoading,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Labrador',
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
                                      color: AppTheme.deepBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel(label: 'Age'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _ageDescriptionController,
                                  enabled: !isLoading,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 2 years',
                                    prefixIcon: Icon(
                                      Icons.cake_outlined,
                                      color: AppTheme.deepBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SelectionField(
                              label: 'Gender',
                              value: _selectedGender,
                              hintText: 'Select gender',
                              icon: Icons.person_outline_rounded,
                              options: _genderOptions,
                              enabled: !isLoading,
                              onSelected: _setGender,
                              validator: (value) =>
                                  _validateRequired(value, 'gender'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const _FieldLabel(label: 'Location', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'location'),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Colombo',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.deepBrown,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const _FieldLabel(label: 'Description', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !isLoading,
                        minLines: 4,
                        maxLines: 7,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            _validateRequired(value, 'description'),
                        decoration: const InputDecoration(
                          hintText: 'Describe the pet, temperament, background and adoption information.',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 72),
                            child: Icon(
                              Icons.description_outlined,
                              color: AppTheme.deepBrown,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const _FieldLabel(label: 'Contact Note'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _contactNoteController,
                        enabled: !isLoading,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Optional information about how adopters should contact you.',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 34),
                            child: Icon(
                              Icons.contact_phone_outlined,
                              color: AppTheme.deepBrown,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const _FieldLabel(label: 'Image Asset / URL'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _imageAssetController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Optional image asset or URL',
                          prefixIcon: Icon(
                            Icons.image_outlined,
                            color: AppTheme.deepBrown,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _save(status: 'draft'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppTheme.deepBrown,
                                side: const BorderSide(
                                  color: AppTheme.secondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Save Draft',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _save(status: 'available'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isEditing
                                          ? 'Publish Changes'
                                          : 'Publish',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.icon,
    required this.options,
    required this.enabled,
    required this.onSelected,
    required this.validator,
  });

  final String label;
  final String? value;
  final String hintText;
  final IconData icon;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
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
        ),
      ],
    );
  }
}
