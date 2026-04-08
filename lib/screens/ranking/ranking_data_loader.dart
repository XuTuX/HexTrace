import 'package:flutter/foundation.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';

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
}) async {
  final isLoggedIn = authService.user.value != null;

  if (isLoggedIn) {
    await scoreController.waitForLoginSync();
    await scoreController.syncScoreForRanking();
  }

  final results = await Future.wait([
    isLoggedIn
        ? dbService.getMyRank(gameId).catchError((e) {
            debugPrint('🔴 [RankingScreen] getMyRank error: $e');
            return null;
          })
        : Future<int?>.value(null),
    isLoggedIn
        ? dbService.getMyBestScore(gameId).catchError((e) {
            debugPrint('🔴 [RankingScreen] getMyBestScore error: $e');
            return null;
          })
        : Future<int?>.value(null),
    dbService.getLeaderboard(gameId).catchError((e) {
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
