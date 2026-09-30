import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../notifications/data/repositories/firebase_notification_repository.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/entities/adoption_request.dart';
import '../providers/my_adoption_listings_provider.dart';
import '../providers/received_adoption_requests_provider.dart';

class AdoptionProviderDashboardPage extends StatefulWidget {
  const AdoptionProviderDashboardPage({
    super.key,
    required this.listingsProvider,
    required this.requestsProvider,
  });

  final MyAdoptionListingsProvider listingsProvider;
  final ReceivedAdoptionRequestsProvider requestsProvider;

  @override
  State<AdoptionProviderDashboardPage> createState() =>
      _AdoptionProviderDashboardPageState();
}

class _AdoptionProviderDashboardPageState
    extends State<AdoptionProviderDashboardPage> {
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();

    _notificationProvider = NotificationProvider(
      repository: FirebaseNotificationRepository(),
    );

    widget.listingsProvider.startListening();
    widget.requestsProvider.startListening();
    _notificationProvider.startListening();
  }

  @override
  void dispose() {
    _notificationProvider.dispose();
    widget.listingsProvider.dispose();
    widget.requestsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.listingsProvider,
            widget.requestsProvider,
            _notificationProvider,
          ]),
          builder: (context, _) {
            if (widget.listingsProvider.isLoading ||
                widget.requestsProvider.isLoading ||
                _notificationProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              );
            }

            if (widget.listingsProvider.errorMessage != null ||
                widget.requestsProvider.errorMessage != null ||
                _notificationProvider.errorMessage != null) {
              return _DashboardErrorState(
                onRetry: () {
                  widget.listingsProvider.startListening();
                  widget.requestsProvider.startListening();
                  _notificationProvider.startListening();
                },
              );
            }

            return _DashboardContent(
              listings: widget.listingsProvider.listings,
              requests: widget.requestsProvider.requests,
              unreadNotificationCount: _notificationProvider.unreadCount,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.listings,
    required this.requests,
    required this.unreadNotificationCount,
  });

  final List<AdoptionListing> listings;
  final List<AdoptionRequest> requests;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    final pendingRequestCount = requests
        .where((request) => request.status == 'pending')
        .length;

    final recentListing = listings.isEmpty ? null : listings.first;
    final recentRequest = requests.isEmpty ? null : requests.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(unreadNotificationCount: unreadNotificationCount),
          const SizedBox(height: 24),
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.pets_rounded,
                  title: 'My Listings',
                  value: listings.length.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Pending Requests',
                  value: pendingRequestCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _QuickActionCard(onPressed: () {}),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Listing',
            actionLabel: listings.isEmpty ? null : 'View all',
            onAction: listings.isEmpty ? null : () {},
          ),
          const SizedBox(height: 12),
          if (recentListing == null)
            const _DashboardEmptyCard(
              icon: Icons.pets_rounded,
              title: 'No listings yet',
              message: 'Create your first adoption listing to get started.',
            )
          else
            _RecentListingCard(listing: recentListing),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Request',
            actionLabel: requests.isEmpty ? null : 'View all',
            onAction: requests.isEmpty ? null : () {},
          ),
          const SizedBox(height: 12),
          if (recentRequest == null)
            const _DashboardEmptyCard(
              icon: Icons.inbox_outlined,
              title: 'No adoption requests yet',
              message: 'Requests from interested adopters will appear here.',
            )
          else
            _RecentRequestCard(request: recentRequest),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.unreadNotificationCount});

  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Adoption Provider Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.notifications);
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.deepBrown,
              ),
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadNotificationCount > 9
                        ? '9+'
                        : unreadNotificationCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.deepBrown),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.deepBrown),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Listing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a pet for adoption',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.deepBrown),
                    ),
                  ],
                ),
              ),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _RecentListingCard extends StatelessWidget {
  const _RecentListingCard({required this.listing});

  final AdoptionListing listing;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      listing.species,
      if (listing.breed != null && listing.breed!.isNotEmpty) listing.breed!,
      if (listing.ageDescription != null && listing.ageDescription!.isNotEmpty)
        listing.ageDescription!,
    ];

    return Card(
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
                    details.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
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
            _ListingStatus(status: listing.status),
          ],
        ),
      ),
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  const _RecentRequestCard({required this.request});

  final AdoptionRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adoption request',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listing: ${request.listingId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ],
              ),
            ),
            _RequestStatus(status: request.status),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  const _DashboardEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.deepBrown),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
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

class _ListingStatus extends StatelessWidget {
  const _ListingStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(label: _formatStatus(status));
  }

  String _formatStatus(String value) {
    if (value.isEmpty) {
      return 'Unknown';
    }

    return value
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(label: _formatStatus(status));
  }

  String _formatStatus(String value) {
    if (value.isEmpty) {
      return 'Unknown';
    }

    return value
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppTheme.deepBrown, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null || imageAsset!.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.pets_rounded,
          size: 32,
          color: AppTheme.deepBrown,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        imageAsset!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: 72,
            height: 72,
            color: AppTheme.secondary,
            child: const Icon(
              Icons.pets_rounded,
              size: 32,
              color: AppTheme.deepBrown,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.onRetry});

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
              'Unable to load your dashboard.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
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
