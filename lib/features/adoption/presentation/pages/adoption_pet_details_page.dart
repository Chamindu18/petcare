import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_listing_repository.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_listing_repository.dart';
import '../providers/adoption_pet_details_provider.dart';

class AdoptionPetDetailsPage extends StatefulWidget {
  const AdoptionPetDetailsPage({
    super.key,
    required this.listingId,
    this.adoptionListingRepository,
  });

  final String listingId;
  final AdoptionListingRepository? adoptionListingRepository;

  @override
  State<AdoptionPetDetailsPage> createState() => _AdoptionPetDetailsPageState();
}

class _AdoptionPetDetailsPageState extends State<AdoptionPetDetailsPage> {
  late final AdoptionPetDetailsProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = AdoptionPetDetailsProvider(
      repository:
          widget.adoptionListingRepository ??
          FirebaseAdoptionListingRepository(),
      listingId: widget.listingId,
    );

    _provider.startListening();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pet Details')),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.errorMessage != null) {
            return _ErrorState(onRetry: _provider.startListening);
          }

          final listing = _provider.listing;

          if (listing == null) {
            return const _UnavailableState();
          }

          return _DetailsContent(listing: listing);
        },
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.listing});

  final AdoptionListing listing;

  @override
  Widget build(BuildContext context) {
    final isAvailable = listing.status == 'available';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PetImage(imageAsset: listing.imageAsset),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.petName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: listing.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _petSummary,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppTheme.deepBrown),
          ),
          const SizedBox(height: 24),
          _InfoSection(
            title: 'About ${listing.petName}',
            child: Text(
              listing.description,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: 'Pet Information',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.pets_rounded,
                  label: 'Species',
                  value: listing.species,
                ),
                if (listing.breed != null && listing.breed!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Breed',
                    value: listing.breed!,
                  ),
                if (listing.ageDescription != null &&
                    listing.ageDescription!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: listing.ageDescription!,
                  ),
                _InfoRow(
                  icon: Icons.wc_rounded,
                  label: 'Gender',
                  value: listing.gender,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: 'Location',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.deepBrown,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    listing.location,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.espresso),
                  ),
                ),
              ],
            ),
          ),
          if (listing.contactNote != null &&
              listing.contactNote!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Adoption Information',
              child: Text(
                listing.contactNote!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.espresso, height: 1.5),
              ),
            ),
          ],
          if (isAvailable) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Request Adoption'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _petSummary {
    final details = <String>[
      listing.species,
      if (listing.breed != null && listing.breed!.isNotEmpty) listing.breed!,
      if (listing.ageDescription != null && listing.ageDescription!.isNotEmpty)
        listing.ageDescription!,
    ];

    return details.join(' • ');
  }
}

class _PetImage extends StatelessWidget {
  const _PetImage({required this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null || imageAsset!.isEmpty) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.pets_rounded,
          size: 72,
          color: AppTheme.deepBrown,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        imageAsset!,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: double.infinity,
            height: 240,
            color: AppTheme.secondary,
            child: const Icon(
              Icons.pets_rounded,
              size: 72,
              color: AppTheme.deepBrown,
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.success : AppTheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayStatus,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isAvailable ? AppTheme.white : AppTheme.espresso,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _displayStatus {
    switch (status) {
      case 'available':
        return 'Available';
      case 'pending':
        return 'Pending';
      case 'adopted':
        return 'Adopted';
      case 'unavailable':
        return 'Unavailable';
      default:
        return status;
    }
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.deepBrown),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

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
              'Listing unavailable',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This adoption listing is no longer available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to listings'),
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
              'Unable to load pet details',
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
