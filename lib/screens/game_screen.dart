import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/score_controller.dart';
import '../game/hex_board_view.dart';
import '../game/hex_game_controller.dart';
import '../utils/browser_back_blocker.dart';
import '../widgets/game/floating_status_view.dart';
import '../widgets/game/game_hud.dart';
import '../widgets/game/game_over_overlay.dart';
import '../widgets/home_screen/background_painter.dart';
import 'home_screen.dart';
import 'ranking_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final HexGameController _controller;
  late final ScoreController _scoreController;
  final BrowserBackBlocker _browserBackBlocker = BrowserBackBlocker();
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
    _browserBackBlocker.attach();
  }

  @override
  void dispose() {
    _browserBackBlocker.detach();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPatternPainter(),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              const Spacer(flex: 1),
                              GameHud(controller: _controller),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 12,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: HexBoardView(
                                            controller: _controller),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: FloatingStatusView(
                                            controller: _controller,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                isNewHighScore: _scoreController
                                    .hasNewHighScoreThisGame.value,
                                onRestart: _restartGame,
                                onHome: () =>
                                    Get.offAll(() => const HomeScreen()),
                                onRanking: _openRanking,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
