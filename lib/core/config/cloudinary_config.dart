class CloudinaryConfig {
  const CloudinaryConfig._();

  static const String _defaultCloudName = 'dvd6d0h6s';
  static const String _defaultUploadPreset = 'petcare_unsigned';

  static String get cloudName => String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: _defaultCloudName,
  );

  static String get uploadPreset => String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: _defaultUploadPreset,
  );
}
