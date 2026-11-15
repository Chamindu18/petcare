import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/features/hospitals/data/models/hospital_model.dart';

void main() {
  final data = {
    'hospitalId': 'hospital_001',
    'name': 'PawCare Central Hospital',
    'location': 'Colombo',
    'contact': '011-0000000',
    'active': true,
  };

  test('maps the stored hours field', () {
    final hospital = HospitalModel.fromMap({
      ...data,
      'hours': '8:00 AM - 8:00 PM',
    });
    expect(hospital.hours, '8:00 AM - 8:00 PM');
  });

  test('missing hours remain diagnosable as invalid configuration', () {
    final hospital = HospitalModel.fromMap(data);
    expect(hospital.hours, isEmpty);
  });
}
