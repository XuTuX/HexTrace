part of 'package:hexor/controllers/score_controller.dart';

String _scoreStorageKeyFor(ScoreController controller) {
  final userId = controller._currentUserId;
  if (userId != null) {
    return 'high_score_$userId';
  }
  return 'high_score_guest';
}

Future<void> _saveHighScore(ScoreController controller, int score) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(controller._scoreKey, score);
}

Future<void> _loadHighScore(ScoreController controller) async {
  final prefs = await SharedPreferences.getInstance();
  int storedScore = prefs.getInt(controller._scoreKey) ?? 0;

  if (controller._currentUserId == null) {
    final legacyScore = prefs.getInt('high_score') ?? 0;
    if (legacyScore > storedScore) {
      debugPrint(
        '🔵 [ScoreController] Legacy score ($legacyScore) > guest score ($storedScore). Migrating...',
      );
      storedScore = legacyScore;
      await prefs.setInt('high_score_guest', storedScore);
    }
    if (legacyScore > 0) {
      await prefs.remove('high_score');
    }
  }

  controller.highscore.value = storedScore;
  controller.hasNewHighScoreThisGame.value = false;
}
