import '../entities/hospital_operating_hours.dart';

/// Parses the human-readable hospital opening-hours format stored in Firestore.
///
/// Supported examples:
/// - 8 AM - 8 PM
/// - 9 AM - 7 PM
/// - 8 am - 6 pm
/// - 08 AM - 08 PM
class HospitalHoursParser {
  const HospitalHoursParser._();

  static HospitalOperatingHours parse(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw const FormatException('Hospital hours cannot be empty.');
    }

    final match = RegExp(
      r'^(\d{1,2})\s*(AM|PM)\s*-\s*(\d{1,2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match == null) {
      throw FormatException(
        'Invalid hospital hours format: "$value". '
        'Expected format such as "8 AM - 8 PM".',
      );
    }

    final openingHour = int.parse(match.group(1)!);
    final openingPeriod = match.group(2)!.toUpperCase();
    final closingHour = int.parse(match.group(3)!);
    final closingPeriod = match.group(4)!.toUpperCase();

    _validateHour(openingHour, value);
    _validateHour(closingHour, value);

    final openingMinutes = _toMinutes(openingHour, openingPeriod);
    final closingMinutes = _toMinutes(closingHour, closingPeriod);

    if (closingMinutes <= openingMinutes) {
      throw FormatException(
        'Hospital closing time must be after opening time: "$value".',
      );
    }

    return HospitalOperatingHours(
      openingMinutes: openingMinutes,
      closingMinutes: closingMinutes,
    );
  }

  static void _validateHour(int hour, String originalValue) {
    if (hour < 1 || hour > 12) {
      throw FormatException(
        'Invalid hour in hospital hours: "$originalValue".',
      );
    }
  }

  static int _toMinutes(int hour, String period) {
    final normalizedHour = hour == 12 ? 0 : hour;
    final hour24 = period == 'PM' ? normalizedHour + 12 : normalizedHour;

    return hour24 * 60;
  }
}
