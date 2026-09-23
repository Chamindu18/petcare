import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_listing_repository.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';
import '../providers/adoption_listing_provider.dart';

class AdoptionListingsPage extends StatefulWidget {
  const AdoptionListingsPage({super.key, this.adoptionListingRepository});

  final AdoptionListingRepository? adoptionListingRepository;

  @override
  State<AdoptionListingsPage> createState() => _AdoptionListingsPageState();
}

class _AdoptionListingsPageState extends State<AdoptionListingsPage> {
  late final AdoptionListingProvider _adoptionListingProvider;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _adoptionListingProvider = AdoptionListingProvider(
      repository:
          widget.adoptionListingRepository ??
          FirebaseAdoptionListingRepository(),
    );

    _searchController = TextEditingController();
    _adoptionListingProvider.startListening();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adoptionListingProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Adopt a Pet')),
      body: ListenableBuilder(
        listenable: _adoptionListingProvider,
        builder: (context, _) {
          return Column(
            children: [
              _SearchAndFilterSection(
                controller: _searchController,
                onChanged: _adoptionListingProvider.setSearchQuery,
              ),
              Expanded(child: _buildContent()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_adoptionListingProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_adoptionListingProvider.errorMessage != null) {
      return _ErrorState(onRetry: _adoptionListingProvider.startListening);
    }

    if (_adoptionListingProvider.hasNoResults) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _adoptionListingProvider.listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final listing = _adoptionListingProvider.listings[index];

        return _AdoptionListingCard(listing: listing, onTap: () {});
      },
    );
  }
}

class _SearchAndFilterSection extends StatelessWidget {
  const _SearchAndFilterSection({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search pets, breed or location',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.deepBrown,
                side: const BorderSide(color: AppTheme.secondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdoptionListingCard extends StatelessWidget {
  const _AdoptionListingCard({required this.listing, required this.onTap});

  final AdoptionListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ListingImage(imageAsset: listing.imageAsset),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.petName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.deepBrown,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.deepBrown,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final details = <String>[
      listing.species,
      if (listing.breed != null && listing.breed!.isNotEmpty) listing.breed!,
      if (listing.ageDescription != null && listing.ageDescription!.isNotEmpty)
        listing.ageDescription!,
    ];

    return details.join(' • ');
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null || imageAsset!.isEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.pets_rounded,
          size: 36,
          color: AppTheme.deepBrown,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        imageAsset!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: 88,
            height: 88,
            color: AppTheme.secondary,
            child: const Icon(
              Icons.pets_rounded,
              size: 36,
              color: AppTheme.deepBrown,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 36,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No adoption listings found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search or check back later for new pets.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load adoption listings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
