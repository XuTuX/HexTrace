class KstClock {
  const KstClock._();

  static const Duration _kstOffset = Duration(hours: 9);

  static DateTime nowUtc() => DateTime.now().toUtc();

  static DateTime nowInKst() => nowUtc().add(_kstOffset);

  static DateTime toKst(DateTime value) => value.toUtc().add(_kstOffset);

  static String currentDateKey() => dateKeyFor(nowInKst());

  static String currentWeekKey() => isoWeekKeyFor(nowInKst());

  static String dateKeyFor(DateTime kstTime) {
    final value = toKst(kstTime);
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String isoWeekKeyFor(DateTime kstTime) {
    final value = DateTime.utc(
      toKst(kstTime).year,
      toKst(kstTime).month,
      toKst(kstTime).day,
    );
    final shifted = value.add(Duration(days: 4 - value.weekday));
    final weekYear = shifted.year;
    final firstThursday = DateTime.utc(weekYear, 1, 4);
    final firstWeekStart =
        firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final weekNumber = ((value.difference(firstWeekStart).inDays) ~/ 7) + 1;
    return '$weekYear-${weekNumber.toString().padLeft(2, '0')}';
  }
}
