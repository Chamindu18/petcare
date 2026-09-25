import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/pet.dart';
import '../providers/pets_controller.dart';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({
    required this.controller,
    super.key,
    this.ownsController = true,
  });

  final PetsController controller;
  final bool ownsController;

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  PetsController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onControllerChanged);

    if (_controller.pets.isEmpty) {
      _loadPets();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);

    if (widget.ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadPets() async {
    await _controller.loadPets();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openAddPet() {
    Navigator.pushNamed(
      context,
      AppRouter.addPet,
      arguments: _controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pets')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPet,
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.pets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.errorMessage != null && _controller.pets.isEmpty) {
      return _buildErrorState();
    }

    if (_controller.pets.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPetList(_controller.pets);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No pets yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet to start managing their health records.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAddPet,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load pets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadPets,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetList(List<Pet> pets) {
    return RefreshIndicator(
      onRefresh: _loadPets,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _PetCard(pet: pets[index]);
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: pet.imageUrl.isEmpty
              ? const Icon(Icons.pets)
              : ClipOval(
                  child: Image.network(
                    pet.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.pets),
                  ),
                ),
        ),
        title: Text(
          pet.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${pet.species} • ${pet.breed} • ${pet.ageInYears} years',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}