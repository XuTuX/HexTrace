import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'hex_game_models.dart';

export 'hex_game_models.dart';

part 'hex_game/hex_game_drag.dart';
part 'hex_game/hex_game_generation.dart';
part 'hex_game/hex_game_matching.dart';
part 'hex_game/hex_game_round.dart';

class HexGameController extends ChangeNotifier {
  HexGameController({
    this.rows = 7,
    this.cols = 6,
    this.colorBarSize = 10,
    this.startingSeconds = 60,
    Random? random,
  }) : _random = random ?? Random() {
    _resetGame(this);
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
  List<HexCoord> lastMatchPath = const [];
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

    return _matchingBarWindowsForSequence(this, _colorsForPath(this, dragPath));
  }

  void restart() {
    _resetGame(this);
  }

  void beginDrag(HexCoord? coord) {
    _beginDrag(this, coord);
  }

  void extendDrag(HexCoord? coord) {
    _extendDrag(this, coord);
  }

  void endDrag() {
    _endDrag(this);
  }

  void cancelDrag() {
    _cancelDrag(this);
  }

  List<HexCoord> neighborsOf(HexCoord coord) {
    return _neighborsOf(this, coord);
  }

  bool isAdjacent(HexCoord a, HexCoord b) {
    return _isAdjacent(this, a, b);
  }

  bool sequenceMatchesAnyBarWindow(List<GameColor> sequence) {
    return _sequenceMatchesAnyBarWindow(this, sequence);
  }

  List<BarWindow> matchingBarWindowsForSequence(List<GameColor> sequence) {
    return _matchingBarWindowsForSequence(this, sequence);
  }

  bool hasAnyValidMove() {
    return _hasAnyValidMove(this);
  }

  @override
  void dispose() {
    _disposeGame(this);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
