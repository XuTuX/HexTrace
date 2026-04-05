import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/score_controller.dart';
import '../game/hex_board_view.dart';
import '../game/hex_game_controller.dart';
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
                        const Spacer(flex: 1),
                        GameHud(controller: _controller),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 12,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: HexBoardView(controller: _controller),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: _FloatingStatusView(
                                        controller: _controller),
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

class _FloatingStatusView extends StatefulWidget {
  final HexGameController controller;

  const _FloatingStatusView({required this.controller});

  @override
  State<_FloatingStatusView> createState() => _FloatingStatusViewState();
}

class _FloatingStatusViewState extends State<_FloatingStatusView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  String _currentText = '';
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_animController);
    _translateY = Tween<double>(begin: 10, end: -40).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _FloatingStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.score > _lastScore) {
      _lastScore = widget.controller.score;
      setState(() {
        _currentText = widget.controller.statusText;
      });
      _animController.forward(from: 0);
    } else if (widget.controller.score == 0) {
      _lastScore = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        if (_animController.isDismissed || _currentText.isEmpty) {
          return const SizedBox.shrink();
        }

        final bool isCombo = _currentText.contains('COMBO');
        final List<String> textLines = _currentText.split('\n');
        final Color textColor =
            isCombo ? const Color(0xFF6366F1) : const Color(0xFF2563EB); // Indigo : Blue

        return Center(
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Transform.rotate(
              angle: isCombo ? -0.05 : 0,
              child: Opacity(
                opacity: _opacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: textLines.map((line) {
                    final bool isComboLine = line.startsWith('COMBO');
                    return Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isComboLine ? 16 : (isCombo ? 28 : 24),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
