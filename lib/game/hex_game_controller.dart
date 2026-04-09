import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'hex_game_models.dart';
import '../services/app_haptics.dart';

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
    int? seed,
  }) : initialSeed = seed ?? Random().nextInt(1000000) {
    _random = Random(initialSeed);
    _resetGame(this, seed: initialSeed);
  }

  final int rows;
  final int cols;
  final int colorBarSize;
  final int startingSeconds;
  late Random _random;
  // ignore: prefer_final_fields
  int _nextBarEntryId = 0;

  int initialSeed = 0;
  final List<List<HexCoord>> recordedMoves = [];
  bool isReplaying = false;

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
  // ignore: prefer_final_fields
  bool _disposed = false;
  DateTime? _lastMatchAt;
  // ignore: prefer_final_fields
  int _gameVersion = 0;
  // ignore: prefer_final_fields
  int _invalidPulseVersion = 0;

  bool get canInteract => !isGameOver && !isResolvingMatch && !isReplaying;

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
    _resetGame(this, seed: initialSeed);
  }

  void playAgain() {
    initialSeed = Random().nextInt(1000000);
    _random = Random(initialSeed);
    _resetGame(this, seed: initialSeed);
  }

  Future<void> watchReplay() async {
    isReplaying = true;
    final movesToReplay = List<List<HexCoord>>.from(recordedMoves);
    _resetGame(this, seed: initialSeed, isReplayMode: true);

    statusText = '리플레이를 준비하고 있어요...';
    statusTone = GameMessageTone.info;
    _notify();

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    statusText = '리플레이 시작!';
    statusTone = GameMessageTone.success;
    _notify();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    for (final move in movesToReplay) {
      if (_disposed || isGameOver) break;

      dragPath = move;
      _notify();
      await _resolveCurrentMatch(this);
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    statusText = '리플레이가 끝났습니다.';
    statusTone = GameMessageTone.info;
    _notify();

    // 리플레이 종료 후 1.2초 대기했다가 결과 화면으로 전환
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    isReplaying = false;
    _endGame(this, '리플레이가 완료되었습니다.');
    _notify();
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
