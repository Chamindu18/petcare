import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_listing_repository.dart';
import '../../data/repositories/firebase_adoption_request_repository.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/entities/adoption_request.dart';
import '../../domain/repositories/adoption_listing_repository.dart';
import '../../domain/repositories/adoption_request_decision_repository.dart';
import '../../domain/repositories/adoption_request_repository.dart';

class AdoptionRequestDetailsPage extends StatefulWidget {
  const AdoptionRequestDetailsPage({
    super.key,
    required this.requestId,
    this.adoptionRequestRepository,
    this.decisionRepository,
    this.adoptionListingRepository,
    this.currentUserId,
  });

  final String requestId;
  final String? currentUserId;
  final AdoptionRequestRepository? adoptionRequestRepository;
  final AdoptionRequestDecisionRepository? decisionRepository;
  final AdoptionListingRepository? adoptionListingRepository;

  @override
  State<AdoptionRequestDetailsPage> createState() =>
      _AdoptionRequestDetailsPageState();
}

class _AdoptionRequestDetailsPageState
    extends State<AdoptionRequestDetailsPage> {
  late final AdoptionRequestRepository _requestRepository;
  late final AdoptionRequestDecisionRepository _decisionRepository;
  late final AdoptionListingRepository _listingRepository;
  late Stream<AdoptionRequest?> _requestStream;

  final Map<String, Stream<AdoptionListing?>> _listingStreams = {};
  bool _isSubmittingDecision = false;

  @override
  void initState() {
    super.initState();

    final requestRepository = widget.adoptionRequestRepository;
    final decisionRepository = widget.decisionRepository;

    if (requestRepository != null && decisionRepository != null) {
      // Tests and callers that inject repositories do not need Firebase to be
      // initialized just to construct this page.
      _requestRepository = requestRepository;
      _decisionRepository = decisionRepository;
    } else {
      final firebaseRequestRepository = FirebaseAdoptionRequestRepository();
      _requestRepository = requestRepository ?? firebaseRequestRepository;
      _decisionRepository = decisionRepository ?? firebaseRequestRepository;
    }

    _listingRepository =
        widget.adoptionListingRepository ?? FirebaseAdoptionListingRepository();
    _requestStream = _requestRepository.watchRequest(
      requestId: widget.requestId,
    );
  }

  void _reloadRequest() {
    setState(() {
      _requestStream = _requestRepository.watchRequest(
        requestId: widget.requestId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Adoption Request Details')),
      body: StreamBuilder<AdoptionRequest?>(
        stream: _requestStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              !snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return _RequestDetailsErrorState(onRetry: _reloadRequest);
          }

          final request = snapshot.data;
          if (request == null) {
            return const _RequestNotFoundState();
          }

          final listingStream = _listingStreams.putIfAbsent(
            request.listingId,
            () => _listingRepository.watchListing(listingId: request.listingId),
          );

          final canDecideRequest =
              request.recipientType == 'adoption_provider' &&
              request.recipientId != null &&
              request.recipientId == widget.currentUserId;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RequestStatusPanel(status: request.status),
                const SizedBox(height: 16),
                _DetailsCard(
                  title: 'Request message',
                  icon: Icons.chat_bubble_outline_rounded,
                  child: Text(
                    request.message?.trim().isNotEmpty == true
                        ? request.message!.trim()
                        : 'The adopter did not include a message.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.espresso, height: 1.45),
                  ),
                ),
                const SizedBox(height: 12),
                _DetailsCard(
                  title: 'Request information',
                  icon: Icons.event_note_outlined,
                  child: Column(
                    children: [
                      _InformationRow(
                        label: 'Submitted',
                        value: _formatDateTime(request.submittedAt),
                      ),
                      const SizedBox(height: 10),
                      _InformationRow(
                        label: 'Last updated',
                        value: _formatDateTime(request.updatedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailsCard(
                  title: 'Related listing',
                  icon: Icons.pets_rounded,
                  child: StreamBuilder<AdoptionListing?>(
                    stream: listingStream,
                    builder: (context, listingSnapshot) {
                      if (listingSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !listingSnapshot.hasData &&
                          !listingSnapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      if (listingSnapshot.hasError) {
                        return const Text(
                          'Unable to load the listing details. You can still review the request status.',
                        );
                      }

                      final listing = listingSnapshot.data;
                      if (listing == null) {
                        return const Text(
                          'The related adoption listing is no longer available.',
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.petName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.espresso,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _InformationRow(
                            label: 'Species',
                            value: listing.species,
                          ),
                          if (listing.breed?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            _InformationRow(
                              label: 'Breed',
                              value: listing.breed!.trim(),
                            ),
                          ],
                          if (listing.ageDescription?.trim().isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 8),
                            _InformationRow(
                              label: 'Age',
                              value: listing.ageDescription!.trim(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _InformationRow(
                            label: 'Gender',
                            value: listing.gender,
                          ),
                          const SizedBox(height: 8),
                          _InformationRow(
                            label: 'Location',
                            value: listing.location,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            listing.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.deepBrown,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (_isPending(request.status) && canDecideRequest) ...[
                  Text(
                    'Decision',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmittingDecision
                              ? null
                              : () => _confirmDecision(
                                  request: request,
                                  decision: 'rejected',
                                ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject Request'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSubmittingDecision
                              ? null
                              : () => _confirmDecision(
                                  request: request,
                                  decision: 'accepted',
                                ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Accept Request'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSubmittingDecision) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ] else if (_isPending(request.status)) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only the adoption provider managing this listing can '
                    'accept or reject this request.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'This request is no longer pending and cannot be changed.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDecision({
    required AdoptionRequest request,
    required String decision,
  }) async {
    final isAccept = decision == 'accepted';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isAccept
              ? 'Accept this adoption request?'
              : 'Reject this adoption request?',
        ),
        content: Text(
          isAccept
              ? 'The request status will change to Accepted.'
              : 'The request status will change to Rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isAccept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSubmittingDecision = true);
    try {
      if (isAccept) {
        await _decisionRepository.acceptRequest(requestId: request.requestId);
      } else {
        await _decisionRepository.rejectRequest(requestId: request.requestId);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccept
                ? 'Adoption request accepted.'
                : 'Adoption request rejected.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update this request. It may have already been reviewed. Refresh and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingDecision = false);
      }
    }
  }

  bool _isPending(String status) => status.toLowerCase() == 'pending';

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.deepBrown),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.espresso),
          ),
        ),
      ],
    );
  }
}

class _RequestStatusPanel extends StatelessWidget {
  const _RequestStatusPanel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (label, color) = switch (normalized) {
      'pending' => ('Pending review', AppTheme.warning),
      'accepted' => ('Accepted', AppTheme.success),
      'rejected' => ('Rejected', AppTheme.error),
      'withdrawn' => ('Withdrawn', AppTheme.deepBrown),
      'closed' => ('Closed', AppTheme.deepBrown),
      _ => (status, AppTheme.deepBrown),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request status',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
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

class _RequestDetailsErrorState extends StatelessWidget {
  const _RequestDetailsErrorState({required this.onRetry});

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
              'Unable to load this adoption request.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.espresso,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _RequestNotFoundState extends StatelessWidget {
  const _RequestNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This adoption request could not be found or is no longer available.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
