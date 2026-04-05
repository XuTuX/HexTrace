import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gameplay/engine/rune_bloom_engine.dart';
import '../gameplay/game_constants.dart';
import '../gameplay/models/board_cell.dart';
import '../gameplay/models/rune_piece.dart';
import '../gameplay/models/rune_type.dart';
import '../screens/game_over.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import 'score_controller.dart';

enum ContinueResult {
  success,
  alreadyUsed,
  noValidPulse,
  adNotCompleted,
  adUnavailable,
}

class GameController extends GetxController {
  late ScoreController scoreController;
  late SettingsService settingsService;

  final Random _random = Random();

  final board = <List<BoardCell?>>[].obs;
  final activePieces = <RunePiece?>[].obs;

  final isGameOver = false.obs;
  final hoverCells = <int>[].obs;
  final hoverColor = Rx<Color?>(null);
  final lastPlacedCells = <int>[].obs;
  final lastClearedCells = <int>[].obs;
  final currentChain = 0.obs;
  final showTutorial = true.obs;
  final hasSavedGame = false.obs;
  final hasUsedContinueThisGame = false.obs;

  static const String _tutorialKey = 'rune_bloom_tutorial_seen';
  static const String _saveKey = 'rune_bloom_state';

  @override
  void onInit() {
    super.onInit();

    try {
      scoreController = Get.find<ScoreController>();
    } catch (_) {
      scoreController = Get.put(ScoreController());
    }

    settingsService = Get.find<SettingsService>();

    _checkTutorial();
    checkHasSavedGame();
  }

  Future<void> checkHasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    hasSavedGame.value = prefs.containsKey(_saveKey);
  }

  Future<void> saveGameState() async {
    if (isGameOver.value || board.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final state = {
      'score': scoreController.score.value,
      'placementScore': scoreController.placementScore.value,
      'cascadeScore': scoreController.cascadeScore.value,
      'combo': scoreController.combo.value,
      'board': board
          .map(
            (row) => row.map((cell) => cell?.toJson()).toList(growable: false),
          )
          .toList(growable: false),
      'activePieces':
          activePieces.map((piece) => piece?.toJson()).toList(growable: false),
      'hasUsedContinueThisGame': hasUsedContinueThisGame.value,
    };

    await prefs.setString(_saveKey, jsonEncode(state));
    hasSavedGame.value = true;
  }

  Future<bool> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_saveKey);
    if (stateJson == null) return false;

    try {
      final state = jsonDecode(stateJson) as Map<String, dynamic>;

      scoreController.score.value = state['score'] as int? ?? 0;
      scoreController.placementScore.value =
          state['placementScore'] as int? ?? 0;
      scoreController.cascadeScore.value = state['cascadeScore'] as int? ?? 0;
      scoreController.combo.value = state['combo'] as int? ?? 0;
      scoreController.lastIncrement.value = 0;
      scoreController.showIncrement.value = false;

      final boardJson =
          List<List<dynamic>>.from(state['board'] as List<dynamic>);
      board.assignAll(
        boardJson.map((row) {
          return row.map<BoardCell?>((cell) {
            if (cell == null) return null;
            return BoardCell.fromJson(Map<String, dynamic>.from(cell));
          }).toList(growable: false);
        }).toList(growable: false),
      );

      final activePiecesJson =
          List<dynamic>.from(state['activePieces'] as List<dynamic>);
      activePieces.assignAll(activePiecesJson.map((piece) {
        if (piece == null) return null;
        return RunePiece.fromJson(Map<String, dynamic>.from(piece));
      }).toList(growable: false));

      isGameOver.value = false;
      hoverCells.clear();
      hoverColor.value = null;
      lastPlacedCells.clear();
      lastClearedCells.clear();
      currentChain.value = scoreController.combo.value;
      hasUsedContinueThisGame.value =
          state['hasUsedContinueThisGame'] as bool? ?? false;
      hasSavedGame.value = true;

      return true;
    } catch (error) {
      debugPrint('Error loading Rune Bloom save: $error');
      return false;
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    hasSavedGame.value = false;
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    showTutorial.value = !(prefs.getBool(_tutorialKey) ?? false);
  }

  Future<void> completeTutorial() async {
    showTutorial.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
    await _checkTrackingPermission();
  }

  void openTutorial() {
    showTutorial.value = true;
  }

  void resetGame() {
    scoreController.resetScore();

    board.assignAll(RuneBloomEngine.createEmptyBoard());
    activePieces.clear();
    isGameOver.value = false;
    hoverCells.clear();
    hoverColor.value = null;
    lastPlacedCells.clear();
    lastClearedCells.clear();
    currentChain.value = 0;
    hasUsedContinueThisGame.value = false;

    clearSavedGame();
    generateNewPieces();
  }

  void generateNewPieces() {
    final pieces = List<RunePiece?>.generate(3, (_) => _createRandomPiece());
    final placeableTemplates = runePieceTemplates
        .where(
          (shape) => RuneBloomEngine.canPlacePieceAnywhere(
            board,
            RunePiece(
              id: 'preview',
              type: RuneType.ember,
              shape: shape,
            ),
          ),
        )
        .toList(growable: false);

    if (placeableTemplates.isNotEmpty && !_hasAnyPlaceablePiece(pieces)) {
      pieces[_random.nextInt(pieces.length)] = RunePiece(
        id: _pieceId(),
        type: RuneType.values[_random.nextInt(RuneType.values.length)],
        shape: placeableTemplates[_random.nextInt(placeableTemplates.length)],
      );
    }

    activePieces.assignAll(pieces);
  }

  void updateHover(int centerRow, int centerColumn, RunePiece piece) {
    final previewCells =
        RuneBloomEngine.pieceCellsAtCenter(piece, centerRow, centerColumn);

    final nextHover = <int>[];

    for (final cell in previewCells) {
      if (cell.x < 0 ||
          cell.x >= boardRows ||
          cell.y < 0 ||
          cell.y >= boardColumns ||
          board[cell.x][cell.y] != null) {
        clearHover();
        return;
      }

      nextHover.add(RuneBloomEngine.toCellIndex(cell.x, cell.y));
    }

    hoverCells.assignAll(nextHover);
    hoverColor.value = hoverColorForRune(piece.type);
  }

  void clearHover() {
    hoverCells.clear();
    hoverColor.value = null;
  }

  void placePiece(int centerRow, int centerColumn, int pieceIndex) {
    clearHover();

    if (pieceIndex < 0 || pieceIndex >= activePieces.length) return;

    final piece = activePieces[pieceIndex];
    if (piece == null) return;

    if (!RuneBloomEngine.canPlacePieceAtCenter(
      board,
      piece,
      centerRow,
      centerColumn,
    )) {
      return;
    }

    if (settingsService.isHapticsOn.value) {
      HapticFeedback.selectionClick();
    }

    final workingBoard = RuneBloomEngine.cloneBoard(board);
    final placedCells =
        RuneBloomEngine.pieceCellsAtCenter(piece, centerRow, centerColumn);

    for (final cell in placedCells) {
      workingBoard[cell.x][cell.y] = BoardCell(type: piece.type, level: 1);
    }

    final resolution = RuneBloomEngine.resolveCascades(workingBoard);
    board.assignAll(resolution.board);

    lastPlacedCells.assignAll(
      placedCells
          .map((cell) => RuneBloomEngine.toCellIndex(cell.x, cell.y))
          .toList(growable: false),
    );
    lastClearedCells.assignAll(resolution.clearedCells);
    currentChain.value = resolution.highestChain;

    scoreController.registerTurn(
      placementPoints: piece.cellCount * 2,
      cascadePoints: resolution.cascadeScore,
      chainDepth: resolution.highestChain,
    );

    activePieces[pieceIndex] = null;
    activePieces.refresh();

    Future.delayed(const Duration(milliseconds: 300), () {
      lastPlacedCells.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      lastClearedCells.clear();
    });

    if (activePieces.every((piece) => piece == null)) {
      generateNewPieces();
    }

    saveGameState();

    if (!_canPlaceAnyActivePiece()) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!_canPlaceAnyActivePiece() && !isGameOver.value) {
          gameOver();
        }
      });
    }
  }

  Future<void> restartGame() async {
    await _checkTrackingPermission();
    resetGame();
  }

  Future<ContinueResult> continueAfterRewardAd() async {
    if (hasUsedContinueThisGame.value) {
      return ContinueResult.alreadyUsed;
    }

    final rescueWindow =
        RuneBloomEngine.findBestRescueWindow(board, activePieces);
    if (rescueWindow == null) {
      return ContinueResult.noValidPulse;
    }

    final adService = Get.find<AdService>();
    final completer = Completer<ContinueResult>();
    bool rewardEarned = false;

    final didShowAd = adService.showRewardedAd(
      onUserEarnedReward: () {
        rewardEarned = true;
      },
      onAdDismissed: () {
        if (rewardEarned) {
          _clearRescueWindow(rescueWindow);
          if (!completer.isCompleted) {
            completer.complete(ContinueResult.success);
          }
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(ContinueResult.adNotCompleted);
        }
      },
      onAdUnavailable: () {
        if (!completer.isCompleted) {
          completer.complete(ContinueResult.adUnavailable);
        }
      },
    );

    if (!didShowAd) {
      return ContinueResult.adUnavailable;
    }

    return completer.future;
  }

  void gameOver() {
    isGameOver.value = true;
    scoreController.checkHighScore();
    scoreController.uploadHighScoreToServer();
    clearSavedGame();

    if (settingsService.isHapticsOn.value) {
      HapticFeedback.vibrate();
    }

    final adService = Get.find<AdService>();
    final canContinue = adService.hasRewardedAdConfigured &&
        !hasUsedContinueThisGame.value &&
        RuneBloomEngine.findBestRescueWindow(board, activePieces) != null;

    Get.dialog(
      GameOverDialog(
        onRestart: () {
          Get.back();
          restartGame();
        },
        onContinue: canContinue ? continueAfterRewardAd : null,
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
    );
  }

  bool _canPlaceAnyActivePiece() {
    return _hasAnyPlaceablePiece(activePieces);
  }

  bool _hasAnyPlaceablePiece(Iterable<RunePiece?> pieces) {
    for (final piece in pieces) {
      if (piece == null) continue;
      if (RuneBloomEngine.canPlacePieceAnywhere(board, piece)) {
        return true;
      }
    }

    return false;
  }

  RunePiece _createRandomPiece() {
    return RunePiece(
      id: _pieceId(),
      type: RuneType.values[_random.nextInt(RuneType.values.length)],
      shape: runePieceTemplates[_random.nextInt(runePieceTemplates.length)],
    );
  }

  String _pieceId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(99999)}';
  }

  void _clearRescueWindow(RescueWindow window) {
    final updatedBoard = RuneBloomEngine.cloneBoard(board);
    final cleared = <int>[];

    for (int row = window.startRow; row < window.startRow + 3; row++) {
      for (int column = window.startColumn;
          column < window.startColumn + 3;
          column++) {
        if (updatedBoard[row][column] == null) continue;
        updatedBoard[row][column] = null;
        cleared.add(RuneBloomEngine.toCellIndex(row, column));
      }
    }

    board.assignAll(updatedBoard);
    lastClearedCells.assignAll(cleared);
    isGameOver.value = false;
    currentChain.value = 0;
    hasUsedContinueThisGame.value = true;

    Future.delayed(const Duration(milliseconds: 800), () {
      lastClearedCells.clear();
    });

    saveGameState();
  }

  Future<void> _checkTrackingPermission() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 500));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (error) {
      debugPrint('Error requesting tracking transparency: $error');
    }
  }
}
