import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../pets/data/repositories/firebase_pet_repository.dart';
import '../../../pets/domain/usecases/create_pet.dart';
import '../../../pets/domain/usecases/delete_pet.dart';
import '../../../pets/domain/usecases/get_pets.dart';
import '../../../pets/domain/usecases/update_pet.dart';
import '../../../pets/presentation/pages/my_pets_page.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import 'home_page.dart';

class OwnerShellPage extends StatefulWidget {
  const OwnerShellPage({super.key});

  @override
  State<OwnerShellPage> createState() => _OwnerShellPageState();
}

class _OwnerShellPageState extends State<OwnerShellPage> {
  int _currentIndex = 0;

  late final PetsController _petsController;

  @override
  void initState() {
    super.initState();

    final repository = FirebasePetRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    _petsController = PetsController(
      CreatePet(repository),
      GetPets(repository),
      UpdatePet(repository),
      DeletePet(repository),
    );
  }

  @override
  void dispose() {
    _petsController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddPet() {
    Navigator.pushNamed(
      context,
      AppRouter.addPet,
      arguments: _petsController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            petsController: _petsController,
            onMyPetsTap: () => _onTabSelected(1),
            onAddPetTap: _openAddPet,
          ),
          MyPetsPage(
            controller: _petsController,
            ownsController: false,
          ),
          const _ComingSoonTab(
            title: 'Appointments',
            icon: Icons.calendar_month_rounded,
          ),
          const _ComingSoonTab(
            title: 'AI Hub',
            icon: Icons.psychology_rounded,
          ),
          const _ComingSoonTab(
            title: 'Profile',
            icon: Icons.person_rounded,
          ),
        ],
      ),
      bottomNavigationBar: _OwnerBottomNavigation(
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
      ),
    );
  }
}

class _OwnerBottomNavigation extends StatelessWidget {
  const _OwnerBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _OwnerNavItem(
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    _OwnerNavItem(
      label: 'My Pets',
      icon: Icons.pets_rounded,
    ),
    _OwnerNavItem(
      label: 'Appointments',
      icon: Icons.calendar_month_rounded,
    ),
    _OwnerNavItem(
      label: 'AI Hub',
      icon: Icons.psychology_rounded,
    ),
    _OwnerNavItem(
      label: 'Profile',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.secondary.withValues(alpha: 0.22),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];

              return Expanded(
                child: _OwnerNavigationItem(
                  item: item,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OwnerNavigationItem extends StatelessWidget {
  const _OwnerNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _OwnerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.primary
        : AppTheme.deepBrown.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerNavItem {
  const _OwnerNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: AppTheme.deepBrown,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This section will be available soon.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepBrown,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}