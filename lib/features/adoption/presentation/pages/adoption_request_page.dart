import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/repositories/firebase_adoption_request_repository.dart';
import '../../domain/entities/adoption_listing.dart';
import '../../domain/repositories/adoption_request_repository.dart';
import '../providers/adoption_request_provider.dart';

class AdoptionRequestPage extends StatefulWidget {
  const AdoptionRequestPage({
    super.key,
    required this.listing,
    this.adoptionRequestRepository,
  });

  final AdoptionListing listing;
  final AdoptionRequestRepository? adoptionRequestRepository;

  @override
  State<AdoptionRequestPage> createState() => _AdoptionRequestPageState();
}

class _AdoptionRequestPageState extends State<AdoptionRequestPage> {
  late final AdoptionRequestProvider _provider;
  late final TextEditingController _messageController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _provider = AdoptionRequestProvider(
      repository:
          widget.adoptionRequestRepository ??
          FirebaseAdoptionRequestRepository(),
    );

    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await _provider.submitRequest(
      listingId: widget.listing.listingId,
      providerId: widget.listing.providerId,
      message: _messageController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (_provider.isSubmitted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Adoption Request')),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ListingSummary(listing: widget.listing),
                const SizedBox(height: 24),
                Text(
                  'Send a message',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell the provider why you are interested in adopting this pet.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Write your message...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message.';
                    }

                    return null;
                  },
                ),
                if (_provider.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _ErrorMessage(
                    message: _provider.errorMessage!,
                    onDismiss: _provider.clearError,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _provider.isSubmitting ? null : _submitRequest,
                    child: _provider.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.white,
                            ),
                          )
                        : const Text('Submit Adoption Request'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ListingSummary extends StatelessWidget {
  const _ListingSummary({required this.listing});

  final AdoptionListing listing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 34,
                color: AppTheme.deepBrown,
              ),
            ),
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
                    _summary,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.location,
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

  String get _summary {
    final details = <String>[
      listing.species,
      if (listing.breed != null && listing.breed!.isNotEmpty) listing.breed!,
    ];

    return details.join(' • ');
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.deepBrown,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
