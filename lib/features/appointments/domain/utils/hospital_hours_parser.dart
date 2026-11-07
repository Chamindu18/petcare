import '../entities/hospital_operating_hours.dart';

/// Parses the human-readable hospital opening-hours format stored in Firestore.
///
/// Supported examples:
/// - 8 AM - 8 PM
/// - 8:00 AM - 8:00 PM
/// - 9:30 AM - 7:30 PM
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
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\s*-\s*'
      r'(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match == null) {
      throw FormatException(
        'Invalid hospital hours format: "$value". '
        'Expected format such as "8 AM - 8 PM" or "8:00 AM - 8:00 PM".',
      );
    }

    final openingHour = int.parse(match.group(1)!);
    final openingMinutes = _parseMinutes(match.group(2), value);
    final openingPeriod = match.group(3)!.toUpperCase();

    final closingHour = int.parse(match.group(4)!);
    final closingMinutes = _parseMinutes(match.group(5), value);
    final closingPeriod = match.group(6)!.toUpperCase();

    _validateHour(openingHour, value);
    _validateHour(closingHour, value);

    final openingTotalMinutes = _toMinutes(
      openingHour,
      openingMinutes,
      openingPeriod,
    );

    final closingTotalMinutes = _toMinutes(
      closingHour,
      closingMinutes,
      closingPeriod,
    );

    if (closingTotalMinutes <= openingTotalMinutes) {
      throw FormatException(
        'Hospital closing time must be after opening time: "$value".',
      );
    }

    return HospitalOperatingHours(
      openingMinutes: openingTotalMinutes,
      closingMinutes: closingTotalMinutes,
    );
  }

  static int _parseMinutes(String? value, String originalValue) {
    if (value == null) {
      return 0;
    }

    final minutes = int.parse(value);

    if (minutes < 0 || minutes > 59) {
      throw FormatException(
        'Invalid minutes in hospital hours: "$originalValue".',
      );
    }

    return minutes;
  }

  static void _validateHour(int hour, String originalValue) {
    if (hour < 1 || hour > 12) {
      throw FormatException(
        'Invalid hour in hospital hours: "$originalValue".',
      );
    }
  }

  static int _toMinutes(
    int hour,
    int minutes,
    String period,
  ) {
    final normalizedHour = hour == 12 ? 0 : hour;
    final hour24 = period == 'PM' ? normalizedHour + 12 : normalizedHour;

    return hour24 * 60 + minutes;
  }
}