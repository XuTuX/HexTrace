import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/utils/kst_clock.dart';

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

@immutable
class MissionDefinition {
  const MissionDefinition({
    required this.type,
    required this.title,
    required this.description,
  });

  final MissionType type;
  final String title;
  final String description;
}

@immutable
class MissionProgress {
  const MissionProgress({
    required this.definition,
    required this.dateKey,
    required this.progress,
    required this.target,
    required this.isCompleted,
  });

  final MissionDefinition definition;
  final String dateKey;
  final int progress;
  final int target;
  final bool isCompleted;
}

@immutable
class AchievementDefinition {
  const AchievementDefinition({
    required this.type,
    required this.title,
    required this.description,
  });

  final AchievementType type;
  final String title;
  final String description;
}

@immutable
class AchievementProgress {
  const AchievementProgress({
    required this.definition,
    required this.isUnlocked,
  });

  final AchievementDefinition definition;
  final bool isUnlocked;
}

@immutable
class ProgressAwardResult {
  const ProgressAwardResult({
    required this.completedMissionTypes,
    required this.unlockedAchievementTypes,
  });

  final List<MissionType> completedMissionTypes;
  final List<AchievementType> unlockedAchievementTypes;

  bool get hasUpdates =>
      completedMissionTypes.isNotEmpty || unlockedAchievementTypes.isNotEmpty;
}

class ProgressService extends GetxService {
  static const _dailyStateKey = 'progress_daily_state';
  static const _achievementStateKey = 'progress_achievement_state';

  final dailyMissions = <MissionProgress>[].obs;
  final achievements = <AchievementProgress>[].obs;

  SharedPreferences? _prefs;

  Future<ProgressService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await refresh();
    return this;
  }

  Future<void> refresh() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final dateKey = KstClock.currentDateKey();
    final selectedMissions = _selectMissionTypesForDate(dateKey);
    final storedDailyState = _loadJsonMap(prefs.getString(_dailyStateKey));
    final currentMissionState = storedDailyState['date_key'] == dateKey
        ? Map<String, dynamic>.from(storedDailyState['completed'] as Map? ?? {})
        : <String, dynamic>{};

    dailyMissions.assignAll(
      selectedMissions.map((type) {
        final definition = _missionDefinition(type);
        final isCompleted = currentMissionState[type.name] == true;
        return MissionProgress(
          definition: definition,
          dateKey: dateKey,
          progress: isCompleted ? 1 : 0,
          target: 1,
          isCompleted: isCompleted,
        );
      }),
    );

    final unlockedAchievements = _loadJsonMap(
      prefs.getString(_achievementStateKey),
    );
    achievements.assignAll(
      AchievementType.values.map((type) {
        return AchievementProgress(
          definition: _achievementDefinition(type),
          isUnlocked: unlockedAchievements[type.name] == true,
        );
      }),
    );
  }

  Future<ProgressAwardResult> registerCompletedRun(
      GameRunSummary summary) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final dateKey = KstClock.currentDateKey();
    final selectedMissionTypes = _selectMissionTypesForDate(dateKey);
    final dailyState = _loadJsonMap(prefs.getString(_dailyStateKey));
    final completedMissions = dailyState['date_key'] == dateKey
        ? Map<String, dynamic>.from(
            dailyState['completed'] as Map? ?? <String, dynamic>{},
          )
        : <String, dynamic>{};

    final newlyCompletedMissionTypes = <MissionType>[];
    for (final type in selectedMissionTypes) {
      if (completedMissions[type.name] == true) {
        continue;
      }
      if (_matchesMission(type, summary)) {
        completedMissions[type.name] = true;
        newlyCompletedMissionTypes.add(type);
      }
    }

    await prefs.setString(
      _dailyStateKey,
      jsonEncode({
        'date_key': dateKey,
        'completed': completedMissions,
      }),
    );

    final achievementState =
        _loadJsonMap(prefs.getString(_achievementStateKey));
    final newlyUnlockedAchievementTypes = <AchievementType>[];
    for (final type in AchievementType.values) {
      if (achievementState[type.name] == true) {
        continue;
      }
      if (_matchesAchievement(type, summary)) {
        achievementState[type.name] = true;
        newlyUnlockedAchievementTypes.add(type);
      }
    }

    await prefs.setString(
      _achievementStateKey,
      jsonEncode(achievementState),
    );

    await refresh();

    return ProgressAwardResult(
      completedMissionTypes: newlyCompletedMissionTypes,
      unlockedAchievementTypes: newlyUnlockedAchievementTypes,
    );
  }

  MissionDefinition missionDefinition(MissionType type) =>
      _missionDefinition(type);

  AchievementDefinition achievementDefinition(AchievementType type) =>
      _achievementDefinition(type);

  List<MissionType> missionTypesForDate(String dateKey) =>
      _selectMissionTypesForDate(dateKey);

  @visibleForTesting
  static List<MissionType> selectMissionTypesForDate(String dateKey) =>
      _selectMissionTypesForDate(dateKey);

  @visibleForTesting
  static bool matchesMission(MissionType type, GameRunSummary summary) =>
      _matchesMission(type, summary);

  @visibleForTesting
  static bool matchesAchievement(
          AchievementType type, GameRunSummary summary) =>
      _matchesAchievement(type, summary);

  static List<MissionType> _selectMissionTypesForDate(String dateKey) {
    final sorted = MissionType.values.toList(growable: false);
    sorted.sort((a, b) =>
        _missionWeight(a, dateKey).compareTo(_missionWeight(b, dateKey)));
    return sorted.take(3).toList(growable: false);
  }

  static int _missionWeight(MissionType type, String dateKey) {
    var hash = 17;
    for (final codeUnit in '$dateKey:${type.name}'.codeUnits) {
      hash = ((hash * 37) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  static MissionDefinition _missionDefinition(MissionType type) {
    return switch (type) {
      MissionType.combo5 => const MissionDefinition(
          type: MissionType.combo5,
          title: '콤보 러시',
          description: '한 판에서 콤보 5회 달성',
        ),
      MissionType.path7 => const MissionDefinition(
          type: MissionType.path7,
          title: '롱 패스',
          description: '한 번에 7칸 이상 연결',
        ),
      MissionType.flawless3000 => const MissionDefinition(
          type: MissionType.flawless3000,
          title: '퍼펙트 3000',
          description: '실수 없이 3000점 달성',
        ),
      MissionType.finish15s => const MissionDefinition(
          type: MissionType.finish15s,
          title: '여유 있는 마감',
          description: '15초 이상 남기고 종료',
        ),
      MissionType.score5000 => const MissionDefinition(
          type: MissionType.score5000,
          title: '점수 폭발',
          description: '한 판에서 5000점 달성',
        ),
      MissionType.matches8 => const MissionDefinition(
          type: MissionType.matches8,
          title: '연결 장인',
          description: '한 판에서 8회 이상 매치',
        ),
    };
  }

  static AchievementDefinition _achievementDefinition(AchievementType type) {
    return switch (type) {
      AchievementType.combo5 => const AchievementDefinition(
          type: AchievementType.combo5,
          title: '콤보 5',
          description: '콤보 5회를 처음 달성했어요.',
        ),
      AchievementType.path7 => const AchievementDefinition(
          type: AchievementType.path7,
          title: '7칸 연결',
          description: '7칸 이상 경로를 처음 만들었어요.',
        ),
      AchievementType.flawless3000 => const AchievementDefinition(
          type: AchievementType.flawless3000,
          title: '노미스 3000',
          description: '실수 없이 3000점을 처음 넘겼어요.',
        ),
      AchievementType.finish15s => const AchievementDefinition(
          type: AchievementType.finish15s,
          title: '시간 여유',
          description: '15초 이상 남기고 처음 마무리했어요.',
        ),
      AchievementType.score5000 => const AchievementDefinition(
          type: AchievementType.score5000,
          title: '5000점 돌파',
          description: '5000점을 처음 달성했어요.',
        ),
      AchievementType.score10000 => const AchievementDefinition(
          type: AchievementType.score10000,
          title: '10000점 돌파',
          description: '10000점을 처음 달성했어요.',
        ),
    };
  }

  static bool _matchesMission(MissionType type, GameRunSummary summary) {
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

  static bool _matchesAchievement(
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

  static Map<String, dynamic> _loadJsonMap(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
