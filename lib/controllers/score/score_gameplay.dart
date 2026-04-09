part of 'package:linkagon/controllers/score_controller.dart';

void _registerPuzzleMatch(
  ScoreController controller, {
  required int points,
  required int comboDepth,
}) {
  controller.placementScore.value += points;
  controller.cascadeScore.value = 0;
  controller.score.value += points;
  controller.combo.value = comboDepth;

  controller.lastIncrement.value = points;
  controller.showIncrement.value = points > 0;

  if (points > 0) {
    Future.delayed(const Duration(seconds: 1), () {
      controller.showIncrement.value = false;
    });
  }

  controller.checkHighScore();
}

void _resetScoreState(ScoreController controller) {
  controller.score.value = 0;
  controller.placementScore.value = 0;
  controller.cascadeScore.value = 0;
  controller.combo.value = 0;
  controller.lastIncrement.value = 0;
  controller.showIncrement.value = false;
  controller.hasNewHighScoreThisGame.value = false;
}

Future<void> _checkHighScore(ScoreController controller) async {
  if (controller.score.value > controller.highscore.value) {
    controller.highscore.value = controller.score.value;
    controller.hasNewHighScoreThisGame.value = true;
    await _saveHighScore(controller, controller.highscore.value);
  }
}
