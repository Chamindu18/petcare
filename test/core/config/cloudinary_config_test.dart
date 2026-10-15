import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/core/config/cloudinary_config.dart';

void main() {
  group('CloudinaryConfig', () {
    test('cloudName has default value', () {
      expect(CloudinaryConfig.cloudName, isNotEmpty);
      expect(CloudinaryConfig.cloudName, equals('dvd6d0h6s'));
    });

    test('uploadPreset has default value', () {
      expect(CloudinaryConfig.uploadPreset, isNotEmpty);
      expect(CloudinaryConfig.uploadPreset, equals('petcare_unsigned'));
    });
  });
}
