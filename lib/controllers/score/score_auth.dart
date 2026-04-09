part of 'package:linkagon/controllers/score_controller.dart';

void _bindScoreAuthState(ScoreController controller) {
  final authService = Get.find<AuthService>();
  controller._authWorker?.dispose();
  controller._authWorker = ever(authService.user, (user) {
    if (controller.isClosed) {
      return;
    }

    if (user != null) {
      controller._loginSyncCompleter = Completer<void>();
      _onUserLogin(controller, user.id);
    } else {
      _onUserLogout(controller);
    }
  });
}

Future<void> _onUserLogin(ScoreController controller, String userId) async {
  if (controller.isClosed) {
    return;
  }
  controller.isSyncing.value = true;
  controller.hasNewHighScoreThisGame.value = false;

  try {
    final prefs = await SharedPreferences.getInstance();
    final userLocalScore = prefs.getInt('high_score_$userId') ?? 0;
    final legacyScore = prefs.getInt('high_score') ?? 0;
    final guestScore = prefs.getInt('high_score_guest') ?? 0;

    int bestLocalScore = max(userLocalScore, legacyScore);

    if (guestScore > 0) {
      bestLocalScore = max(bestLocalScore, guestScore);
      debugPrint(
        '🔵 [ScoreController] Merging guest score ($guestScore) with user score ($userLocalScore) / legacy ($legacyScore) → $bestLocalScore',
      );
      await prefs.setInt('high_score_guest', 0);
    }

    if (legacyScore > 0) {
      await prefs.remove('high_score');
      debugPrint(
        '🔵 [ScoreController] Legacy score ($legacyScore) migrated and cleared.',
      );
    }

    if (controller.isClosed) {
      return;
    }
    controller.highscore.value = bestLocalScore;
    await prefs.setInt('high_score_$userId', bestLocalScore);
    await _syncWithOnlineScore(controller, bestLocalScore);
  } catch (e) {
    debugPrint('🔴 [ScoreController] _onUserLogin failed: $e');
  } finally {
    if (!controller.isClosed) {
      controller.isSyncing.value = false;
    }
    if (controller._loginSyncCompleter != null &&
        !controller._loginSyncCompleter!.isCompleted) {
      controller._loginSyncCompleter!.complete();
    }
  }
}

Future<void> _onUserLogout(ScoreController controller) async {
  if (controller.isClosed) {
    return;
  }
  controller.isSyncing.value = true;
  controller.hasNewHighScoreThisGame.value = false;

  final prefs = await SharedPreferences.getInstance();
  final guestScore = prefs.getInt('high_score_guest') ?? 0;
  if (controller.isClosed) {
    return;
  }
  controller.highscore.value = guestScore;

  debugPrint(
    '🔵 [ScoreController] Switched to guest mode. Guest score: $guestScore',
  );
  if (!controller.isClosed) {
    controller.isSyncing.value = false;
  }
}
