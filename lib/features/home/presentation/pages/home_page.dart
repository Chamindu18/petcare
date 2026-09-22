import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../notifications/data/repositories/firebase_notification_repository.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../pets/data/repositories/firebase_pet_repository.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/usecases/create_pet.dart';
import '../../../pets/domain/usecases/delete_pet.dart';
import '../../../pets/domain/usecases/get_pets.dart';
import '../../../pets/domain/usecases/update_pet.dart';
import '../../../pets/presentation/providers/pets_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PetsController _petsController;
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();

    final petsRepository = FirebasePetRepository();

    _petsController = PetsController(
      CreatePet(petsRepository),
      GetPets(petsRepository),
      UpdatePet(petsRepository),
      DeletePet(petsRepository),
    );

    _notificationProvider = NotificationProvider(
      repository: FirebaseNotificationRepository(),
    );

    _petsController.loadPets();
    _notificationProvider.startListening();
  }

  @override
  void dispose() {
    _petsController.dispose();
    _notificationProvider.dispose();
    super.dispose();
  }

  void _openNotifications() {
    Navigator.pushNamed(context, AppRouter.notifications);
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName == null || displayName.isEmpty) {
      return 'Pet Owner';
    }

    return displayName;
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.white,
          onRefresh: () async {
            await _petsController.loadPets();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HomeHeader(
                      userName: _userName,
                      unreadCount: _notificationProvider.unreadCount,
                      onNotificationsTap: _openNotifications,
                    ),
                    const SizedBox(height: 22),
                    _GreetingSection(greeting: _greeting, userName: _userName),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: 'Your Pets',
                      actionLabel: _petsController.pets.isNotEmpty
                          ? 'View All'
                          : null,
                      onActionTap: null,
                    ),
                    const SizedBox(height: 12),
                    _PetsSection(controller: _petsController),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    _QuickActions(onNotificationsTap: _openNotifications),
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      title: 'Upcoming Appointments',
                      actionLabel: 'See All',
                    ),
                    const SizedBox(height: 12),
                    const _EmptyAppointmentCard(),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Helpful Resources'),
                    const SizedBox(height: 12),
                    const _HelpfulResources(),
                  ]),
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
// Header
// -----------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  final String userName;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: Image.asset(
              'assets/branding/petcare_logo.png',
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'PetCare+ logo',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              tooltip: 'Notifications',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.secondary.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                minimumSize: const Size(44, 44),
                fixedSize: const Size(44, 44),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.espresso,
                size: 24,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.24),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.deepBrown,
            size: 23,
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
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.espresso,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Let's give your pets the best care together.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.deepBrown,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: onActionTap == null
                  ? AppTheme.deepBrown.withValues(alpha: 0.45)
                  : AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 11.5,
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
  const _PetsSection({required this.controller});

  final PetsController controller;

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
          return const _NoPetsCard();
        }

        return SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.pets.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
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
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  const _NoPetsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppTheme.deepBrown,
              size: 29,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No pets yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Add your first pet to start managing their '
            'health and care.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.primary, size: 19),
                SizedBox(width: 6),
                Text(
                  'Add Pet',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final hasImage = pet.imageUrl.trim().isNotEmpty;

    return Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 92,
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
          Text(
            pet.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.espresso,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pet.ageInYears == 1 ? '1 year old' : '${pet.ageInYears} years old',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
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
        child: Icon(Icons.pets_rounded, color: AppTheme.deepBrown, size: 32),
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
      childAspectRatio: 2.5,
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? AppTheme.espresso
                            : AppTheme.deepBrown.withValues(alpha: 0.70),
                        fontSize: 11,
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
                            : AppTheme.deepBrown.withValues(alpha: 0.55),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
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
// Appointments empty state
// -----------------------------------------------------------------------------

class _EmptyAppointmentCard extends StatelessWidget {
  const _EmptyAppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.deepBrown,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No appointments yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your upcoming appointments will appear here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

// -----------------------------------------------------------------------------
// Helpful resources
// -----------------------------------------------------------------------------

class _HelpfulResources extends StatelessWidget {
  const _HelpfulResources();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
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
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBrown, size: 20),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.espresso,
                    fontSize: 11.5,
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
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
