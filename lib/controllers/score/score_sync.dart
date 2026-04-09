part of 'package:linkagon/controllers/score_controller.dart';

Future<void> _syncWithOnlineScore(
  ScoreController controller,
  int localScore,
) async {
  try {
    debugPrint('🔵 [ScoreController] Starting score sync...');

    final dbService = Get.find<DatabaseService>();

    int? onlineBest;
    try {
      onlineBest = await dbService.getMyBestScore(gameId);
    } catch (e) {
      debugPrint(
        '🟡 [ScoreController] Could not fetch online best score (might be empty/error). Proceeding to upload local anyway: $e',
      );
    }

    if (onlineBest != null && onlineBest > localScore) {
      controller.highscore.value = onlineBest;
      await _saveHighScore(controller, onlineBest);
      debugPrint(
        '🟢 [ScoreController] Synced: server ($onlineBest) > local ($localScore). Updated local.',
      );
    } else if (localScore > (onlineBest ?? 0)) {
      final bestScore = await dbService.saveScore(gameId, localScore);
      controller.highscore.value = bestScore;
      await _saveHighScore(controller, bestScore);
      debugPrint(
        '🟢 [ScoreController] Synced: local ($localScore) > server (${onlineBest ?? 0}). Uploaded best=$bestScore.',
      );
    } else {
      debugPrint('🟢 [ScoreController] Scores already in sync ($localScore)');
    }
  } catch (e) {
    debugPrint('🔴 [ScoreController] Online score sync overall failed: $e');
  }
}

Future<void> _uploadHighScoreToServer(ScoreController controller) async {
  if (controller._currentUserId == null) {
    return;
  }

  try {
    final dbService = Get.find<DatabaseService>();
    final bestScore =
        await dbService.saveScore(gameId, controller.highscore.value);
    controller.highscore.value = bestScore;
    await _saveHighScore(controller, bestScore);
    debugPrint(
      '🟢 [ScoreController] High score uploaded: ${controller.highscore.value}',
    );
  } catch (e) {
    debugPrint('🔴 [ScoreController] High score upload failed: $e');
  }
}

Future<void> _syncScoreForRanking(ScoreController controller) async {
  if (controller._currentUserId == null) {
    return;
  }

  await _syncWithOnlineScore(controller, controller.highscore.value);
}
