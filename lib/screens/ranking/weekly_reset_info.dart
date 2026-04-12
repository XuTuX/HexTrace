class WeeklyResetInfo {
  const WeeklyResetInfo({
    required this.days,
    required this.hours,
    required this.minutes,
  });

  final int days;
  final int hours;
  final int minutes;

  static WeeklyResetInfo current() {
    // 1. Get current time in KST (UTC+9)
    final nowUtc = DateTime.now().toUtc();
    final nowKst = nowUtc.add(const Duration(hours: 9));

    // 2. Find days until next Monday (1)
    // weekday is 1 for Monday, 7 for Sunday.
    // At Monday 00:00, we want the count for the next cycle (7 days).
    final daysUntilNextMonday = 8 - nowKst.weekday;

    // 3. Target next Monday 00:00:00 KST
    // We use DateTime.utc to stay in the same coordinate system as nowKst.
    final nextResetKst = DateTime.utc(
      nowKst.year,
      nowKst.month,
      nowKst.day + daysUntilNextMonday,
    );

    final remaining = nextResetKst.difference(nowKst);
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    return WeeklyResetInfo(
      days: safeRemaining.inDays,
      hours: safeRemaining.inHours.remainder(24),
      minutes: safeRemaining.inMinutes.remainder(60),
    );
  }

  String get koreanLabel {
    if (days > 0) {
      return '종료까지 $days일 $hours시간 $minutes분';
    }
    if (hours > 0) {
      return '종료까지 $hours시간 $minutes분';
    }
    return '종료까지 $minutes분';
  }

  String get englishCompactLabel {
    if (days > 0) {
      return '${days}D ${hours}H ${minutes}M LEFT';
    }
    if (hours > 0) {
      return '${hours}H ${minutes}M LEFT';
    }
    return '${minutes}M LEFT';
  }
}
