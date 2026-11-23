// DateTime.tryParse normalizes overflowing components (such as February 30).
// Validate the stored wall time before applying its optional UTC offset.
final _dateParts = RegExp(
  r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)(?:[T ](\d\d)(?::?(\d\d)(?::?(\d\d)(?:[.,]\d+)?)?)?(?: ?[zZ]| ?[+-](\d\d)(?::?(\d\d))?)?)?$',
);

int _daysInMonth(int year, int month) {
  if (month == 2) {
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    return leap ? 29 : 28;
  }
  return const [4, 6, 9, 11].contains(month) ? 30 : 31;
}

DateTime? parseStoredHealthDate(Object? value) {
  if (value is! String) return null;
  final parts = _dateParts.firstMatch(value);
  if (parts == null) return null;
  int component(int index) => int.parse(parts[index] ?? '0');
  final year = component(1);
  final month = component(2);
  final day = component(3);
  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > _daysInMonth(year, month) ||
      component(4) > 23 ||
      component(5) > 59 ||
      component(6) > 59 ||
      component(7) > 23 ||
      component(8) > 59) {
    return null;
  }
  return DateTime.tryParse(value);
}
