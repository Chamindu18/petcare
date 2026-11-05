import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../providers/veterinarian_workspace_controller.dart';

class VeterinarianEditProfilePage extends StatefulWidget {
  const VeterinarianEditProfilePage({super.key, required this.controller});

  final VeterinarianWorkspaceController controller;

  @override
  State<VeterinarianEditProfilePage> createState() =>
      _VeterinarianEditProfilePageState();
}

class _VeterinarianEditProfilePageState
    extends State<VeterinarianEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;

  String? _existingImageUrl;
  Uint8List? _selectedImageBytes;
  bool _removeExistingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final veterinarian = widget.controller.veterinarian;

    _nameController = TextEditingController(text: veterinarian?.name ?? '');
    _specialtyController = TextEditingController(
      text: veterinarian?.specialty ?? '',
    );
    _qualificationsController = TextEditingController(
      text: veterinarian?.qualifications ?? '',
    );
    _experienceController = TextEditingController(
      text: veterinarian?.experienceYears?.toString() ?? '',
    );
    _bioController = TextEditingController(text: veterinarian?.bio ?? '');
    _existingImageUrl = veterinarian?.profileImageUrl?.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const PetCareSecondaryAppBar(title: 'Edit Profile'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            _buildPhotoCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Professional details'),
            const SizedBox(height: 10),
            _buildField(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name.';
                }

                if (value.trim().length > 120) {
                  return 'Name must be 120 characters or fewer.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _specialtyController,
              label: 'Specialty',
              icon: Icons.medical_services_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().length > 120) {
                  return 'Specialty must be 120 characters or fewer.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _qualificationsController,
              label: 'Qualifications',
              icon: Icons.school_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return 'Qualifications must be 200 characters or fewer.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _experienceController,
              label: 'Years of experience',
              icon: Icons.work_outline_rounded,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) return null;

                final years = int.tryParse(text);

                if (years == null || years < 0 || years > 80) {
                  return 'Enter a number between 0 and 80.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _bioController,
              label: 'About',
              icon: Icons.info_outline_rounded,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value != null && value.trim().length > 1000) {
                  return 'About must be 1000 characters or fewer.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Your name and professional details are visible to pet owners '
              'when they view your veterinary profile.',
              style: TextStyle(
                color: AppTheme.deepBrown.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _save,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSubmitting ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.background,
            backgroundImage: _selectedImageBytes != null
                ? MemoryImage(_selectedImageBytes!)
                : _showExistingImage
                ? NetworkImage(_existingImageUrl!)
                : null,
            child: _selectedImageBytes == null && !_showExistingImage
                ? const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: AppTheme.deepBrown,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isSubmitting ? null : _chooseImageSource,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Change photo'),
              ),
              if (_selectedImageBytes != null || _showExistingImage)
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _showExistingImage {
    final url = _existingImageUrl;
    return !_removeExistingImage &&
        _selectedImageBytes == null &&
        url != null &&
        url.isNotEmpty;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppTheme.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
    );
  }

  Future<void> _chooseImageSource() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update profile photo',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Take a photo'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (!mounted || image == null) return;

      final bytes = await image.readAsBytes();
      const maxImageSize = 5 * 1024 * 1024;

      if (bytes.length > maxImageSize) {
        _showMessage('Please choose an image smaller than 5 MB.');
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _removeExistingImage = false;
      });
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to select the profile image. Please try again.');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _removeExistingImage = true;
    });
  }

  Future<void> _save() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      if (_selectedImageBytes != null) {
        imageUrl = await widget.controller.uploadProfileImage(
          _selectedImageBytes!,
        );

        if (imageUrl == null) {
          _showMessage(
            widget.controller.profileErrorMessage ??
                'Unable to upload the profile image. Please try again.',
          );
          return;
        }
      } else if (_removeExistingImage) {
        imageUrl = null;
      } else {
        imageUrl = _existingImageUrl;
      }

      final experienceText = _experienceController.text.trim();

      final success = await widget.controller.updateProfessionalProfile(
        name: _nameController.text,
        profileImageUrl: imageUrl,
        specialty: _specialtyController.text,
        qualifications: _qualificationsController.text,
        experienceYears: experienceText.isEmpty
            ? null
            : int.parse(experienceText),
        bio: _bioController.text,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage(
          widget.controller.profileErrorMessage ??
              'Unable to update your profile. Please try again.',
        );
        return;
      }

      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
