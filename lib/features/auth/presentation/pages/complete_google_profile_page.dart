import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/auth_shared.dart';
import '../../domain/repositories/auth_repository.dart';

class CompleteGoogleProfilePage extends StatefulWidget {
  const CompleteGoogleProfilePage({
    super.key,
    required this.onComplete,
    required this.onSignOut,
    this.initialName = '',
  });

  final Future<void> Function(String fullName) onComplete;
  final Future<void> Function() onSignOut;
  final String initialName;

  @override
  State<CompleteGoogleProfilePage> createState() =>
      _CompleteGoogleProfilePageState();
}

class _CompleteGoogleProfilePageState extends State<CompleteGoogleProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onComplete(_nameController.text.trim());
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to save your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.onSignOut();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign out. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/branding/petcare_logo.png', width: 120),
                  const SizedBox(height: 24),
                  Text(
                    'What should we call you?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your full name to finish setting up your pet owner profile.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const AuthFieldLabel(label: 'Full name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Please enter your full name'
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Your full name',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text('Save profile'),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
