import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/pages/veterinarian_appointment_details_page.dart';
import '../../../appointments/presentation/pages/veterinarian_appointments_page.dart';
import '../../../appointments/presentation/widgets/veterinarian_appointment_card.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../queue/domain/repositories/queue_repository.dart';
import '../providers/veterinarian_workspace_controller.dart';
import 'veterinarian_queue_page.dart';
import 'veterinarian_self_profile_page.dart';

class VeterinarianDashboardPage extends StatefulWidget {
  const VeterinarianDashboardPage({
    super.key,
    required this.profile,
    this.controller,
    this.authRepository,
    this.queueRepository,
  });

  final UserProfile profile;
  final VeterinarianWorkspaceController? controller;
  final AuthRepository? authRepository;
  final VeterinarianQueueRepository? queueRepository;

  @override
  State<VeterinarianDashboardPage> createState() =>
      _VeterinarianDashboardPageState();
}

class _VeterinarianDashboardPageState extends State<VeterinarianDashboardPage> {
  late final VeterinarianWorkspaceController _controller;
  late final AuthRepository _authRepository;
  late final bool _ownsController;

  int _selectedIndex = 0;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? VeterinarianWorkspaceController.production();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();

    _controller.bindSession(widget.profile.uid);
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant VeterinarianDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid) {
      _controller.bindSession(widget.profile.uid);
      _controller.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  String get _appBarTitle {
    return switch (_selectedIndex) {
      0 => 'Dashboard',
      1 => 'Appointments',
      2 => 'Queue',
      _ => 'My Profile',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _selectedIndex != 0) {
              setState(() => _selectedIndex = 0);
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                _appBarTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: _openNotifications,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.deepBrown,
                  ),
                ),
                if (_selectedIndex == 0 || _selectedIndex == 1)
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _controller.isLoading
                        ? null
                        : _controller.refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.deepBrown,
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(context),
            bottomNavigationBar: NavigationBar(
              height: 68,
              backgroundColor: AppTheme.white,
              indicatorColor: AppTheme.secondary.withValues(alpha: 0.42),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Appointments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Queue',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_controller.loadErrorMessage != null) {
      return _buildLoadError();
    }

    return Column(
      children: [
        if (_controller.hospitalWarning != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_controller.hospitalWarning!),
          ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(context),
              VeterinarianAppointmentsPage(
                appointments: _controller.appointments,
                serviceNameFor: _controller.serviceNameFor,
                isLoading: _controller.isLoading,
                onRefresh: _controller.refresh,
                errorMessage: _controller.loadErrorMessage,
                actionErrorMessage: _controller.actionErrorMessage,
                onOpenDetails: _openDetails,
                embedded: true,
              ),
              _buildQueueTab(context),
              VeterinarianSelfProfilePage(
                controller: _controller,
                profile: widget.profile,
                authRepository: _authRepository,
                embedded: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadError() {
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
          _controller.loadErrorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.espresso),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _buildWelcomeHeader(context),
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
            count: _controller.todayCount,
            subtitle: 'Your appointments scheduled for today',
          ),
          const SizedBox(height: 12),
          if (_controller.todayAppointments.isEmpty)
            _emptyState(
              'No appointments scheduled for today.',
              Icons.event_available_outlined,
            )
          else
            ..._controller.todayAppointments.take(4).map(_buildAppointmentCard),
          const SizedBox(height: 24),
          _sectionTitle('Queue overview', subtitle: 'Hospital queue snapshot'),
          const SizedBox(height: 12),
          _buildQueuePreview(),
          const SizedBox(height: 24),
          _sectionTitle(
            'Upcoming appointments',
            count: _controller.upcomingCount,
            subtitle: 'Your next scheduled visits',
          ),
          const SizedBox(height: 12),
          if (_controller.upcomingAppointments.isEmpty)
            _emptyState(
              'No upcoming appointments.',
              Icons.calendar_month_outlined,
            )
          else
            ..._controller.upcomingAppointments
                .take(4)
                .map(_buildAppointmentCard),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final imageUrl = _imageUrl;

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
            backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
            child: imageUrl == null
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
                        _controller.veterinarian == null
                            ? 'Veterinarian'
                            : _controller.hospitalName,
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
          Tooltip(
            message: 'Log out',
            child: InkWell(
              onTap: _isSigningOut ? null : _confirmLogout,
              borderRadius: BorderRadius.circular(19),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: _isSigningOut
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.deepBrown,
                        size: 20,
                      ),
              ),
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
            value: '${_controller.todayCount}',
            icon: Icons.today_rounded,
            accent: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _OverviewCard(
            label: 'Pending',
            value: '${_controller.pendingCount}',
            icon: Icons.hourglass_top_rounded,
            accent: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _OverviewCard(
            label: 'Upcoming',
            value: '${_controller.upcomingCount}',
            icon: Icons.event_available_rounded,
            accent: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = <Widget>[
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Appointments',
        onTap: () => _selectTab(1),
      ),
      _QuickAction(
        icon: Icons.groups_rounded,
        label: 'Manage Queue',
        onTap: () => _selectTab(2),
      ),
      _QuickAction(
        icon: Icons.person_outline_rounded,
        label: 'My Profile',
        onTap: () => _selectTab(3),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(width: itemWidth, child: action),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return VeterinarianAppointmentCard(
      appointment: appointment,
      serviceName: _controller.serviceNameFor(appointment.serviceId),
      onTap: () => _openDetails(appointment),
    );
  }

  Widget _buildQueuePreview() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTab(2),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            children: [
              _QueueIcon(),
              SizedBox(width: 12),
              Expanded(
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
                      'View and manage your assigned patients.',
                      style: TextStyle(color: AppTheme.deepBrown, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.deepBrown),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueTab(BuildContext context) {
    final veterinarian = _controller.veterinarian;
    if (veterinarian == null) {
      return const Center(
        child: Text('Veterinarian assignment is unavailable.'),
      );
    }
    return VeterinarianQueuePage(
      hospitalId: veterinarian.hospitalId,
      veterinarianId: veterinarian.vetId,
      isActive: _selectedIndex == 2,
      queueRepository: widget.queueRepository,
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

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openNotifications() async {
    await _controller.refresh();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          onOpenAppointmentById: _openNotificationAppointment,
        ),
      ),
    );
  }

  void _openNotificationAppointment(String appointmentId) {
    final appointment = _controller.appointmentById(appointmentId);
    if (appointment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment access is no longer available.'),
        ),
      );
      return;
    }
    _openDetails(appointment);
  }

  void _openDetails(Appointment appointment) {
    final sessionRevision = _controller.sessionRevision;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (sessionRevision != _controller.sessionRevision ||
                _controller.appointmentById(appointment.appointmentId) ==
                    null ||
                _controller.loadErrorMessage != null) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(
                  child: Text('Appointment access is no longer available.'),
                ),
              );
            }
            return VeterinarianAppointmentDetailsPage(
              appointment: appointment,
              serviceName: _controller.serviceNameFor(appointment.serviceId),
              hospitalName: _controller.hospital?.name,
              onConfirm: _controller.confirmAppointment,
              onReject: _controller.rejectAppointment,
              onManageQueue: () {
                Navigator.of(context).pop();
                _selectTab(2);
              },
              actionErrorProvider: () => _controller.actionErrorMessage,
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isSigningOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of your PetCare+ account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted || _isSigningOut) return;

    setState(() => _isSigningOut = true);

    try {
      await _authRepository.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    } catch (error) {
      debugPrint('Veterinarian logout failed: ${error.runtimeType}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  String get _displayName {
    final vetName = _controller.veterinarian?.name.trim() ?? '';

    if (vetName.isNotEmpty) return vetName;

    final fullName = widget.profile.fullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final displayName = widget.profile.displayName.trim();
    return displayName.isNotEmpty ? displayName : 'Veterinarian';
  }

  String? get _imageUrl {
    final vetImage = _controller.veterinarian?.profileImageUrl?.trim();

    if (vetImage != null && vetImage.isNotEmpty) return vetImage;

    final accountImage = widget.profile.photoUrl?.trim();
    return accountImage == null || accountImage.isEmpty ? null : accountImage;
  }

  String get _greeting {
    final hour = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30))
        .hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
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
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.espresso,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueIcon extends StatelessWidget {
  const _QueueIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.people_alt_outlined, color: AppTheme.primary),
    );
  }
}
