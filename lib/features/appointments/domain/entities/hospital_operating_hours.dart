class HospitalOperatingHours {
  const HospitalOperatingHours({
    required this.openingMinutes,
    required this.closingMinutes,
  }) : assert(
         openingMinutes >= 0 && openingMinutes < 24 * 60,
         'Opening time must be within a day.',
       ),
       assert(
         closingMinutes > 0 && closingMinutes <= 24 * 60,
         'Closing time must be within a day.',
       ),
       assert(
         closingMinutes > openingMinutes,
         'Closing time must be after opening time.',
       );

  final int openingMinutes;
  final int closingMinutes;

  Duration get duration => Duration(minutes: closingMinutes - openingMinutes);
}
