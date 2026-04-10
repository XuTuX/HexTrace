import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/score_controller.dart';
import '../game/hex_board_view.dart';
import '../game/hex_game_controller.dart';
import '../services/app_haptics.dart';
import '../services/replay_share_service.dart';
import '../utils/browser_back_blocker.dart';
import '../widgets/dialogs/share_preview_dialog.dart';
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final HexGameController _controller;
  late final ScoreController _scoreController;
  final BrowserBackBlocker _browserBackBlocker = BrowserBackBlocker();
  int _lastSyncedScore = 0;
  bool _didReportGameOver = false;
  bool _isSharingReplay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _browserBackBlocker.detach();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.syncTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            // 시스템 뒤로가기 차단
          },
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
                              if (_controller.isReplaying)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 20),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_circle_fill,
                                                color: Color(0xFF0095FF),
                                                size: 22),
                                            const SizedBox(width: 12),
                                            const Text(
                                              '리플레이 재생 중',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${_controller.currentReplayIndex} / ${_controller.totalReplayMoves}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: _controller.stopReplay,
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white70,
                                                  size: 22),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Progress Bar
                                      Container(
                                        height: 6,
                                        width: double.infinity,
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: _controller
                                                        .totalReplayMoves >
                                                    0
                                                ? (_controller
                                                         .currentReplayIndex /
                                                    _controller
                                                        .totalReplayMoves)
                                                : 0.0,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF0095FF),
                                                    Color(0xFF00D47C)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                onReplay: _replayGame,
                                onShare: _shareReplay,
                                onHome: () =>
                                    Get.offAll(() => const HomeScreen()),
                                onRanking: _openRanking,
                                isSharing: _isSharingReplay,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Time critical flash overlay
                if (_controller.lastTimeFlashAt != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_controller.lastTimeFlashAt),
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          if (value <= 0) return const SizedBox.shrink();
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withValues(alpha: value * 0.4),
                                width: 20 * value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: value * 0.2),
                                  blurRadius: 40 * value,
                                  spreadRadius: 10 * value,
                                ),
                              ],
                            ),
                          );
                        },
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
      if (!_controller.isReplaying) {
        _scoreController.registerPuzzleMatch(
          points: gained,
          comboDepth: _controller.combo,
        );
      }
      _lastSyncedScore = _controller.score;
    }

    if (_controller.isGameOver &&
        !_didReportGameOver &&
        !_controller.isReplaying) {
      _didReportGameOver = true;
      unawaited(AppHaptics.gameOver());
      _scoreController.checkHighScore();
      unawaited(_scoreController.uploadHighScoreToServer(_controller.score));
    } else if (!_controller.isGameOver) {
      _didReportGameOver = false;
    }
  }

  void _restartGame() {
    _scoreController.resetScore();
    _lastSyncedScore = 0;
    _didReportGameOver = false;
    _controller.playAgain();
  }

  void _replayGame() {
    _scoreController.resetScore();
    _lastSyncedScore = 0;
    _didReportGameOver = false;
    unawaited(_controller.watchReplay());
  }

  void _openRanking() {
    Get.bottomSheet(
      const RankingScreen(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _shareReplay() async {
    final GlobalKey dialogShareKey = GlobalKey();

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return SharePreviewDialog(
            score: _controller.score,
            bestScore: _scoreController.highscore.value,
            isNewHighScore: _scoreController.hasNewHighScoreThisGame.value,
            shareCardKey: dialogShareKey,
            isSharing: _isSharingReplay,
            onShare: () async {
              if (_isSharingReplay) return;

              setDialogState(() => _isSharingReplay = true);
              setState(() => _isSharingReplay = true);

              try {
                final shareImage = await ReplayShareService.captureReplayCard(
                  repaintBoundaryKey: dialogShareKey,
                  pixelRatio: MediaQuery.devicePixelRatioOf(context),
                );

                if (!mounted || !context.mounted) return;

                final shareText = ReplayShareService.buildShareText(
                  score: _controller.score,
                  bestScore: _scoreController.highscore.value,
                  isNewHighScore:
                      _scoreController.hasNewHighScoreThisGame.value,
                  seed: _controller.initialSeed,
                  recordedMoves: _controller.recordedMoves,
                );

                final renderBox = context.findRenderObject() as RenderBox?;
                final shareOrigin = renderBox == null
                    ? null
                    : renderBox.localToGlobal(Offset.zero) & renderBox.size;

                await SharePlus.instance.share(
                  ShareParams(
                    title: 'Linkagon 리플레이',
                    subject: 'Linkagon 리플레이',
                    text: shareText,
                    files: shareImage == null ? null : [shareImage],
                    fileNameOverrides: shareImage == null
                        ? null
                        : const ['linkagon-trace-replay.png'],
                    sharePositionOrigin: shareOrigin,
                  ),
                );

                if (mounted) {
                  Get.back(); // Close dialog on success
                }
              } catch (e) {
                Get.snackbar(
                  '공유 실패',
                  '리플레이를 공유하지 못했습니다. 잠시 후 다시 시도해 주세요.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } finally {
                if (mounted) {
                  setDialogState(() => _isSharingReplay = false);
                  setState(() => _isSharingReplay = false);
                }
              }
            },
          );
        },
      ),
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }
}
