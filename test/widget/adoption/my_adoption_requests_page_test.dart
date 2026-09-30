import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/adoption/domain/entities/adoption_request.dart';
import 'package:petcare/features/adoption/domain/repositories/adoption_request_repository.dart';
import 'package:petcare/features/adoption/presentation/pages/my_adoption_requests_page.dart';

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
    if (error != null) {
      return Stream<List<AdoptionRequest>>.error(error!);
    }

    return Stream.value(requests);
  }

  @override
  Stream<List<AdoptionRequest>> watchReceivedRequests() {
    return Stream.value(requests);
  }

  @override
  Stream<AdoptionRequest?> watchRequest({required String requestId}) {
    return const Stream.empty();
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

Widget _buildPage({required AdoptionRequestRepository repository}) {
  return MaterialApp(
    home: MyAdoptionRequestsPage(adoptionRequestRepository: repository),
  );
}

void main() {
  testWidgets('shows adoption requests and their status', (tester) async {
    final repository = _FakeAdoptionRequestRepository(
      requests: [
        _createRequest(status: 'pending'),
        _createRequest(status: 'accepted'),
      ],
    );

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('My Adoption Requests'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no adoption requests', (
    tester,
  ) async {
    final repository = _FakeAdoptionRequestRepository();

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('No adoption requests yet'), findsOneWidget);
    expect(
      find.text(
        'Your adoption requests will appear here after you apply for a pet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error state when requests cannot be loaded', (
    tester,
  ) async {
    final repository = _FakeAdoptionRequestRepository(
      error: StateError('Network error'),
    );

    await tester.pumpWidget(_buildPage(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('Unable to load your adoption requests'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
