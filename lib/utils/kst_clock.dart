class KstClock {
  const KstClock._();

  static const Duration _kstOffset = Duration(hours: 9);

  static DateTime nowUtc() => DateTime.now().toUtc();

  static DateTime nowInKst() => nowUtc().add(_kstOffset);

  static DateTime toKst(DateTime value) => value.toUtc().add(_kstOffset);

  static String currentDateKey() => dateKeyFor(nowInKst());

  static String currentWeekKey() => isoWeekKeyFor(nowInKst());

  static List<String> recentDateKeys({int days = 30}) {
    final totalDays = days < 1 ? 1 : days;
    final today = nowInKst();
    return List<String>.generate(
      totalDays,
      (index) => dateKeyFor(today.subtract(Duration(days: index))),
    );
  }

  static String compactDateLabel(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return dateKey;
    }
    return '${parts[1]}.${parts[2]}';
  }

  static String weekdayLabel(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) {
      return '';
    }
    return switch (parsed.weekday) {
      DateTime.monday => '월',
      DateTime.tuesday => '화',
      DateTime.wednesday => '수',
      DateTime.thursday => '목',
      DateTime.friday => '금',
      DateTime.saturday => '토',
      DateTime.sunday => '일',
      _ => '',
    };
  }

  static DateTime? parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static String dateKeyFor(DateTime kstTime) {
    final value = kstTime;
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String isoWeekKeyFor(DateTime kstTime) {
    final value = DateTime.utc(
      kstTime.year,
      kstTime.month,
      kstTime.day,
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
