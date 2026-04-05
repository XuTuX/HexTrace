import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../gameplay/hex_puzzle/hex_puzzle_logic.dart';
import '../gameplay/hex_puzzle/hex_puzzle_palette.dart';
import '../services/settings_service.dart';
import 'score_controller.dart';

class GameController extends GetxController {
  late final ScoreController scoreController;
  late final SettingsService settingsService;

  final Random _random = Random();

  final board = <List<HexTileColor>>[].obs;
  final colorBar = <HexTileColor>[].obs;
  final dragPath = <HexCoord>[].obs;
  final lastMatchedPath = <HexCoord>[].obs;

  final dragStatus = DragPathStatus.idle.obs;
  final highlightedWindow = Rxn<BarWindowMatch>();

  final isResolving = false.obs;
  final isGameOver = false.obs;
  final hasSavedGame = false.obs;

  final score = 0.obs;
  final timeLeft = HexPuzzleLogic.initialTimeSeconds.obs;
  final comboDepth = 0.obs;
  final matchesMade = 0.obs;
  final shuffleCharges = 1.obs;

  final statusText =
      'Drag 3 or more adjacent hexes whose colors match any contiguous run in the bar.'
          .obs;
  final gameOverReason = ''.obs;

  Timer? _countdownTimer;
  DateTime? _lastMatchAt;

  @override
  void onInit() {
    super.onInit();

    try {
      scoreController = Get.find<ScoreController>();
    } catch (_) {
      scoreController = Get.put(ScoreController());
    }

    settingsService = Get.find<SettingsService>();
    checkHasSavedGame();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  Future<void> checkHasSavedGame() async {
    hasSavedGame.value = false;
  }

  Future<void> saveGameState() async {
    hasSavedGame.value = false;
  }

  Future<bool> loadGameState() async {
    hasSavedGame.value = false;
    return false;
  }

  Future<void> clearSavedGame() async {
    hasSavedGame.value = false;
  }

  void resetGame() {
    _countdownTimer?.cancel();
    scoreController.resetScore();

    score.value = 0;
    timeLeft.value = HexPuzzleLogic.initialTimeSeconds;
    comboDepth.value = 0;
    matchesMade.value = 0;
    shuffleCharges.value = 1;
    isResolving.value = false;
    isGameOver.value = false;
    gameOverReason.value = '';
    _lastMatchAt = null;

    _buildPlayableState();
    _clearDragState();
    statusText.value =
        'Find a path of 3+ adjacent hexes that matches any consecutive colors in the bar.';
    _startTimer();
  }

  void startDrag(HexCoord coord) {
    if (!_canInteract) return;

    dragPath.assignAll([coord]);
    _updateDragFeedback();
  }

  void updateDrag(HexCoord coord) {
    if (!_canInteract || dragPath.isEmpty) return;

    final currentPath = List<HexCoord>.from(dragPath);
    final last = currentPath.last;

    if (coord == last) {
      return;
    }

    if (currentPath.length >= 2 &&
        coord == currentPath[currentPath.length - 2]) {
      currentPath.removeLast();
      dragPath.assignAll(currentPath);
      _updateDragFeedback();
      return;
    }

    if (!HexPuzzleLogic.areAdjacent(last, coord) ||
        currentPath.contains(coord)) {
      dragStatus.value = DragPathStatus.invalid;
      statusText.value = 'Keep the route adjacent and do not revisit a tile.';
      return;
    }

    currentPath.add(coord);
    dragPath.assignAll(currentPath);
    _updateDragFeedback();
  }

  Future<void> endDrag() async {
    if (dragPath.isEmpty || !_canInteract) {
      _clearDragState();
      return;
    }

    final evaluation = _currentEvaluation;
    if (evaluation.isExactMatch &&
        dragPath.length >= HexPuzzleLogic.minimumPathLength) {
      await _resolveCurrentMatch(evaluation.window!);
      return;
    }

    if (settingsService.isHapticsOn.value) {
      HapticFeedback.heavyImpact();
    }

    statusText.value =
        'That path does not match a contiguous run in the bar. Try a different route.';
    _clearDragState();
  }

  void cancelDrag() {
    if (isResolving.value) return;
    _clearDragState();
  }

  Future<void> useShuffle() async {
    if (!_canInteract || shuffleCharges.value <= 0) return;

    shuffleCharges.value--;
    await _shuffleIntoPlayableState(
      status:
          'The hive was shuffled. The bar stays live, so look for a new contiguous color run.',
    );
  }

  bool get _canInteract => !isGameOver.value && !isResolving.value;

  DragEvaluation get _currentEvaluation {
    final colors = dragPath
        .map((coord) => board[coord.row][coord.column])
        .toList(growable: false);
    return HexPuzzleLogic.evaluatePath(colors, colorBar);
  }

  void _updateDragFeedback() {
    final evaluation = _currentEvaluation;
    dragStatus.value = evaluation.status;
    highlightedWindow.value = evaluation.window;

    switch (evaluation.status) {
      case DragPathStatus.idle:
        statusText.value =
            'Start on any tile. You can use any contiguous run in the bar, not just slot 1.';
        break;
      case DragPathStatus.building:
        final nextLength = dragPath.length;
        if (nextLength < HexPuzzleLogic.minimumPathLength) {
          statusText.value =
              'Good start. Keep dragging until the path reaches at least 3 tiles.';
        } else {
          statusText.value =
              'This path is still a valid prefix. Release now or extend for a longer match.';
        }
        break;
      case DragPathStatus.exact:
        statusText.value =
            'Release to score, clear the path, and earn bonus time.';
        break;
      case DragPathStatus.invalid:
        statusText.value =
            'The color order broke the bar sequence. Backtrack or release to cancel.';
        break;
    }
  }

  Future<void> _resolveCurrentMatch(BarWindowMatch window) async {
    isResolving.value = true;
    highlightedWindow.value = window;

    final matchedPath = List<HexCoord>.from(dragPath);
    dragPath.clear();
    lastMatchedPath.assignAll(matchedPath);

    final combo = _nextComboDepth();
    final gainedScore = HexPuzzleLogic.scoreForPath(matchedPath.length, combo);
    final gainedTime = HexPuzzleLogic.timeBonusForPath(matchedPath.length);

    score.value += gainedScore;
    timeLeft.value = min(
      HexPuzzleLogic.maximumTimeSeconds,
      timeLeft.value + gainedTime,
    );
    matchesMade.value++;

    scoreController.registerPuzzleMatch(
      points: gainedScore,
      comboDepth: combo,
    );

    if (settingsService.isHapticsOn.value) {
      HapticFeedback.mediumImpact();
    }

    statusText.value =
        '+$gainedScore points and +$gainedTime sec. The matched run was removed from the bar.';

    await Future<void>.delayed(const Duration(milliseconds: 180));

    final nextBoard = HexPuzzleLogic.removePathAndRefill(
      board,
      matchedPath,
      _random,
    );
    final nextColorBar = HexPuzzleLogic.consumeColorBarWindow(
      colorBar,
      window,
      _random,
    );

    board.assignAll(nextBoard);
    colorBar.assignAll(nextColorBar);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    lastMatchedPath.clear();
    dragStatus.value = DragPathStatus.idle;
    highlightedWindow.value = null;
    isResolving.value = false;

    await _ensurePlayableAfterTurn();
  }

  int _nextComboDepth() {
    final now = DateTime.now();
    if (_lastMatchAt != null &&
        now.difference(_lastMatchAt!) <= const Duration(seconds: 3)) {
      comboDepth.value += 1;
    } else {
      comboDepth.value = 1;
    }

    _lastMatchAt = now;
    return comboDepth.value;
  }

  void _buildPlayableState() {
    for (var attempt = 0; attempt < 160; attempt++) {
      final nextBoard = HexPuzzleLogic.randomBoard(_random);
      final nextColorBar = HexPuzzleLogic.randomColorBar(_random);

      if (!HexPuzzleLogic.hasAnyValidMove(nextBoard, nextColorBar)) {
        continue;
      }

      board.assignAll(nextBoard);
      colorBar.assignAll(nextColorBar);
      return;
    }

    _assignGuaranteedMoveState();
  }

  Future<void> _ensurePlayableAfterTurn() async {
    if (timeLeft.value <= 0) {
      await _finishGame('Time is up.');
      return;
    }

    if (HexPuzzleLogic.hasAnyValidMove(board, colorBar)) {
      return;
    }

    if (shuffleCharges.value > 0) {
      shuffleCharges.value--;
      await _shuffleIntoPlayableState(
        status:
            'No valid path remained, so the prototype used your one emergency shuffle.',
      );
      return;
    }

    await _finishGame('No valid paths of length 3 or more remain.');
  }

  Future<void> _shuffleIntoPlayableState({required String status}) async {
    isResolving.value = true;
    _clearDragState();

    for (var attempt = 0; attempt < 120; attempt++) {
      final nextBoard = attempt.isEven
          ? HexPuzzleLogic.shuffledBoard(board, _random)
          : HexPuzzleLogic.randomBoard(_random);
      final nextBar = attempt.isEven
          ? HexPuzzleLogic.shuffledColorBar(colorBar, _random)
          : HexPuzzleLogic.randomColorBar(_random);

      if (!HexPuzzleLogic.hasAnyValidMove(nextBoard, nextBar)) {
        continue;
      }

      board.assignAll(nextBoard);
      colorBar.assignAll(nextBar);
      statusText.value = status;
      isResolving.value = false;
      return;
    }

    _assignGuaranteedMoveState();
    statusText.value = status;
    isResolving.value = false;
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (isGameOver.value || isResolving.value) return;

      timeLeft.value--;
      if (timeLeft.value <= 0) {
        await _finishGame('Time is up.');
      }
    });
  }

  Future<void> _finishGame(String reason) async {
    if (isGameOver.value) return;

    _countdownTimer?.cancel();
    isGameOver.value = true;
    gameOverReason.value = reason;
    _clearDragState();
    scoreController.checkHighScore();
    await scoreController.uploadHighScoreToServer();
  }

  void _clearDragState() {
    dragPath.clear();
    dragStatus.value = DragPathStatus.idle;
    highlightedWindow.value = null;
  }

  void _assignGuaranteedMoveState() {
    final seededBoard = HexPuzzleLogic.randomBoard(_random);
    final seededBar = <HexTileColor>[
      HexTileColor.coral,
      HexTileColor.amber,
      HexTileColor.lime,
      HexPuzzleLogic.randomColor(_random),
      HexPuzzleLogic.randomColor(_random),
    ];

    const guaranteedPath = [
      HexCoord(3, 2),
      HexCoord(3, 3),
      HexCoord(3, 4),
    ];
    for (var index = 0; index < guaranteedPath.length; index++) {
      final coord = guaranteedPath[index];
      seededBoard[coord.row][coord.column] = seededBar[index];
    }

    board.assignAll(seededBoard);
    colorBar.assignAll(seededBar);
  }

  String describePathColor(HexCoord coord) {
    return board[coord.row][coord.column].label;
  }
}
