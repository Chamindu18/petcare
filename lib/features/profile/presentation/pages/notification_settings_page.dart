import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({
    super.key,
    required this.profile,
    this.profileRepository,
  });

  final UserProfile profile;
  final ProfileRepository? profileRepository;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final ProfileProvider _profileProvider;

  late bool _notificationsEnabled;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _profileProvider = ProfileProvider(
      repository: widget.profileRepository ?? FirebaseProfileRepository(),
    );

    _notificationsEnabled = widget.profile.notificationEnabled;
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  Future<void> _saveNotificationPreference(bool enabled) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;
      _isSaving = true;
    });

    try {
      await _profileProvider.updateNotificationPreference(enabled: enabled);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings updated successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsEnabled = !enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update notification settings. Please try again.',
          ),
        ),
      );
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
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose whether PetCare+ can send you notifications.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown),
          ),
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: const Text('Allow Notifications'),
              subtitle: Text(
                _notificationsEnabled
                    ? 'Notifications are enabled.'
                    : 'Notifications are disabled.',
              ),
              value: _notificationsEnabled,
              onChanged: _isSaving ? null : _saveNotificationPreference,
              secondary: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.deepBrown,
              ),
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
