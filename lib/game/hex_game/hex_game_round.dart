part of 'package:hexor/game/hex_game_controller.dart';

void _disposeGame(HexGameController controller) {
  controller._disposed = true;
  controller._timer?.cancel();
}

Future<void> _resolveCurrentMatch(HexGameController controller) async {
  final matchedPath = List<HexCoord>.from(controller.dragPath);
  final matchedColors = _colorsForPath(controller, matchedPath);
  final usedWindow =
      _matchingBarWindowsForSequence(controller, matchedColors).first;
  final currentVersion = controller._gameVersion;

  controller.isResolvingMatch = true;
  controller.clearingPath = matchedPath;
  controller.lastMatchPath = matchedPath;
  controller.combo = controller._lastMatchAt != null &&
          DateTime.now().difference(controller._lastMatchAt!) <=
              const Duration(seconds: 4)
      ? controller.combo + 1
      : 1;
  _clearDrag(controller);

  final now = DateTime.now();
  if (!controller.isReplaying) {
    controller.recordedMoves.add(matchedPath);
  }
  controller._lastMatchAt = now;

  final gainedScore =
      _scoreForLength(controller, matchedPath.length, controller.combo);
  controller.score += gainedScore;
  if (!controller.isReplaying) {
    controller.timeRemaining = min(
      controller.startingSeconds.toDouble() + 25,
      controller.timeRemaining +
          _timeBonusForLength(controller, matchedPath.length),
    );
  }
  controller.statusText = '+$gainedScore';
  controller.statusTone = GameMessageTone.success;
  unawaited(AppHaptics.success());
  controller._notify();

  await Future<void>.delayed(const Duration(milliseconds: 180));

  if (controller._disposed || currentVersion != controller._gameVersion) {
    return;
  }

  _removeMatchedTiles(controller, matchedPath);
  _consumeBarWindow(controller, usedWindow);
  controller.clearingPath = const [];
  _ensurePlayableStateAfterBoardChange(controller);
  controller._notify();

  if (controller.isGameOver) {
    controller.isResolvingMatch = false;
    controller._notify();
    return;
  }

  await Future<void>.delayed(const Duration(milliseconds: 320));

  if (controller._disposed || currentVersion != controller._gameVersion) {
    return;
  }

  controller.isResolvingMatch = false;
  controller._notify();
}

void _removeMatchedTiles(
  HexGameController controller,
  List<HexCoord> matchedPath,
) {
  final stagedBoard = controller.board
      .map((row) => row.map<GameColor?>((color) => color).toList())
      .toList();
  final nextAnimatedTiles = matchedPath.toSet();
  final counts = _colorCountsFromBoard(controller, stagedBoard);

  for (final coord in matchedPath) {
    final nextColor = _weightedBoardColor(controller, counts);
    stagedBoard[coord.row][coord.col] = nextColor;
    counts[nextColor] = (counts[nextColor] ?? 0) + 1;
  }

  controller.board = stagedBoard
      .map((row) => row.map((color) => color!).toList(growable: false))
      .toList(growable: false);
  controller.animatedTiles = Set<HexCoord>.unmodifiable(nextAnimatedTiles);
  controller.boardAnimationTick++;
}

void _consumeBarWindow(HexGameController controller, BarWindow usedWindow) {
  controller.colorBar = List<ColorBarEntry>.from(controller.colorBar)
    ..removeRange(usedWindow.start, usedWindow.end + 1);

  _refillColorBar(controller);
}

void _ensurePlayableStateAfterBoardChange(HexGameController controller) {
  if (controller.timeRemaining <= 0) {
    _endGame(controller, '시간이 모두 지났어요.');
    return;
  }

  if (_hasAnyValidMove(controller)) {
    return;
  }

  _endGame(controller, '더 이상 만들 수 있는 경로가 없어요.');
}

void _endGame(HexGameController controller, String message) {
  controller.isGameOver = true;
  controller.isResolvingMatch = false;
  controller._timer?.cancel();
  _clearDrag(controller);
  controller.clearingPath = const [];
  controller.statusText = message;
  controller.statusTone = GameMessageTone.error;
}

void _resetGame(
  HexGameController controller, {
  int? seed,
  bool isReplayMode = false,
}) {
  controller._gameVersion++;
  controller._timer?.cancel();

  if (seed != null) {
    controller.initialSeed = seed;
    controller._random = Random(seed);
  }

  if (!isReplayMode) {
    controller.recordedMoves.clear();
  }

  controller.score = 0;
  controller.combo = 0;
  controller.timeRemaining = controller.startingSeconds.toDouble();
  controller.isGameOver = false;
  controller.isResolvingMatch = false;
  controller.invalidPulse = false;
  controller.dragState = DragState.idle;
  controller.dragPath = const [];
  controller.clearingPath = const [];
  controller.lastMatchPath = const [];
  controller.animatedTiles = const {};
  controller.boardAnimationTick = 0;
  controller._lastMatchAt = null;
  controller._nextBarEntryId = 0;
  controller.statusText = '';
  controller.statusTone = GameMessageTone.info;

  controller.colorBar = const [];
  _refillColorBar(controller);
  _randomizeBoardUntilPlayable(controller);
  _startTimer(controller);
  controller._notify();
}

void _startTimer(HexGameController controller) {
  controller._timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
    if (controller.isGameOver || controller.isReplaying) {
      return;
    }

    controller.timeRemaining = max(0, controller.timeRemaining - 0.25);

    if (controller.timeRemaining <= 0) {
      _endGame(controller, '시간이 모두 지났어요.');
    }

    controller._notify();
  });
}
