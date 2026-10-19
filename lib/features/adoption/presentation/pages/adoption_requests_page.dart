import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_request_repository.dart';
import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../providers/received_adoption_requests_provider.dart';

class AdoptionRequestsPage extends StatefulWidget {
  const AdoptionRequestsPage({super.key, this.adoptionRequestRepository});

  final AdoptionRequestRepository? adoptionRequestRepository;

  @override
  State<AdoptionRequestsPage> createState() => _AdoptionRequestsPageState();
}

class _AdoptionRequestsPageState extends State<AdoptionRequestsPage> {
  late final ReceivedAdoptionRequestsProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = ReceivedAdoptionRequestsProvider(
      repository:
          widget.adoptionRequestRepository ??
          FirebaseAdoptionRequestRepository(),
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
      appBar: AppBar(title: const Text('Adoption Requests')),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          if (_provider.errorMessage != null) {
            return _ErrorState(onRetry: _provider.startListening);
          }

          if (_provider.hasNoRequests) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _provider.requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ReceivedRequestCard(request: _provider.requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _ReceivedRequestCard extends StatelessWidget {
  const _ReceivedRequestCard({required this.request});

  final AdoptionRequest request;

  @override
  Widget build(BuildContext context) {
    final message = request.message?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                color: AppTheme.deepBrown,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adoption Request',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Listing reference: ${request.listingId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Received ${_formatDate(request.submittedAt)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.espresso),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RequestStatusBadge(status: request.status),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    final (label, color) = switch (normalizedStatus) {
      'pending' => ('Pending', AppTheme.warning),
      'accepted' => ('Accepted', AppTheme.success),
      'rejected' => ('Rejected', AppTheme.error),
      'withdrawn' => ('Withdrawn', AppTheme.deepBrown),
      'closed' => ('Closed', AppTheme.deepBrown),
      _ => (status, AppTheme.deepBrown),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
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
                Icons.inbox_outlined,
                size: 36,
                color: AppTheme.deepBrown,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No adoption requests yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests from interested adopters will appear here when someone applies for one of your listings.',
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
              'Unable to load adoption requests',
              textAlign: TextAlign.center,
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
