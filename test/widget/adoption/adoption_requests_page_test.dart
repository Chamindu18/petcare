import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/domain/entities/adoption_request.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/adoption_requests_page.dart';

class _FakeAdoptionRequestRepository implements AdoptionRequestRepository {
  _FakeAdoptionRequestRepository({
    this.requests = const [],
    this.error,
    this.failFirstReceivedStream = false,
  });

  final List<AdoptionRequest> requests;
  final Object? error;
  final bool failFirstReceivedStream;

  int _receivedStreamCalls = 0;

  @override
  Future<void> createRequest({
    required String listingId,
    required String providerId,
    String? recipientId,
    String recipientType = 'adoption_provider',
    String? message,
  }) async {}

  @override
  Stream<List<AdoptionRequest>> watchMyRequests() {
    return Stream.value(requests);
  }

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() {
    _receivedStreamCalls++;

    if (error != null &&
        (!failFirstReceivedStream || _receivedStreamCalls == 1)) {
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

AdoptionRequest _createRequest({
  String requestId = 'request-1',
  String listingId = 'listing-1',
  String status = 'pending',
  String? message = 'I would love to adopt this pet.',
}) {
  return AdoptionRequest(
    requestId: requestId,
    listingId: listingId,
    requesterId: 'owner-1',
    providerId: 'provider-1',
    message: message,
    status: status,
    submittedAt: DateTime(2026, 9, 20),
    updatedAt: DateTime(2026, 9, 20),
  );
}

Widget _buildPage({required AdoptionRequestRepository repository}) {
  return MaterialApp(
    home: AdoptionRequestsPage(adoptionRequestRepository: repository),
  );
}

void main() {
  testWidgets('shows received adoption requests and their statuses', (
    tester,
  ) async {
    final repository = _FakeAdoptionRequestRepository(
      requests: [
        _createRequest(),
        _createRequest(
          requestId: 'request-2',
          listingId: 'listing-2',
          status: 'accepted',
          message: null,
        ),
      ],
    );

    await tester.pumpWidget(_buildPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Adoption Requests'), findsOneWidget);
    expect(find.text('Listing reference: listing-1'), findsOneWidget);
    expect(find.text('Listing reference: listing-2'), findsOneWidget);
    expect(find.text('I would love to adopt this pet.'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no received requests', (
    tester,
  ) async {
    final repository = _FakeAdoptionRequestRepository();

    await tester.pumpWidget(_buildPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('No adoption requests yet'), findsOneWidget);
    expect(
      find.text(
        'Requests from interested adopters will appear here when someone applies for one of your listings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error and recovers when retry succeeds', (tester) async {
    final repository = _FakeAdoptionRequestRepository(
      requests: [_createRequest()],
      error: StateError('Network error'),
      failFirstReceivedStream: true,
    );

    await tester.pumpWidget(_buildPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load adoption requests'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load adoption requests'), findsNothing);
    expect(find.text('Listing reference: listing-1'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });
}
