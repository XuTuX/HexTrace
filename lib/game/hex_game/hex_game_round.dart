part of 'package:linkagon/game/hex_game_controller.dart';

void _disposeGame(HexGameController controller) {
  controller._disposed = true;
  controller._timer?.cancel();
  controller._timerDeadlineAt = null;
}

Future<void> _resolveCurrentMatch(HexGameController controller) async {
  _syncTimerState(controller, notify: false);
  if (controller.isGameOver) {
    controller._notify();
    return;
  }

  final matchedPath = List<HexCoord>.from(controller.dragPath);
  final matchedColors = _colorsForPath(controller, matchedPath);
  final usedWindow =
      _matchingBarWindowsForSequence(controller, matchedColors).first;
  final currentVersion = controller._gameVersion;

  controller.isResolvingMatch = true;
  controller.clearingPath = matchedPath;
  controller.lastMatchPath = matchedPath;
  if (!controller.isReplaying) {
    controller.combo = controller._lastMatchAt != null &&
            DateTime.now().difference(controller._lastMatchAt!) <=
                const Duration(seconds: 4)
        ? controller.combo + 1
        : 1;
  }
  _clearDrag(controller);

  final now = DateTime.now();
  if (!controller.isReplaying) {
    controller.recordedMoves.add(RecordedMove(
      path: matchedPath,
      combo: controller.combo,
    ));
  }
  controller._lastMatchAt = now;

  final gainedScore =
      _scoreForLength(controller, matchedPath.length, controller.combo);
  controller.score += gainedScore;
  if (!controller.isReplaying) {
    final nextRemaining = min(
      controller.startingSeconds.toDouble() + 25,
      controller.timeRemaining +
          _timeBonusForLength(controller, matchedPath.length),
    );
    controller.timeRemaining = nextRemaining;
    controller._timerDeadlineAt = DateTime.now().add(
      Duration(milliseconds: (nextRemaining * 1000).round()),
    );
  }
  if (controller.combo > 1) {
    controller.statusText = 'COMBO ${controller.combo}\n+$gainedScore';
  } else {
    controller.statusText = '+$gainedScore';
  }
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
  controller._timerDeadlineAt = null;
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
  controller._timerDeadlineAt = DateTime.now().add(
    Duration(milliseconds: (controller.timeRemaining * 1000).round()),
  );

  controller.colorBar = const [];
  _refillColorBar(controller);
  _randomizeBoardUntilPlayable(controller);
  _startTimer(controller);
  controller._notify();
}

void _startTimer(HexGameController controller) {
  controller._timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
    _syncTimerState(controller);
  });
}

bool _syncTimerState(
  HexGameController controller, {
  bool notify = true,
}) {
  if (controller.isGameOver || controller.isReplaying) {
    return controller.isGameOver;
  }

  final deadlineAt = controller._timerDeadlineAt;
  if (deadlineAt == null) {
    return controller.isGameOver;
  }

  final nextRemaining = max(
    0.0,
    deadlineAt.difference(DateTime.now()).inMilliseconds / 1000,
  ).toDouble();
  final didChange = (controller.timeRemaining - nextRemaining).abs() >= 0.05;
  final oldRemaining = controller.timeRemaining;
  controller.timeRemaining = nextRemaining;

  // Haptic warnings at 10s and 5s
  if (oldRemaining > 10 && nextRemaining <= 10) {
    unawaited(AppHaptics.warning());
    // Flash status text for visual cue
    controller.statusText = '10초 남았어요!';
    controller.statusTone = GameMessageTone.warning;
  } else if (oldRemaining > 5 && nextRemaining <= 5) {
    unawaited(AppHaptics.gameOver()); // Stronger vibration
    controller.statusText = '마지막 5초!!';
    controller.statusTone = GameMessageTone.error;
  }

  if (nextRemaining <= 0) {
    _endGame(controller, '시간이 모두 지났어요.');
    if (notify) {
      controller._notify();
    }
    return true;
  }

  if (notify && didChange) {
    controller._notify();
  }

  return false;
}
