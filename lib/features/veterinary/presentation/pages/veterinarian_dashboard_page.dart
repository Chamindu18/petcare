import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../appointments/data/repositories/firebase_appointment_repository.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/usecases/appointment_usecases.dart';
import '../../../hospitals/data/repositories/firebase_hospital_repository.dart';
import '../../../hospitals/domain/entities/hospital.dart';
import '../../../hospitals/domain/usecases/hospital_usecases.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/repositories/firebase_veterinarian_assignment_repository.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/usecases/get_current_veterinarian_assignment.dart';
import '../../../appointments/presentation/pages/veterinarian_appointments_page.dart';

class VeterinarianDashboardPage extends StatefulWidget {
  const VeterinarianDashboardPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<VeterinarianDashboardPage> createState() =>
      _VeterinarianDashboardPageState();
}

class _VeterinarianDashboardPageState extends State<VeterinarianDashboardPage> {
  late final GetAppointmentsByVeterinarian _getAppointments;
  late final GetCurrentVeterinarianAssignment _getAssignment;
  late final GetHospitalById _getHospital;

  List<Appointment> _appointments = [];
  Veterinarian? _veterinarian;
  Hospital? _hospital;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _getAppointments = GetAppointmentsByVeterinarian(
      FirebaseAppointmentRepository(),
    );

    _getAssignment = GetCurrentVeterinarianAssignment(
      FirebaseVeterinarianAssignmentRepository(),
    );

    _getHospital = GetHospitalById(FirebaseHospitalRepository());

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assignment = await _getAssignment();
      if (assignment == null) {
        throw StateError(
          'Your active veterinarian assignment could not be verified.',
        );
      }
      final vetId = assignment.vetId;
      final hospitalId = assignment.hospitalId;
      final results = await Future.wait([
        Future.value(assignment),
        _getHospital(hospitalId),
        _getAppointments(vetId: vetId, hospitalId: hospitalId),
      ]);

      final veterinarian = results[0] as Veterinarian?;
      final hospital = results[1] as Hospital?;
      final appointments = results[2] as List<Appointment>;

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;

      setState(() {
        _veterinarian = veterinarian;
        _hospital = hospital;
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard information. Please check your connection and try again.';
      });

      debugPrint('Veterinarian dashboard error: $error');
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isTerminal(String status) {
    final normalized = status.toLowerCase();

    return normalized == 'cancelled' || normalized == 'rejected';
  }

  List<Appointment> get _todayAppointments {
    final now = DateTime.now();

    return _appointments.where((appointment) {
      return _sameDay(appointment.dateTime, now) &&
          !_isTerminal(appointment.status);
    }).toList();
  }

  List<Appointment> get _upcomingAppointments {
    final now = DateTime.now();

    return _appointments.where((appointment) {
      return appointment.dateTime.isAfter(now) &&
          !_sameDay(appointment.dateTime, now) &&
          !_isTerminal(appointment.status);
    }).toList();
  }

  int get _pendingCount {
    return _appointments
        .where((a) => a.status.toLowerCase() == 'pending')
        .length;
  }

  String get _displayName {
    final fullName = widget.profile.fullName.trim();
    final vetName = _veterinarian?.name.trim() ?? '';
    final displayName = widget.profile.displayName.trim();

    if (fullName.isNotEmpty) return fullName;
    if (vetName.isNotEmpty) return vetName;
    if (displayName.isNotEmpty) return displayName;

    return 'Veterinarian';
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.deepBrown),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadDashboard,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavigationPreview(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 520,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppTheme.deepBrown,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.espresso),
          ),
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _buildWelcomeHeader(),
        const SizedBox(height: 22),

        _sectionTitle(
          'Appointment overview',
          subtitle: 'Your schedule at a glance',
        ),
        const SizedBox(height: 12),
        _buildOverviewCards(),

        const SizedBox(height: 24),

        _sectionTitle('Quick actions', subtitle: 'Common tasks'),
        const SizedBox(height: 12),
        _buildQuickActions(),

        const SizedBox(height: 24),

        _sectionTitle(
          "Today's appointments",
          count: _todayAppointments.length,
          subtitle: 'Your appointments scheduled for today',
        ),
        const SizedBox(height: 12),

        if (_todayAppointments.isEmpty)
          _emptyState(
            'No appointments scheduled for today.',
            Icons.event_available_outlined,
          )
        else
          ..._todayAppointments.take(4).map(_buildAppointmentCard),

        const SizedBox(height: 24),

        _sectionTitle('Queue overview', subtitle: 'Hospital queue snapshot'),
        const SizedBox(height: 12),
        _buildQueuePreview(),

        const SizedBox(height: 24),

        _sectionTitle(
          'Upcoming appointments',
          count: _upcomingAppointments.length,
          subtitle: 'Your next scheduled visits',
        ),
        const SizedBox(height: 12),

        if (_upcomingAppointments.isEmpty)
          _emptyState(
            'No upcoming appointments.',
            Icons.calendar_month_outlined,
          )
        else
          ..._upcomingAppointments.take(4).map(_buildAppointmentCard),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    final imageUrl = _veterinarian?.profileImageUrl ?? widget.profile.photoUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: AppTheme.white,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 31,
                    color: AppTheme.deepBrown,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 3),
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_outlined,
                      size: 14,
                      color: AppTheme.deepBrown,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _hospital?.name ?? 'Veterinarian',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.deepBrown),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.deepBrown,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle, int? count}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
              ],
            ],
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            label: 'Today',
            value: '${_todayAppointments.length}',
            icon: Icons.today_rounded,
            accent: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _OverviewCard(
            label: 'Pending',
            value: '$_pendingCount',
            icon: Icons.hourglass_top_rounded,
            accent: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _OverviewCard(
            label: 'Upcoming',
            value: '${_upcomingAppointments.length}',
            icon: Icons.event_available_rounded,
            accent: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 9,
      mainAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        const _QuickAction(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan Pet QR',
        ),
        _QuickAction(
          icon: Icons.calendar_month_rounded,
          label: 'Appointments',
          onTap: () {
            if (_veterinarian == null || _hospital == null) return;

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VeterinarianAppointmentsPage(
                  vetId: _veterinarian!.vetId,
                  hospitalId: _hospital!.hospitalId,
                ),
              ),
            );
          },
        ),
        const _QuickAction(icon: Icons.groups_rounded, label: 'Manage Queue'),
        const _QuickAction(
          icon: Icons.person_outline_rounded,
          label: 'My Profile',
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isToday = _sameDay(appointment.dateTime, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppTheme.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday
                      ? 'Today · ${_formatTime(appointment.dateTime)}'
                      : _formatDate(appointment.dateTime),
                  style: const TextStyle(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pet appointment',
                  style: TextStyle(
                    color: AppTheme.deepBrown.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Appointment #${_shortId(appointment.appointmentId)}',
                  style: TextStyle(
                    color: AppTheme.deepBrown.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AppointmentStatus(status: appointment.status),
        ],
      ),
    );
  }

  Widget _buildQueuePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Queue management',
                  style: TextStyle(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Queue information will be available here.',
                  style: TextStyle(color: AppTheme.deepBrown, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.deepBrown),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppTheme.secondary),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.deepBrown, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationPreview() {
    return NavigationBar(
      height: 68,
      backgroundColor: AppTheme.white,
      indicatorColor: AppTheme.secondary.withValues(alpha: 0.42),
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} · ${_formatTime(dateTime)}';
  }

  String _shortId(String id) {
    return id.length <= 7 ? id : id.substring(0, 7).toUpperCase();
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 13, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.deepBrown,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.espresso,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentStatus extends StatelessWidget {
  const _AppointmentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final color = normalized == 'confirmed' || normalized == 'completed'
        ? AppTheme.success
        : normalized == 'pending'
        ? AppTheme.warning
        : normalized == 'cancelled' || normalized == 'rejected'
        ? AppTheme.error
        : AppTheme.information;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
