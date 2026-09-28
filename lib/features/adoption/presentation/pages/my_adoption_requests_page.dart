import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_request_repository.dart';
import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../providers/my_adoption_requests_provider.dart';

class MyAdoptionRequestsPage extends StatefulWidget {
  const MyAdoptionRequestsPage({super.key, this.adoptionRequestRepository});

  final AdoptionRequestRepository? adoptionRequestRepository;

  @override
  State<MyAdoptionRequestsPage> createState() => _MyAdoptionRequestsPageState();
}

class _MyAdoptionRequestsPageState extends State<MyAdoptionRequestsPage> {
  late final MyAdoptionRequestsProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = MyAdoptionRequestsProvider(
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
      appBar: AppBar(title: const Text('My Adoption Requests')),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
              return _AdoptionRequestCard(request: _provider.requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _AdoptionRequestCard extends StatelessWidget {
  const _AdoptionRequestCard({required this.request});

  final AdoptionRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppTheme.deepBrown,
                size: 28,
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
                    'Submitted ${_formatDate(request.submittedAt)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  if (request.message != null &&
                      request.message!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.espresso),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusBadge(status: request.status),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    final (label, color) = switch (normalizedStatus) {
      'pending' => ('Pending', AppTheme.warning),
      'accepted' => ('Accepted', AppTheme.success),
      'rejected' => ('Rejected', AppTheme.error),
      'withdrawn' => ('Withdrawn', AppTheme.deepBrown),
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
                Icons.pets_rounded,
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
              'Your adoption requests will appear here after you apply for a pet.',
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
              'Unable to load your adoption requests',
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
