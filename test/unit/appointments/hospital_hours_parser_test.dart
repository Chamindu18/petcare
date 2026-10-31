import 'package:flutter_test/flutter_test.dart';

import 'package:petcare/features/appointments/domain/entities/hospital_operating_hours.dart';
import 'package:petcare/features/appointments/domain/utils/hospital_hours_parser.dart';

void main() {
  group('HospitalHoursParser', () {
    test('parses standard AM/PM hospital hours', () {
      final result = HospitalHoursParser.parse('8 AM - 8 PM');

      expect(result, isA<HospitalOperatingHours>());
      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 20 * 60);
    });

    test('parses single-digit and lowercase AM/PM values', () {
      final result = HospitalHoursParser.parse('9 am - 7 pm');

      expect(result.openingMinutes, 9 * 60);
      expect(result.closingMinutes, 19 * 60);
    });

    test('converts 12 AM to midnight', () {
      final result = HospitalHoursParser.parse('12 AM - 6 PM');

      expect(result.openingMinutes, 0);
      expect(result.closingMinutes, 18 * 60);
    });

    test('converts 12 PM to noon', () {
      final result = HospitalHoursParser.parse('8 AM - 12 PM');

      expect(result.openingMinutes, 8 * 60);
      expect(result.closingMinutes, 12 * 60);
    });

    test('rejects an invalid hour', () {
      expect(
        () => HospitalHoursParser.parse('13 PM - 8 PM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed hours text', () {
      expect(
        () => HospitalHoursParser.parse('8:00 - 20:00'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty hours text', () {
      expect(
        () => HospitalHoursParser.parse(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a closing time before the opening time', () {
      expect(
        () => HospitalHoursParser.parse('8 PM - 8 AM'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects equal opening and closing times', () {
      expect(
        () => HospitalHoursParser.parse('8 AM - 8 AM'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
