import 'package:flutter_test/flutter_test.dart';

import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/progress_service.dart';

void main() {
  group('ProgressService mission selection', () {
    test('selects three deterministic daily missions', () {
      final first = ProgressService.selectMissionTypesForDate('2026-04-12');
      final second = ProgressService.selectMissionTypesForDate('2026-04-12');
      final selections = <List<MissionType>>[
        for (final dateKey in [
          '2026-04-12',
          '2026-04-13',
          '2026-04-14',
          '2026-04-15',
          '2026-04-16',
        ])
          ProgressService.selectMissionTypesForDate(dateKey),
      ];

      expect(first, equals(second));
      expect(first.length, 3);
      expect(first.toSet().length, 3);
      expect(
        selections.map((value) => value.join(',')).toSet().length,
        greaterThan(1),
      );
    });
  });

  group('ProgressService summary evaluation', () {
    const summary = GameRunSummary(
      mode: GameMode.dailyOfficial,
      score: 6200,
      maxCombo: 5,
      longestPathLength: 7,
      matchCount: 9,
      invalidAttemptCount: 0,
      remainingTime: 18,
      bestMove: BestMoveSummary(
        pathLength: 7,
        scoreGained: 1200,
        combo: 3,
      ),
      dateKey: '2026-04-12',
      seed: 123456,
    );

    test('marks matching daily missions as completed', () {
      expect(
        ProgressService.matchesMission(MissionType.combo5, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesMission(MissionType.path7, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesMission(MissionType.flawless3000, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesMission(MissionType.finish15s, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesMission(MissionType.score5000, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesMission(MissionType.matches8, summary),
        isTrue,
      );
    });

    test('marks matching permanent achievements as unlocked', () {
      expect(
        ProgressService.matchesAchievement(AchievementType.combo5, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesAchievement(AchievementType.path7, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesAchievement(
            AchievementType.flawless3000, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesAchievement(AchievementType.finish15s, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesAchievement(AchievementType.score5000, summary),
        isTrue,
      );
      expect(
        ProgressService.matchesAchievement(AchievementType.score10000, summary),
        isFalse,
      );
    });
  });
}
