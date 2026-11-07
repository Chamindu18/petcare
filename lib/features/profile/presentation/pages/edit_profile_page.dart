import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
    this.profileRepository,
  });

  final UserProfile profile;
  final ProfileRepository? profileRepository;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileProvider _profileProvider;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;

  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository: widget.profileRepository ?? FirebaseProfileRepository(),
    );

    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizeFullName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  }

  String? _validateFullName(String? value) {
    final fullName = _normalizeFullName(value ?? '');

    if (fullName.isEmpty) {
      return 'Full name is required.';
    }

    if (fullName.runes.length < 2) {
      return 'Full name must contain at least 2 characters.';
    }

    if (fullName.runes.length > 80) {
      return 'Full name must not exceed 80 characters.';
    }

    if (RegExp(r'\d').hasMatch(fullName)) {
      return 'Full name cannot contain numbers.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = _normalizePhone(value ?? '');

    // A phone number is optional for accounts without a contact number.
    if (phone.isEmpty) {
      return null;
    }

    final isLocalNumber = RegExp(r'^0[1-9]\d{8}$').hasMatch(phone);
    final isInternationalNumber = RegExp(r'^\+94[1-9]\d{8}$').hasMatch(phone);

    if (!isLocalNumber && !isInternationalNumber) {
      return 'Enter a valid Sri Lankan number '
          '(e.g. 0771234567 or +94771234567).';
    }

    return null;
  }

  Future<void> _saveProfile() async {
    // Protect against repeated submissions from any entry point.
    if (_isSaving) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final fullName = _normalizeFullName(_fullNameController.text);
    final phone = _normalizePhone(_phoneController.text);

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileProvider.updateProfile(fullName: fullName, phone: phone);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ProfileRepositoryException
          ? error.message
          : 'Unable to update your profile. Please try again.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your name and contact details.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              maxLength: 80,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateFullName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '0771234567 or +94771234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
              onFieldSubmitted: (_) => _saveProfile(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.65,
                  ),
                  disabledForegroundColor: AppTheme.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.white,
                          ),
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
