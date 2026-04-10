class WeeklyResetInfo {
  const WeeklyResetInfo({
    required this.days,
    required this.hours,
  });

  final int days;
  final int hours;

  static WeeklyResetInfo current() {
    const kstOffset = Duration(hours: 9);
    final nowUtc = DateTime.now().toUtc();
    final nowKst = nowUtc.add(kstOffset);

    final daysUntilNextMonday = 8 - nowKst.weekday;
    final nextResetKst = DateTime(
      nowKst.year,
      nowKst.month,
      nowKst.day + daysUntilNextMonday,
    );

    final remaining = nextResetKst.difference(nowKst);
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    return WeeklyResetInfo(
      days: safeRemaining.inDays,
      hours: safeRemaining.inHours.remainder(24),
    );
  }

  String get koreanLabel => '종료까지 $days일 $hours시간';

  String get englishCompactLabel => '${days}D ${hours}H LEFT';
}
