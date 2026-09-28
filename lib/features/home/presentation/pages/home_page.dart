import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../notifications/data/repositories/firebase_notification_repository.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/presentation/providers/pets_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.petsController,
    required this.onMyPetsTap,
    required this.onAddPetTap,
    required this.userName,
    required this.photoUrl,
    super.key,
  });

  final PetsController petsController;
  final VoidCallback onMyPetsTap;
  final VoidCallback onAddPetTap;
  final String userName;
  final String? photoUrl;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final NotificationProvider _notificationProvider;

  PetsController get _petsController => widget.petsController;

  @override
  void initState() {
    super.initState();

    _petsController.addListener(_onPetsControllerChanged);

    _notificationProvider = NotificationProvider(
      repository: FirebaseNotificationRepository(),
    );

    _petsController.loadPets();
    _notificationProvider.startListening();
  }

  @override
  void dispose() {
    _petsController.removeListener(_onPetsControllerChanged);
    _notificationProvider.dispose();
    super.dispose();
  }

  void _onPetsControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openNotifications() {
    Navigator.pushNamed(context, AppRouter.notifications);
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 16) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _HomeBackground()),
            RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.white,
              onRefresh: () async {
                await _petsController.loadPets();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _HomeHeader(
                          userName: widget.userName,
                          photoUrl: widget.photoUrl,
                          unreadCount: _notificationProvider.unreadCount,
                          onNotificationsTap: _openNotifications,
                        ),
                        const SizedBox(height: 22),
                        _GreetingSection(
                          greeting: _greeting,
                          userName: widget.userName,
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'Your Pets',
                          actionLabel: _petsController.pets.isNotEmpty
                              ? 'See All'
                              : null,
                          onActionTap: _petsController.pets.isNotEmpty
                              ? widget.onMyPetsTap
                              : null,
                        ),
                        const SizedBox(height: 10),
                        _PetsSection(
                          controller: _petsController,
                          onAddPetTap: widget.onAddPetTap,
                        ),
                        const SizedBox(height: 24),
                        const _SectionHeader(
                          title: 'Quick Actions',
                          actionLabel: 'See All',
                        ),
                        const SizedBox(height: 10),
                        _QuickActions(onNotificationsTap: _openNotifications),
                        const SizedBox(height: 24),
                        const _SectionHeader(
                          title: 'Upcoming Appointment',
                          actionLabel: 'See All',
                        ),
                        const SizedBox(height: 10),
                        const _EmptyAppointmentCard(),
                        const SizedBox(height: 24),
                        const _SectionHeader(title: 'More for Your Pets'),
                        const SizedBox(height: 10),
                        const _HelpfulResources(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _HomeBackgroundPainter());
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-right soft shape.
    paint.color = AppTheme.secondary.withValues(alpha: 0.13);
    canvas.drawCircle(Offset(size.width - 12, 56), 72, paint);

    paint.color = AppTheme.secondary.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width - 62, 94), 42, paint);

    // Mid-right organic shape.
    paint.color = AppTheme.primary.withValues(alpha: 0.055);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width + 10, size.height * 0.47),
        width: 180,
        height: 240,
      ),
      paint,
    );

    // Bottom-left soft shape.
    paint.color = AppTheme.secondary.withValues(alpha: 0.11);
    canvas.drawCircle(Offset(-18, size.height - 92), 92, paint);

    paint.color = AppTheme.primary.withValues(alpha: 0.045);
    canvas.drawCircle(Offset(46, size.height - 26), 54, paint);

    // Small decorative soft circles.
    paint.color = AppTheme.deepBrown.withValues(alpha: 0.035);
    canvas.drawCircle(Offset(size.width - 34, size.height * 0.70), 20, paint);

    canvas.drawCircle(Offset(size.width - 78, size.height * 0.72), 11, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.photoUrl,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  final String userName;
  final String? photoUrl;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: Image.asset(
              'assets/branding/petcare_logo.png',
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              tooltip: 'Notifications',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.secondary.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                minimumSize: const Size(46, 46),
                fixedSize: const Size(46, 46),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.espresso,
                size: 25,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 19,
                    minHeight: 19,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.background, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl == null
              ? const Icon(
                  Icons.person_rounded,
                  color: AppTheme.deepBrown,
                  size: 24,
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_rounded,
                      color: AppTheme.deepBrown,
                      size: 24,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Greeting
// -----------------------------------------------------------------------------

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.greeting, required this.userName});

  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName! 👋',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.espresso,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.06,
            letterSpacing: -0.65,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'How are your pets doing today?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.deepBrown,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Section header
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.espresso,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: const Color.fromARGB(
                  255,
                  117,
                  76,
                  50,
                ).withValues(alpha: 0.72),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Pets
// -----------------------------------------------------------------------------

class _PetsSection extends StatelessWidget {
  const _PetsSection({required this.controller, required this.onAddPetTap});

  final PetsController controller;
  final VoidCallback onAddPetTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.pets.isEmpty) {
          return const _PetsLoadingCard();
        }

        if (controller.errorMessage != null && controller.pets.isEmpty) {
          return _PetsErrorCard(message: controller.errorMessage!);
        }

        if (controller.pets.isEmpty) {
          return _NoPetsCard(onAddPetTap: onAddPetTap);
        }

        return SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 4),
            itemCount: controller.pets.length + 1,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 10);
            },
            itemBuilder: (context, index) {
              if (index == controller.pets.length) {
                return _AddPetSlot(onTap: onAddPetTap);
              }

              return _PetCard(pet: controller.pets[index]);
            },
          ),
        );
      },
    );
  }
}

class _PetsLoadingCard extends StatelessWidget {
  const _PetsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );
  }
}

class _PetsErrorCard extends StatelessWidget {
  const _PetsErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.deepBrown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  const _NoPetsCard({required this.onAddPetTap});

  final VoidCallback onAddPetTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBrown.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.pets_rounded,
                color: AppTheme.primary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No pets yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Add your first pet to start managing '
                  'their health and care.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onAddPetTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppTheme.primary,
                          size: 19,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Add Pet',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPetSlot extends StatelessWidget {
  const _AddPetSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.30),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Pet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.espresso,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'New companion',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.deepBrown.withValues(alpha: 0.70),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final hasImage = pet.imageUrl.trim().isNotEmpty;

    return Container(
      width: 148,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBrown.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: double.infinity,
              height: 105,
              child: hasImage
                  ? Image.network(
                      pet.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _PetImageFallback();
                      },
                    )
                  : const _PetImageFallback(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.espresso,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              pet.ageInYears == 1
                  ? '1 year old'
                  : '${pet.ageInYears} years old',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.deepBrown,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetImageFallback extends StatelessWidget {
  const _PetImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.secondary.withValues(alpha: 0.16),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: AppTheme.deepBrown, size: 34),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Quick actions
// -----------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: [
        _QuickActionCard(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'View updates',
          enabled: true,
          onTap: onNotificationsTap,
        ),
        const _QuickActionCard(
          icon: Icons.calendar_month_rounded,
          title: 'Appointments',
          subtitle: 'Coming soon',
        ),
        const _QuickActionCard(
          icon: Icons.psychology_rounded,
          title: 'AI Assistant',
          subtitle: 'Coming soon',
        ),
        const _QuickActionCard(
          icon: Icons.location_on_rounded,
          title: 'Find Vets',
          subtitle: 'Coming soon',
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? AppTheme.white : AppTheme.deepBrown;

    final iconBackground = enabled
        ? AppTheme.primary
        : AppTheme.secondary.withValues(alpha: 0.18);

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled
                            ? AppTheme.espresso
                            : AppTheme.deepBrown.withValues(alpha: 0.74),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? AppTheme.deepBrown
                            : AppTheme.deepBrown.withValues(alpha: 0.58),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Appointment
// -----------------------------------------------------------------------------

class _EmptyAppointmentCard extends StatelessWidget {
  const _EmptyAppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBrown.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.deepBrown,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No appointments yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your upcoming appointments will appear here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.deepBrown,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helpful resources
// -----------------------------------------------------------------------------

class _HelpfulResources extends StatelessWidget {
  const _HelpfulResources();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ResourceCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Pet Care Tips',
            subtitle: 'Helpful guidance',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ResourceCard(
            icon: Icons.favorite_border_rounded,
            title: 'Adoption',
            subtitle: 'Coming soon',
          ),
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBrown, size: 21),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
