import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/score_controller.dart';
import '../../screens/home_screen.dart';
import '../../screens/ranking_screen.dart';
import '../game/game_controller.dart';
import '../game/hex_board_view.dart';
import '../../widgets/home_screen/background_painter.dart';
import '../../widgets/home_screen/home_components.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_over_overlay.dart';

class HexPuzzlePage extends StatefulWidget {
  const HexPuzzlePage({super.key});

  @override
  State<HexPuzzlePage> createState() => _HexPuzzlePageState();
}

class _HexPuzzlePageState extends State<HexPuzzlePage> {
  late final HexGameController _controller;
  late final ScoreController _scoreController;
  int _lastSyncedScore = 0;
  bool _didReportGameOver = false;

  @override
  void initState() {
    super.initState();
    try {
      _scoreController = Get.find<ScoreController>();
    } catch (_) {
      _scoreController = Get.put(ScoreController());
    }

    _scoreController.resetScore();
    _controller = HexGameController();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        GameHud(controller: _controller),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: HexBoardView(controller: _controller),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                          child: SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: '새 게임',
                              onPressed: _restartGame,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_controller.isGameOver)
                    Positioned.fill(
                      child: GameOverOverlay(
                        score: _controller.score,
                        bestScore: _scoreController.highscore.value,
                        isNewHighScore:
                            _scoreController.hasNewHighScoreThisGame.value,
                        onRestart: _restartGame,
                        onHome: () => Get.offAll(() => const HomeScreen()),
                        onRanking: _openRanking,
                      ),
                    ),
                ],
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleControllerChanged() {
    if (_controller.score < _lastSyncedScore) {
      _scoreController.resetScore();
      _lastSyncedScore = _controller.score;
      _didReportGameOver = false;
      return;
    }

    final gained = _controller.score - _lastSyncedScore;
    if (gained > 0) {
      _scoreController.registerPuzzleMatch(
        points: gained,
        comboDepth: _controller.combo,
      );
      _lastSyncedScore = _controller.score;
    }

    if (_controller.isGameOver && !_didReportGameOver) {
      _didReportGameOver = true;
      _scoreController.checkHighScore();
      unawaited(_scoreController.uploadHighScoreToServer());
    } else if (!_controller.isGameOver) {
      _didReportGameOver = false;
    }
  }

  void _restartGame() {
    _scoreController.resetScore();
    _lastSyncedScore = 0;
    _didReportGameOver = false;
    _controller.restart();
  }

  void _openRanking() {
    Get.bottomSheet(
      const RankingScreen(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }
}
