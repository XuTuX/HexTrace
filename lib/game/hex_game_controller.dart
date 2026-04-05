import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum GameColor { coral, amber, mint, azure, violet }

extension GameColorKey on GameColor {
  String get key => switch (this) {
        GameColor.coral => 'coral',
        GameColor.amber => 'amber',
        GameColor.mint => 'mint',
        GameColor.azure => 'azure',
        GameColor.violet => 'violet',
      };
}

enum DragState { idle, building, valid, invalid }

enum GameMessageTone { info, success, warning, error }

@immutable
class ColorBarEntry {
  const ColorBarEntry({required this.id, required this.color});

  final int id;
  final GameColor color;
}

@immutable
class HexCoord {
  const HexCoord(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) {
    return other is HexCoord && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}

@immutable
class BarWindow {
  const BarWindow(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start + 1;

  bool containsIndex(int index) => index >= start && index <= end;
}

class HexGameController extends ChangeNotifier {
  HexGameController({
    this.rows = 7,
    this.cols = 6,
    this.colorBarSize = 10,
    this.startingSeconds = 60,
    Random? random,
  }) : _random = random ?? Random() {
    _resetGame();
  }

  final int rows;
  final int cols;
  final int colorBarSize;
  final int startingSeconds;
  final Random _random;
  int _nextBarEntryId = 0;

  late List<List<GameColor>> board;
  late List<ColorBarEntry> colorBar;
  Set<HexCoord> animatedTiles = const {};
  int boardAnimationTick = 0;

  List<HexCoord> dragPath = const [];
  List<HexCoord> clearingPath = const [];
  DragState dragState = DragState.idle;
  bool invalidPulse = false;

  int score = 0;
  int combo = 0;
  double timeRemaining = 0;
  bool isGameOver = false;
  bool isResolvingMatch = false;

  String statusText = '';
  GameMessageTone statusTone = GameMessageTone.info;

  Timer? _timer;
  bool _disposed = false;
  DateTime? _lastMatchAt;
  int _gameVersion = 0;
  int _invalidPulseVersion = 0;

  bool get canInteract => !isGameOver && !isResolvingMatch;

  DragState get visibleDragState {
    if (invalidPulse && dragPath.isNotEmpty) {
      return DragState.invalid;
    }

    return dragState;
  }

  List<BarWindow> get activeBarWindows {
    if (dragPath.isEmpty) {
      return const [];
    }

    return matchingBarWindowsForSequence(_colorsForPath(dragPath));
  }

  void restart() {
    _resetGame();
  }

  void beginDrag(HexCoord? coord) {
    if (!canInteract || coord == null) {
      return;
    }

    dragPath = [coord];
    invalidPulse = false;
    _refreshDragState();
    _updateStatusForDrag();
    _notify();
  }

  void extendDrag(HexCoord? coord) {
    if (!canInteract || coord == null || dragPath.isEmpty) {
      return;
    }

    if (coord == dragPath.last) {
      return;
    }

    if (dragPath.length > 1 && coord == dragPath[dragPath.length - 2]) {
      dragPath = List<HexCoord>.from(dragPath)..removeLast();
      invalidPulse = false;
      _refreshDragState();
      _updateStatusForDrag();
      _notify();
      return;
    }

    if (dragPath.contains(coord)) {
      _showInvalidPulse('같은 드래그에서 같은 타일은 다시 지날 수 없어요.');
      return;
    }

    if (!isAdjacent(dragPath.last, coord)) {
      _showInvalidPulse('인접한 육각 타일만 이어서 드래그할 수 있어요.');
      return;
    }

    final candidatePath = [...dragPath, coord];
    final candidateColors = _colorsForPath(candidatePath);

    if (!sequenceMatchesAnyBarWindow(candidateColors)) {
      _showInvalidPulse('색 흐름 안의 연속 구간과 정확히 맞아야 해요.');
      return;
    }

    dragPath = candidatePath;
    invalidPulse = false;
    _refreshDragState();
    _updateStatusForDrag();
    _notify();
  }

  void endDrag() {
    if (!canInteract || dragPath.isEmpty) {
      return;
    }

    if (dragState == DragState.valid) {
      _resolveCurrentMatch();
      return;
    }

    statusText = dragState == DragState.invalid ? '현재 경로가 색 흐름과 맞지 않아요.' : '';
    statusTone = GameMessageTone.warning;
    _clearDrag();
    _notify();
  }

  void cancelDrag() {
    if (dragPath.isEmpty) {
      return;
    }

    _clearDrag();
    _notify();
  }

  List<HexCoord> neighborsOf(HexCoord coord) {
    final oddRow = coord.row.isOdd;
    final List<(int, int)> deltas = oddRow
        ? const [(-1, 0), (1, 0), (0, -1), (1, -1), (0, 1), (1, 1)]
        : const [(-1, 0), (1, 0), (-1, -1), (0, -1), (-1, 1), (0, 1)];

    return deltas
        .map((delta) => HexCoord(coord.col + delta.$1, coord.row + delta.$2))
        .where(_isOnBoard)
        .toList(growable: false);
  }

  bool isAdjacent(HexCoord a, HexCoord b) {
    return neighborsOf(a).contains(b);
  }

  bool sequenceMatchesAnyBarWindow(List<GameColor> sequence) {
    return matchingBarWindowsForSequence(sequence).isNotEmpty;
  }

  List<BarWindow> matchingBarWindowsForSequence(List<GameColor> sequence) {
    if (sequence.isEmpty || sequence.length > colorBar.length) {
      return const [];
    }

    final matches = <BarWindow>[];

    for (var start = 0; start <= colorBar.length - sequence.length; start++) {
      var matched = true;

      for (var offset = 0; offset < sequence.length; offset++) {
        if (colorBar[start + offset].color != sequence[offset]) {
          matched = false;
          break;
        }
      }

      if (matched) {
        matches.add(BarWindow(start, start + sequence.length - 1));
      }
    }

    return matches;
  }

  bool hasAnyValidMove() {
    final seenSequences = <String>{};

    for (var length = 3; length <= colorBar.length; length++) {
      for (var start = 0; start <= colorBar.length - length; start++) {
        final sequence = colorBar
            .sublist(start, start + length)
            .map((entry) => entry.color)
            .toList(growable: false);
        final key = sequence.map((color) => color.key).join('-');

        if (!seenSequences.add(key)) {
          continue;
        }

        for (var row = 0; row < rows; row++) {
          for (var col = 0; col < cols; col++) {
            final origin = HexCoord(col, row);

            if (board[row][col] == sequence.first &&
                _canTraceSequence(origin, sequence, 0, <HexCoord>{origin})) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  bool _canTraceSequence(
    HexCoord current,
    List<GameColor> sequence,
    int index,
    Set<HexCoord> visited,
  ) {
    if (index == sequence.length - 1) {
      return true;
    }

    for (final neighbor in neighborsOf(current)) {
      if (visited.contains(neighbor)) {
        continue;
      }

      if (board[neighbor.row][neighbor.col] != sequence[index + 1]) {
        continue;
      }

      visited.add(neighbor);

      if (_canTraceSequence(neighbor, sequence, index + 1, visited)) {
        return true;
      }

      visited.remove(neighbor);
    }

    return false;
  }

  List<GameColor> _colorsForPath(List<HexCoord> path) {
    return path
        .map((coord) => board[coord.row][coord.col])
        .toList(growable: false);
  }

  void _refreshDragState() {
    if (dragPath.isEmpty) {
      dragState = DragState.idle;
      return;
    }

    final matchesBar = sequenceMatchesAnyBarWindow(_colorsForPath(dragPath));

    if (!matchesBar) {
      dragState = DragState.invalid;
      return;
    }

    dragState = dragPath.length >= 3 ? DragState.valid : DragState.building;
  }

  void _updateStatusForDrag() {
    switch (dragState) {
      case DragState.idle:
        statusText = '';
        statusTone = GameMessageTone.info;
        break;
      case DragState.building:
        statusText = '';
        statusTone = GameMessageTone.info;
        break;
      case DragState.valid:
        statusText = '지금 손을 떼면 이 구간이 제거돼요.';
        statusTone = GameMessageTone.success;
        break;
      case DragState.invalid:
        statusText = '이 경로는 더 이상 연속 구간과 맞지 않아요.';
        statusTone = GameMessageTone.error;
        break;
    }
  }

  void _showInvalidPulse(String message) {
    invalidPulse = true;
    statusText = message;
    statusTone = GameMessageTone.error;
    _notify();

    final pulseVersion = ++_invalidPulseVersion;

    Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
      if (_disposed || pulseVersion != _invalidPulseVersion) {
        return;
      }

      invalidPulse = false;
      _notify();
    });
  }

  Future<void> _resolveCurrentMatch() async {
    final matchedPath = List<HexCoord>.from(dragPath);
    final matchedColors = _colorsForPath(matchedPath);
    final usedWindow = matchingBarWindowsForSequence(matchedColors).first;
    final currentVersion = _gameVersion;

    isResolvingMatch = true;
    clearingPath = matchedPath;
    _clearDrag();

    final now = DateTime.now();
    combo = _lastMatchAt != null &&
            now.difference(_lastMatchAt!) <= const Duration(seconds: 4)
        ? combo + 1
        : 1;
    _lastMatchAt = now;

    final gainedScore = _scoreForLength(matchedPath.length, combo);
    score += gainedScore;
    timeRemaining = min(
      startingSeconds.toDouble() + 25,
      timeRemaining + _timeBonusForLength(matchedPath.length),
    );
    statusText = combo > 1 ? 'COMBO x$combo\n+$gainedScore PTS' : '+$gainedScore PTS';
    statusTone = GameMessageTone.success;
    _notify();

    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (_disposed || currentVersion != _gameVersion) {
      return;
    }

    _removeMatchedTiles(matchedPath);
    _consumeBarWindow(usedWindow);
    clearingPath = const [];
    _ensurePlayableStateAfterBoardChange();
    _notify();

    if (isGameOver) {
      isResolvingMatch = false;
      _notify();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 320));

    if (_disposed || currentVersion != _gameVersion) {
      return;
    }

    isResolvingMatch = false;
    _notify();
  }

  void _removeMatchedTiles(List<HexCoord> matchedPath) {
    final stagedBoard = board
        .map((row) => row.map<GameColor?>((color) => color).toList())
        .toList();
    final nextAnimatedTiles = matchedPath.toSet();
    final counts = _colorCountsFromBoard(stagedBoard);

    for (final coord in matchedPath) {
      final nextColor = _weightedBoardColor(counts);
      stagedBoard[coord.row][coord.col] = nextColor;
      counts[nextColor] = (counts[nextColor] ?? 0) + 1;
    }

    board = stagedBoard
        .map((row) => row.map((color) => color!).toList(growable: false))
        .toList(growable: false);
    animatedTiles = Set<HexCoord>.unmodifiable(nextAnimatedTiles);
    boardAnimationTick++;
  }

  void _consumeBarWindow(BarWindow usedWindow) {
    colorBar = List<ColorBarEntry>.from(colorBar)
      ..removeRange(usedWindow.start, usedWindow.end + 1);

    _refillColorBar();
  }

  void _ensurePlayableStateAfterBoardChange() {
    if (timeRemaining <= 0) {
      _endGame('시간이 모두 지났어요.');
      return;
    }

    if (hasAnyValidMove()) {
      return;
    }

    _endGame('더 이상 만들 수 있는 경로가 없어요.');
  }

  void _endGame(String message) {
    isGameOver = true;
    isResolvingMatch = false;
    _timer?.cancel();
    _clearDrag();
    clearingPath = const [];
    statusText = message;
    statusTone = GameMessageTone.error;
  }

  void _randomizeBoardUntilPlayable() {
    for (var attempt = 0; attempt < 200; attempt++) {
      final counts = <GameColor, int>{};
      board = List<List<GameColor>>.generate(
        rows,
        (_) => List<GameColor>.generate(
          cols,
          (_) {
            final nextColor = _weightedBoardColor(counts);
            counts[nextColor] = (counts[nextColor] ?? 0) + 1;
            return nextColor;
          },
          growable: false,
        ),
        growable: false,
      );

      if (hasAnyValidMove()) {
        return;
      }
    }

    _endGame('플레이 가능한 보드를 만들지 못했어요.');
  }

  void _resetGame() {
    _gameVersion++;
    _timer?.cancel();

    score = 0;
    combo = 0;
    timeRemaining = startingSeconds.toDouble();
    isGameOver = false;
    isResolvingMatch = false;
    invalidPulse = false;
    dragState = DragState.idle;
    dragPath = const [];
    clearingPath = const [];
    animatedTiles = const {};
    boardAnimationTick = 0;
    _lastMatchAt = null;
    _nextBarEntryId = 0;
    statusText = '';
    statusTone = GameMessageTone.info;

    colorBar = const [];
    _refillColorBar();
    _randomizeBoardUntilPlayable();
    _startTimer();
    _notify();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (isGameOver) {
        return;
      }

      timeRemaining = max(0, timeRemaining - 0.25);

      if (timeRemaining <= 0) {
        _endGame('시간이 모두 지났어요.');
      }

      _notify();
    });
  }

  void _clearDrag() {
    dragPath = const [];
    dragState = DragState.idle;
    invalidPulse = false;
  }

  int _scoreForLength(int length, int comboCount) {
    const baseScore = 100;
    final extraBlocks = max(0, length - 3);

    // Non-linear scaling:
    // length 3 (extra 0) => 0
    // length 4 (extra 1) => 150 + 50 = 200
    // length 5 (extra 2) => 300 + 200 = 500
    // length 6 (extra 3) => 450 + 450 = 900
    final lengthBonus = (extraBlocks * 150) + (extraBlocks * extraBlocks * 50);

    final comboBonus = max(0, comboCount - 1) * 50;

    return baseScore + lengthBonus + comboBonus;
  }

  double _timeBonusForLength(int length) {
    return 1.4 + max(0, length - 2) * 0.65;
  }

  GameColor _randomColor() {
    return GameColor.values[_random.nextInt(GameColor.values.length)];
  }

  Map<GameColor, int> _colorCountsFromBoard(
      List<List<GameColor?>> sourceBoard) {
    final counts = <GameColor, int>{};

    for (final row in sourceBoard) {
      for (final color in row) {
        if (color == null) {
          continue;
        }
        counts[color] = (counts[color] ?? 0) + 1;
      }
    }

    return counts;
  }

  GameColor _weightedBoardColor(Map<GameColor, int> counts) {
    final totalTiles = counts.values.fold<int>(0, (sum, value) => sum + value);
    final average = totalTiles / GameColor.values.length;
    final weights = <GameColor, double>{};
    var totalWeight = 0.0;

    // If one color is already overrepresented on the board, lower its spawn
    // weight so refills naturally drift back toward a healthier spread.
    for (final color in GameColor.values) {
      final count = (counts[color] ?? 0).toDouble();
      final deltaFromAverage = count - average;
      final weight = deltaFromAverage <= 0
          ? 1.0 + (-deltaFromAverage * 0.08)
          : 1.0 / (1.0 + (deltaFromAverage * 0.35));

      weights[color] = weight;
      totalWeight += weight;
    }

    var roll = _random.nextDouble() * totalWeight;
    for (final color in GameColor.values) {
      roll -= weights[color]!;
      if (roll <= 0) {
        return color;
      }
    }

    return GameColor.values.last;
  }

  void _refillColorBar() {
    final nextBar = List<ColorBarEntry>.from(colorBar);

    while (nextBar.length < colorBarSize) {
      nextBar.add(_newBarEntry(existingEntries: nextBar));
    }

    colorBar = List<ColorBarEntry>.unmodifiable(nextBar);
  }

  GameColor _nextBarColor({required List<ColorBarEntry> existingEntries}) {
    final presentColors = existingEntries.map((entry) => entry.color).toSet();
    final missingColors = GameColor.values
        .where((color) => !presentColors.contains(color))
        .toList(growable: false);

    if (missingColors.isEmpty) {
      return _randomColor();
    }

    return missingColors[_random.nextInt(missingColors.length)];
  }

  ColorBarEntry _newBarEntry({List<ColorBarEntry> existingEntries = const []}) {
    return ColorBarEntry(
      id: _nextBarEntryId++,
      color: _nextBarColor(existingEntries: existingEntries),
    );
  }

  bool _isOnBoard(HexCoord coord) {
    return coord.row >= 0 &&
        coord.row < rows &&
        coord.col >= 0 &&
        coord.col < cols;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
