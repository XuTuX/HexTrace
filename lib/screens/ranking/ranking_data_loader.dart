import 'package:flutter/foundation.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/controllers/score_controller.dart';
import 'package:linkagon/services/auth_service.dart';
import 'package:linkagon/services/database_service.dart';

import 'ranking_period.dart';

class RankingDataSnapshot {
  const RankingDataSnapshot({
    required this.myRank,
    required this.myScore,
    required this.scores,
  });

  final int? myRank;
  final int? myScore;
  final List<Map<String, dynamic>> scores;
}

Future<RankingDataSnapshot> loadRankingSnapshot({
  required ScoreController scoreController,
  required AuthService authService,
  required DatabaseService dbService,
  required RankingPeriod period,
}) async {
  final isLoggedIn = authService.user.value != null;

  if (isLoggedIn) {
    await scoreController.waitForLoginSync();
    if (period == RankingPeriod.allTime) {
      await scoreController.syncScoreForRanking();
    }
  }

  final results = await Future.wait([
    isLoggedIn
        ? (period == RankingPeriod.weekly
                ? dbService.getMyWeeklyRank(gameId)
                : dbService.getMyAllTimeRank(gameId))
            .catchError((e) {
            debugPrint('🔴 [RankingScreen] getMyRank error: $e');
            return null;
          })
        : Future<int?>.value(null),
    isLoggedIn
        ? (period == RankingPeriod.weekly
                ? dbService.getMyWeeklyBestScore(gameId)
                : dbService.getMyAllTimeBestScore(gameId))
            .catchError((e) {
            debugPrint('🔴 [RankingScreen] getMyBestScore error: $e');
            return null;
          })
        : Future<int?>.value(null),
    (period == RankingPeriod.weekly
            ? dbService.getWeeklyLeaderboard(gameId)
            : dbService.getAllTimeLeaderboard(gameId))
        .catchError((e) {
      debugPrint('🔴 [RankingScreen] getLeaderboard error: $e');
      return <Map<String, dynamic>>[];
    }),
  ]);

  return RankingDataSnapshot(
    myRank: results[0] as int?,
    myScore: results[1] as int?,
    scores: List<Map<String, dynamic>>.from(results[2] as List? ?? []),
  );
}
