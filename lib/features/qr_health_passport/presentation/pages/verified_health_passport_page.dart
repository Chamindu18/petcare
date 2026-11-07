import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/petcare_secondary_app_bar.dart';
import '../../domain/entities/qr_health_passport.dart';
import '../../domain/repositories/qr_health_passport_repository.dart';

class VerifiedHealthPassportPage extends StatefulWidget {
  const VerifiedHealthPassportPage({
    super.key,
    required this.token,
    required this.repository,
    this.auth,
  });

  final String token;
  final QrHealthPassportRepository repository;
  final FirebaseAuth? auth;

  @override
  State<VerifiedHealthPassportPage> createState() =>
      _VerifiedHealthPassportPageState();
}

class _VerifiedHealthPassportPageState
    extends State<VerifiedHealthPassportPage> {
  QrHealthPassportData? _data;
  String? _error;
  StreamSubscription<User?>? _authSubscription;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    final auth = widget.auth ?? FirebaseAuth.instance;
    final initialUid = auth.currentUser?.uid;
    _authSubscription = auth.userChanges().listen((user) {
      if (user?.uid != initialUid && mounted) {
        setState(() {
          _data = null;
          _error = 'Your session changed. Scan the QR code again.';
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _data = null;
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await widget.repository.getPassportData(widget.token);
      if (!mounted) return;
      if (!data.passport.expiresAt.isAfter(DateTime.now())) {
        setState(
          () => _error = 'This passport has expired. Scan a new QR code.',
        );
        return;
      }
      _expiryTimer?.cancel();
      _expiryTimer = Timer(
        data.passport.expiresAt.difference(DateTime.now()),
        () {
          if (mounted) {
            setState(() {
              _data = null;
              _error = 'This passport has expired. Scan a new QR code.';
            });
          }
        },
      );
      setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = null;
          _error =
              'This passport is expired, revoked, or no longer authorized.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const PetCareSecondaryAppBar(title: 'Pet Health Passport'),
      body: data == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_clock_outlined, size: 56),
                          const SizedBox(height: 14),
                          Text(_error!, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _PetHeader(data: data),
                const SizedBox(height: 16),
                _AppointmentCard(data: data),
                const SizedBox(height: 18),
                _section(
                  'Medical conditions',
                  data.medicalConditions
                      .map(
                        (item) => _RecordTile(
                          title: item.name,
                          subtitle:
                              '${item.status} • Diagnosed ${_date(item.diagnosisDate)}',
                          notes: item.notes,
                        ),
                      )
                      .toList(),
                ),
                _section(
                  'Vaccinations',
                  data.vaccinations
                      .map(
                        (item) => _RecordTile(
                          title: item.name,
                          subtitle:
                              'Given ${_date(item.dateGiven)}${item.nextDueDate == null ? '' : ' • Next ${_date(item.nextDueDate!)}'}',
                          notes: item.notes,
                        ),
                      )
                      .toList(),
                ),
                _section(
                  'Treatments',
                  data.treatments
                      .map(
                        (item) => _RecordTile(
                          title: item.name,
                          subtitle:
                              '${item.status}${item.startDate == null ? '' : ' • Started ${_date(item.startDate!)}'}',
                          notes: item.notes,
                        ),
                      )
                      .toList(),
                ),
                _section(
                  'Health measurements',
                  data.measurements
                      .map(
                        (item) => _RecordTile(
                          title: '${item.type}: ${item.value} ${item.unit}',
                          subtitle: 'Recorded ${_date(item.recordedAt)}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Read-only appointment access. Information is shown exactly as recorded by the owner and is not a diagnosis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.deepBrown, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.espresso,
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            const Card(child: ListTile(title: Text('No records available.')))
          else
            ...children,
        ],
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.data});

  final QrHealthPassportData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, child: Icon(Icons.pets_rounded)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.petName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.espresso,
                  ),
                ),
                Text(
                  '${data.species} • ${data.breed} • ${_age(data.dateOfBirth)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _age(DateTime birthDate) {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (DateTime(now.year, birthDate.month, birthDate.day).isAfter(now)) {
      years--;
    }
    return years <= 0 ? 'Under 1 year' : '$years year${years == 1 ? '' : 's'}';
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.data});

  final QrHealthPassportData data;

  @override
  Widget build(BuildContext context) {
    final appointment = data.appointment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Associated appointment',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${appointment.dateTime.toLocal()}'),
            if (appointment.reason.trim().isNotEmpty)
              Text('Reason: ${appointment.reason}'),
            Text('Status: ${appointment.status}'),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.title, required this.subtitle, this.notes});

  final String title;
  final String subtitle;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$subtitle${notes == null || notes!.trim().isEmpty ? '' : '\n${notes!.trim()}'}',
        ),
      ),
    );
  }
}
