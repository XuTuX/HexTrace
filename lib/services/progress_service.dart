import 'dart:math';

import 'package:hexor/game/hex_game_controller.dart';

enum MissionType {
  combo5,
  path7,
  flawless3000,
  finish15s,
  score5000,
  matches8,
}

enum AchievementType {
  combo5,
  path7,
  flawless3000,
  finish15s,
  score5000,
  score10000,
}

class ProgressService {
  static List<MissionType> selectMissionTypesForDate(String dateKey) {
    final pool = MissionType.values.toList(growable: false);
    final shuffled = List<MissionType>.from(pool);
    shuffled.shuffle(Random(_seedFromDateKey(dateKey)));
    return shuffled.take(3).toList(growable: false);
  }

  static bool matchesMission(MissionType type, GameRunSummary summary) {
    return switch (type) {
      MissionType.combo5 => summary.maxCombo >= 5,
      MissionType.path7 => summary.longestPathLength >= 7,
      MissionType.flawless3000 =>
        summary.invalidAttemptCount == 0 && summary.score >= 3000,
      MissionType.finish15s => summary.remainingTime >= 15,
      MissionType.score5000 => summary.score >= 5000,
      MissionType.matches8 => summary.matchCount >= 8,
    };
  }

  static bool matchesAchievement(
    AchievementType type,
    GameRunSummary summary,
  ) {
    return switch (type) {
      AchievementType.combo5 => summary.maxCombo >= 5,
      AchievementType.path7 => summary.longestPathLength >= 7,
      AchievementType.flawless3000 =>
        summary.invalidAttemptCount == 0 && summary.score >= 3000,
      AchievementType.finish15s => summary.remainingTime >= 15,
      AchievementType.score5000 => summary.score >= 5000,
      AchievementType.score10000 => summary.score >= 10000,
    };
  }

  static int _seedFromDateKey(String dateKey) {
    var seed = 0;
    for (final codeUnit in dateKey.codeUnits) {
      seed = ((seed * 31) + codeUnit) & 0x7fffffff;
    }
    return seed;
  }
}
