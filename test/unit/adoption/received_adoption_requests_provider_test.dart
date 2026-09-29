import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/adoption/domain/entities/adoption_request.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_repository.dart';
import 'package:petcare/features/adoption/presentation/providers/received_adoption_requests_provider.dart';

class _FakeAdoptionRequestRepository implements AdoptionRequestRepository {
  _FakeAdoptionRequestRepository({this.requests = const [], this.error});

  final List<AdoptionRequest> requests;
  final Object? error;

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? message,
  }) async {}

  @override
  Stream<List<AdoptionRequest>> watchMyRequests() {
    return Stream.value(requests);
  }

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() {
    if (error != null) {
      return Stream<List<AdoptionRequest>>.error(error!);
    }

    return Stream.value(requests);
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    return Stream.value(
      requests.where((request) => request.requestId == requestId).firstOrNull,
    );
  }
}

AdoptionRequest _createRequest({String status = 'pending'}) {
  return AdoptionRequest(
    requestId: 'request-1',
    listingId: 'listing-1',
    requesterId: 'owner-1',
    providerId: 'provider-1',
    message: 'I would love to adopt this pet.',
    status: status,
    submittedAt: DateTime(2026, 9, 20),
    updatedAt: DateTime(2026, 9, 20),
  );
}

void main() {
  test('loads received requests successfully', () async {
    final provider = ReceivedAdoptionRequestsProvider(
      repository: _FakeAdoptionRequestRepository(requests: [_createRequest()]),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.requests, hasLength(1));
    expect(provider.requests.single.requestId, 'request-1');
    expect(provider.hasNoRequests, isFalse);

    provider.dispose();
  });

  test('shows empty state when there are no received requests', () async {
    final provider = ReceivedAdoptionRequestsProvider(
      repository: _FakeAdoptionRequestRepository(),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.requests, isEmpty);
    expect(provider.hasNoRequests, isTrue);

    provider.dispose();
  });

  test('shows error when received requests fail to load', () async {
    final provider = ReceivedAdoptionRequestsProvider(
      repository: _FakeAdoptionRequestRepository(
        error: StateError('network error'),
      ),
    );

    provider.startListening();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(
      provider.errorMessage,
      'Unable to load received adoption requests. Please try again.',
    );
    expect(provider.hasNoRequests, isFalse);

    provider.dispose();
  });
}
