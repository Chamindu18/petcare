import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../../domain/entities/qr_health_passport.dart';
import '../../domain/repositories/qr_health_passport_repository.dart';

class OwnerQrHealthPassportArgs {
  const OwnerQrHealthPassportArgs({
    required this.petId,
    required this.petName,
    required this.appointmentId,
  });

  final String petId;
  final String petName;
  final String appointmentId;
}

class OwnerQrHealthPassportPage extends StatefulWidget {
  const OwnerQrHealthPassportPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.appointmentId,
    required this.repository,
    this.auth,
  });

  final String petId;
  final String petName;
  final String appointmentId;
  final QrHealthPassportRepository repository;
  final FirebaseAuth? auth;

  @override
  State<OwnerQrHealthPassportPage> createState() =>
      _OwnerQrHealthPassportPageState();
}

class _OwnerQrHealthPassportPageState extends State<OwnerQrHealthPassportPage> {
  QrHealthPassport? _passport;
  String? _error;
  bool _loading = true;
  Timer? _timer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = widget.auth ?? FirebaseAuth.instance;
    final initialUid = auth.currentUser?.uid;
    _authSubscription = auth.userChanges().listen((user) {
      if (user?.uid != initialUid && mounted) {
        setState(() {
          _passport = null;
          _error = 'Your session changed. Open the appointment again.';
          _loading = false;
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _passport != null) setState(() {});
    });
    _generate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _generate({bool replace = false}) async {
    final previous = _passport;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (replace && previous != null && !previous.isRevoked) {
        await widget.repository.revokeQrReference(previous.token);
        if (mounted) setState(() => _passport = null);
      }
      final passport = await widget.repository.createQrReference(
        petId: widget.petId,
        appointmentId: widget.appointmentId,
      );
      if (!mounted) return;
      setState(() => _passport = passport);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke() async {
    final passport = _passport;
    if (passport == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.revokeQrReference(passport.token);
      if (!mounted) return;
      setState(() {
        _passport = null;
        _error = 'This QR code has been revoked.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passport = _passport;
    final remaining = passport == null
        ? Duration.zero
        : passport.expiresAt.difference(DateTime.now());
    final expired = remaining <= Duration.zero;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const PetCareSecondaryAppBar(title: 'QR Health Passport'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(
            petName: widget.petName,
            appointmentId: widget.appointmentId,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (passport != null && !expired) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: QrHealthPassportPayload.encode(passport.token),
                    size: 250,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Expires in ${_remaining(remaining)}',
                    style: const TextStyle(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Valid until ${_formatTime(passport.expiresAt)}',
                    style: const TextStyle(color: AppTheme.deepBrown),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _generate(replace: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Generate a new QR'),
            ),
            TextButton.icon(
              onPressed: _revoke,
              icon: const Icon(Icons.block_rounded),
              label: const Text('Revoke QR'),
            ),
          ] else ...[
            _MessageCard(
              message: expired
                  ? 'This QR code has expired. Generate a new one when the veterinarian is ready to scan.'
                  : (_error ?? 'Unable to generate the QR Health Passport.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Generate QR'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'The QR contains only a temporary random reference. The scanner must be signed in and authorized for this appointment before health information is released.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.deepBrown, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _remaining(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 15 * 60);
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.petName, required this.appointmentId});

  final String petName;
  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.pets_rounded)),
        title: Text(
          petName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Appointment ${_shortId(appointmentId)}'),
      ),
    );
  }

  String _shortId(String value) => value.length <= 10
      ? value.toUpperCase()
      : value.substring(0, 10).toUpperCase();
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
