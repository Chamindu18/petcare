import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:petcare/features/pets/data/repositories/cloudinary_pet_image_repository.dart';

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}

CloudinaryPetImageRepository _createRepository({
  required String cloudName,
  required String uploadPreset,
  required _MockHttpClient httpClient,
  required MockFirebaseAuth auth,
}) {
  return CloudinaryPetImageRepository(
    cloudName: cloudName,
    uploadPreset: uploadPreset,
    httpClient: httpClient,
    auth: auth,
  );
}

void main() {
  group('CloudinaryPetImageRepository', () {
    group('constructor', () {
      test('throws when cloudName is empty', () {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        expect(
          () => _createRepository(
            cloudName: '',
            uploadPreset: 'valid-preset',
            httpClient: _MockHttpClient(
              (_) async => throw UnimplementedError(),
            ),
            auth: mockAuth,
          ),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              contains('cloud name'),
            ),
          ),
        );
      });

      test('throws when uploadPreset is empty', () {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        expect(
          () => _createRepository(
            cloudName: 'valid-cloud',
            uploadPreset: '',
            httpClient: _MockHttpClient(
              (_) async => throw UnimplementedError(),
            ),
            auth: mockAuth,
          ),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              contains('upload preset'),
            ),
          ),
        );
      });

      test('does not throw when both values are provided', () {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        expect(
          () => _createRepository(
            cloudName: 'valid-cloud',
            uploadPreset: 'valid-preset',
            httpClient: _MockHttpClient(
              (_) async => throw UnimplementedError(),
            ),
            auth: mockAuth,
          ),
          returnsNormally,
        );
      });
    });

    group('uploadPetImage', () {
      const petId = 'pet-123';
      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      test('returns secure_url on successful upload', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final ownerId = mockAuth.currentUser!.uid;
        final responseBody = jsonEncode({
          'secure_url':
              'https://res.cloudinary.com/test-cloud/image/upload/v123/pet-images/$ownerId/$petId/abc123.jpg',
          'public_id': 'pet-images/$ownerId/$petId/abc123',
          'version': 123,
        });

        final mockClient = _MockHttpClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals('https://api.cloudinary.com/v1_1/test-cloud/image/upload'),
          );

          final multipartRequest = request as http.MultipartRequest;
          expect(
            multipartRequest.fields['upload_preset'],
            equals('test-preset'),
          );
          expect(
            multipartRequest.fields['folder'],
            equals('pet-images/$ownerId/$petId'),
          );
          expect(multipartRequest.files.length, equals(1));
          expect(multipartRequest.files.first.field, equals('file'));

          return http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            200,
          );
        });

        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        final result = await repository.uploadPetImage(
          petId: petId,
          bytes: imageBytes,
        );

        expect(
          result,
          equals(
            'https://res.cloudinary.com/test-cloud/image/upload/v123/pet-images/$ownerId/$petId/abc123.jpg',
          ),
        );
      });

      test('throws PetImageRepositoryException on non-2xx response', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final responseBody = jsonEncode({
          'error': {'message': 'Upload preset not found'},
        });

        final mockClient = _MockHttpClient(
          (_) async => http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            400,
          ),
        );

        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        expect(
          () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              equals('Upload preset not found'),
            ),
          ),
        );
      });

      test('throws PetImageRepositoryException on 5xx response', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final responseBody = jsonEncode({
          'error': {'message': 'Internal server error'},
        });

        final mockClient = _MockHttpClient(
          (_) async => http.StreamedResponse(
            Stream.value(utf8.encode(responseBody)),
            500,
          ),
        );

        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        expect(
          () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              equals('Internal server error'),
            ),
          ),
        );
      });

      test(
        'throws PetImageRepositoryException when secure_url is missing',
        () async {
          final mockAuth = MockFirebaseAuth(signedIn: true);
          final responseBody = jsonEncode({
            'public_id': 'pet-images/owner/pet/abc123',
            'version': 123,
          });

          final mockClient = _MockHttpClient(
            (_) async => http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            ),
          );

          final repository = _createRepository(
            cloudName: 'test-cloud',
            uploadPreset: 'test-preset',
            httpClient: mockClient,
            auth: mockAuth,
          );

          expect(
            () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
            throwsA(
              isA<PetImageRepositoryException>().having(
                (e) => e.message,
                'message',
                equals('Upload succeeded but no secure URL was returned.'),
              ),
            ),
          );
        },
      );

      test(
        'throws PetImageRepositoryException when secure_url is empty',
        () async {
          final mockAuth = MockFirebaseAuth(signedIn: true);
          final responseBody = jsonEncode({
            'secure_url': '',
            'public_id': 'pet-images/owner/pet/abc123',
            'version': 123,
          });

          final mockClient = _MockHttpClient(
            (_) async => http.StreamedResponse(
              Stream.value(utf8.encode(responseBody)),
              200,
            ),
          );

          final repository = _createRepository(
            cloudName: 'test-cloud',
            uploadPreset: 'test-preset',
            httpClient: mockClient,
            auth: mockAuth,
          );

          expect(
            () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
            throwsA(
              isA<PetImageRepositoryException>().having(
                (e) => e.message,
                'message',
                equals('Upload succeeded but no secure URL was returned.'),
              ),
            ),
          );
        },
      );

      test(
        'throws PetImageRepositoryException on malformed JSON response',
        () async {
          final mockAuth = MockFirebaseAuth(signedIn: true);
          final mockClient = _MockHttpClient(
            (_) async => http.StreamedResponse(
              Stream.value(utf8.encode('not valid json')),
              200,
            ),
          );

          final repository = _createRepository(
            cloudName: 'test-cloud',
            uploadPreset: 'test-preset',
            httpClient: mockClient,
            auth: mockAuth,
          );

          expect(
            () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
            throwsA(
              isA<PetImageRepositoryException>().having(
                (e) => e.message,
                'message',
                equals('Invalid response from image storage service.'),
              ),
            ),
          );
        },
      );

      test('throws PetImageRepositoryException when petId is empty', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final mockClient = _MockHttpClient(
          (_) async => throw UnimplementedError(),
        );
        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        expect(
          () => repository.uploadPetImage(petId: '', bytes: imageBytes),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              equals('A valid pet ID is required for the image upload.'),
            ),
          ),
        );
      });

      test('throws PetImageRepositoryException when bytes is empty', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final mockClient = _MockHttpClient(
          (_) async => throw UnimplementedError(),
        );
        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        expect(
          () => repository.uploadPetImage(petId: petId, bytes: Uint8List(0)),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              equals('The selected pet image is empty.'),
            ),
          ),
        );
      });

      test('throws PetImageRepositoryException on network error', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final mockClient = _MockHttpClient(
          (_) async => throw Exception('Network error'),
        );

        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        expect(
          () => repository.uploadPetImage(petId: petId, bytes: imageBytes),
          throwsA(
            isA<PetImageRepositoryException>().having(
              (e) => e.message,
              'message',
              equals('Unable to upload the pet image. Please try again.'),
            ),
          ),
        );
      });
    });

    group('deletePetImage', () {
      test('returns without throwing for empty URL', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final mockClient = _MockHttpClient(
          (_) async => throw UnimplementedError(),
        );
        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        await expectLater(repository.deletePetImage(imageUrl: ''), completes);
      });

      test('returns without throwing for non-Cloudinary URL', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final mockClient = _MockHttpClient(
          (_) async => throw UnimplementedError(),
        );
        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        await expectLater(
          repository.deletePetImage(
            imageUrl:
                'https://firebasestorage.googleapis.com/v0/b/test/o/image.jpg',
          ),
          completes,
        );
      });

      test(
        'returns without throwing for Cloudinary URL (no-op in phase 1)',
        () async {
          final mockAuth = MockFirebaseAuth(signedIn: true);
          final mockClient = _MockHttpClient(
            (_) async => throw UnimplementedError(),
          );
          final repository = _createRepository(
            cloudName: 'test-cloud',
            uploadPreset: 'test-preset',
            httpClient: mockClient,
            auth: mockAuth,
          );

          await expectLater(
            repository.deletePetImage(
              imageUrl: 'https://res.cloudinary.com/test-cloud/image/upload/v123/pet-images/owner/pet/abc.jpg',
            ),
            completes,
          );
        },
      );

      test('does not make any HTTP request for Cloudinary URL', () async {
        final mockAuth = MockFirebaseAuth(signedIn: true);
        var requestMade = false;
        final mockClient = _MockHttpClient((_) async {
          requestMade = true;
          return http.StreamedResponse(Stream.value([]), 200);
        });

        final repository = _createRepository(
          cloudName: 'test-cloud',
          uploadPreset: 'test-preset',
          httpClient: mockClient,
          auth: mockAuth,
        );

        await repository.deletePetImage(
          imageUrl: 'https://res.cloudinary.com/test-cloud/image/upload/v123/pet-images/owner/pet/abc.jpg',
        );

        expect(requestMade, isFalse);
      });
    });
  });
}
