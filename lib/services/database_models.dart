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

  static SeasonTier fromScore(int score) {
    if (score >= 50000) return SeasonTier.diamond;
    if (score >= 30000) return SeasonTier.platinum;
    if (score >= 20000) return SeasonTier.gold;
    if (score >= 10000) return SeasonTier.silver;
    return SeasonTier.bronze;
  }

  static SeasonTier fromRank({
    required int rank,
    required int participantCount,
  }) {
    if (participantCount <= 0) {
      return SeasonTier.bronze;
    }

    final normalizedRank = rank.clamp(1, participantCount);
    final percentile = normalizedRank / participantCount;

    if (percentile <= 0.01) return SeasonTier.diamond;
    if (percentile <= 0.05) return SeasonTier.platinum;
    if (percentile <= 0.20) return SeasonTier.gold;
    if (percentile <= 0.50) return SeasonTier.silver;
    return SeasonTier.bronze;
  }
}

@immutable
class DailyChallengeInfo {
  const DailyChallengeInfo({
    required this.dateKey,
    required this.seed,
    required this.hasUsedEntry,
    this.myScore,
  });

  final String dateKey;
  final int seed;
  final bool hasUsedEntry;
  final int? myScore;

  String get displayDateLabel => dateKey.replaceAll('-', '.');

  bool get hasScoreEntry => myScore != null;
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
