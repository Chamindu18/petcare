import 'package:flutter/material.dart';

import '../../../hospitals/domain/entities/hospital.dart';
import '../../domain/entities/veterinarian.dart';
import '../providers/veterinarian_provider.dart';

class VeterinarianDiscoveryPage extends StatefulWidget {
  const VeterinarianDiscoveryPage({
    super.key,
    required this.provider,
    required this.onVeterinarianTap,
  });

  final VeterinarianProvider provider;
  final void Function(Veterinarian veterinarian) onVeterinarianTap;

  @override
  State<VeterinarianDiscoveryPage> createState() =>
      _VeterinarianDiscoveryPageState();
}

class _VeterinarianDiscoveryPageState extends State<VeterinarianDiscoveryPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.provider.veterinarians.isEmpty && !widget.provider.isLoading) {
        widget.provider.loadVeterinarians();
      }
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  List<Veterinarian> _filteredVeterinarians() {
    if (_searchQuery.isEmpty) {
      return widget.provider.veterinarians;
    }

    return widget.provider.veterinarians.where((veterinarian) {
      final hospital = widget.provider.getHospital(veterinarian.hospitalId);

      final name = veterinarian.name.toLowerCase();
      final specialty = veterinarian.specialty?.toLowerCase() ?? '';
      final qualifications = veterinarian.qualifications?.toLowerCase() ?? '';
      final hospitalName = hospital?.name.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          specialty.contains(_searchQuery) ||
          qualifications.contains(_searchQuery) ||
          hospitalName.contains(_searchQuery);
    }).toList();
  }

  Future<void> _refresh() async {
    await widget.provider.loadVeterinarians();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final veterinarians = _filteredVeterinarians();

        return Scaffold(
          appBar: AppBar(title: const Text('Find Veterinarians')),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by name, specialty or hospital',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.clear),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                if (widget.provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.provider.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: widget.provider.errorMessage!,
                      onRetry: widget.provider.loadVeterinarians,
                    ),
                  )
                else if (veterinarians.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(hasSearchQuery: _searchQuery.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: veterinarians.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final veterinarian = veterinarians[index];

                        return _VeterinarianCard(
                          veterinarian: veterinarian,
                          hospital: widget.provider.getHospital(
                            veterinarian.hospitalId,
                          ),
                          onTap: () {
                            widget.onVeterinarianTap(veterinarian);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VeterinarianCard extends StatelessWidget {
  const _VeterinarianCard({
    required this.veterinarian,
    required this.hospital,
    required this.onTap,
  });

  final Veterinarian veterinarian;
  final Hospital? hospital;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    veterinarian.profileImageUrl != null &&
                        veterinarian.profileImageUrl!.isNotEmpty
                    ? NetworkImage(veterinarian.profileImageUrl!)
                    : null,
                child:
                    veterinarian.profileImageUrl == null ||
                        veterinarian.profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      veterinarian.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (veterinarian.specialty != null &&
                        veterinarian.specialty!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        veterinarian.specialty!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (hospital != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_hospital_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hospital!.name,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (veterinarian.experienceYears != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${veterinarian.experienceYears} years experience',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearchQuery});

  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasSearchQuery
              ? 'No veterinarians match your search.'
              : 'No veterinarians are available.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
