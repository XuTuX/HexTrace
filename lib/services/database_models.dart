import 'package:flutter/foundation.dart';

import 'package:hexor/utils/kst_clock.dart';

enum SeasonTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get label => switch (this) {
        SeasonTier.bronze => 'BRONZE',
        SeasonTier.silver => 'SILVER',
        SeasonTier.gold => 'GOLD',
        SeasonTier.platinum => 'PLATINUM',
        SeasonTier.diamond => 'DIAMOND',
      };

  static SeasonTier fromValue(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'diamond':
        return SeasonTier.diamond;
      case 'platinum':
        return SeasonTier.platinum;
      case 'gold':
        return SeasonTier.gold;
      case 'silver':
        return SeasonTier.silver;
      default:
        return SeasonTier.bronze;
    }
  }

  static SeasonTier fromRank({
    required int rank,
    required int participantCount,
  }) {
    if (rank <= 0 || participantCount <= 0) {
      return SeasonTier.bronze;
    }

    final percentile = rank / participantCount;
    if (percentile <= 0.01) {
      return SeasonTier.diamond;
    }
    if (percentile <= 0.05) {
      return SeasonTier.platinum;
    }
    if (percentile <= 0.20) {
      return SeasonTier.gold;
    }
    if (percentile <= 0.50) {
      return SeasonTier.silver;
    }
    return SeasonTier.bronze;
  }
}

@immutable
class DailyChallengeInfo {
  const DailyChallengeInfo({
    required this.dateKey,
    required this.seed,
    required this.hasUsedOfficialAttempt,
    this.myScore,
  });

  final String dateKey;
  final int seed;
  final bool hasUsedOfficialAttempt;
  final int? myScore;

  String get displayDateLabel => dateKey.replaceAll('-', '.');

  bool get hasOfficialEntry => myScore != null;
}

@immutable
class WeeklySeasonSummary {
  const WeeklySeasonSummary({
    required this.weekKey,
    required this.participantCount,
    required this.tier,
    this.rank,
    this.score,
  });

  final String weekKey;
  final int participantCount;
  final SeasonTier tier;
  final int? rank;
  final int? score;

  String get compactSeasonLabel => 'SEASON ${KstClock.currentWeekKey()}';
}
