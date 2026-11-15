import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/hospital_operating_hours.dart';
import 'package:petcare/features/appointments/domain/utils/hospital_hours_parser.dart';

void main() {
  group('HospitalHoursParser', () {
    test('weekly hours close outside the stored day range', () {
      expect(
        HospitalHoursParser.forDate(
          'Monday - Saturday, 8 AM - 6 PM',
          DateTime(2026, 11, 8),
        ),
        isNull,
      );
      expect(
        HospitalHoursParser.forDate(
          'Monday - Saturday, 8 AM - 6 PM',
          DateTime(2026, 11, 9),
        )!.openingMinutes,
        480,
      );
    });
    test('stored weekly hours include Friday and another open weekday', () {
      for (final date in [DateTime(2026, 11, 20), DateTime(2026, 11, 23)]) {
        final hours = HospitalHoursParser.forDate(
          'Monday - Saturday, 8 AM - 6 PM',
          date,
        );
        expect(hours?.openingMinutes, 480);
        expect(hours?.closingMinutes, 1080);
      }
      expect(
        HospitalHoursParser.forDate(
          'Monday - Saturday, 8 AM - 6 PM',
          DateTime(2026, 11, 22),
        ),
        isNull,
      );
    });
    test('live hospital format permits multiple future dates', () {
      for (final date in [DateTime(2026, 11, 20), DateTime(2026, 11, 23)]) {
        final hours = HospitalHoursParser.forDate('8:00 AM - 8:00 PM', date)!;
        expect(hours.openingMinutes, 480);
        expect(hours.closingMinutes, 1200);
      }
    });
    test('invalid weekly hours are not mistaken for a closed day', () {
      expect(
        () => HospitalHoursParser.forDate(
          'Monday - Saturday, unknown',
          DateTime(2026, 11, 22),
        ),
        throwsFormatException,
      );
    });
    test('parses standard AM and PM hours', () {
      final result = HospitalHoursParser.parse('8 AM - 8 PM');

      expect(result, isA<HospitalOperatingHours>());
      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 20 * 60);
    });

    test('parses lowercase AM and PM', () {
      final result = HospitalHoursParser.parse('8 am - 6 pm');

      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 18 * 60);
    });

    test('parses hours with leading zeroes', () {
      final result = HospitalHoursParser.parse('08 AM - 08 PM');

      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 20 * 60);
    });

    test('parses hours with explicit zero minutes', () {
      final result = HospitalHoursParser.parse('8:00 AM - 8:00 PM');

      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 20 * 60);
    });

    test('parses hours with non-zero minutes', () {
      final result = HospitalHoursParser.parse('9:30 AM - 7:30 PM');

      expect(result.openingMinutes, 9 * 60 + 30);
      expect(result.closingMinutes, 19 * 60 + 30);
    });

    test('parses 12 PM as noon', () {
      final result = HospitalHoursParser.parse('12 PM - 1 PM');

      expect(result.openingMinutes, 12 * 60);
      expect(result.closingMinutes, 13 * 60);
    });

    test('parses 12 AM as midnight', () {
      final result = HospitalHoursParser.parse('12 AM - 1 AM');

      expect(result.openingMinutes, 0);
      expect(result.closingMinutes, 60);
    });

    test('trims surrounding whitespace', () {
      final result = HospitalHoursParser.parse('  8 AM - 8 PM  ');

      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 20 * 60);
    });

    test('throws when hospital hours are empty', () {
      expect(
        () => HospitalHoursParser.parse(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when hospital hours format is invalid', () {
      expect(
        () => HospitalHoursParser.parse('8 AM to 8 PM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when hour is outside the 1 to 12 range', () {
      expect(
        () => HospitalHoursParser.parse('13 AM - 8 PM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when minutes are outside the 0 to 59 range', () {
      expect(
        () => HospitalHoursParser.parse('8:60 AM - 8 PM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when closing time is equal to opening time', () {
      expect(
        () => HospitalHoursParser.parse('8 AM - 8 AM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when closing time is before opening time', () {
      expect(
        () => HospitalHoursParser.parse('8 PM - 8 AM'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
