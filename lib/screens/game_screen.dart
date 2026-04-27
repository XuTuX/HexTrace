import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../constant.dart';
import '../controllers/score_controller.dart';
import '../game/hex_board_view.dart';
import '../game/hex_game_controller.dart';
import '../services/app_haptics.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../services/daily_submission_service.dart';
import '../services/replay_share_service.dart';
import '../services/settings_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/browser_back_blocker.dart';
import '../widgets/dialogs/share_preview_dialog.dart';
import '../widgets/game/floating_status_view.dart';
import '../widgets/game/game_hud.dart';
import '../widgets/game/game_over_overlay.dart';
import '../widgets/home_screen/background_painter.dart';
import 'home_screen.dart';
import 'ranking_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.sessionConfig = const GameSessionConfig.normal(),
  });

  final GameSessionConfig sessionConfig;

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
  int? _dailyRank;
  bool _isDailyRankLoading = false;
  bool _isLeavingScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scoreController = Get.find<ScoreController>();

    _scoreController.resetScore();
    _controller = HexGameController(sessionConfig: widget.sessionConfig);
    _controller.addListener(_handleControllerChanged);
    _browserBackBlocker.attach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(AudioService().startBGM());
        final settings = Get.find<SettingsService>();
        if (!settings.hasCompletedTutorial.value &&
            !_controller.isReplaying &&
            !_controller.sessionConfig.isDailyMode) {
          _controller.startTutorial();
        } else if (_controller.sessionConfig.isTutorialMode) {
          _controller.startTutorial();
        }
      }
    });
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
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.syncTimer();
        unawaited(AudioService().resumeBGMIfNeeded());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(AudioService().pauseBGM());
        break;
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
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).shortestSide >= 600
                            ? 680
                            : 480,
                      ),
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
                                runSummary: _controller.runSummary,
                                bestScore: _scoreController.highscore.value,
                                isNewHighScore: _scoreController
                                    .hasNewHighScoreThisGame.value,
                                dailyRank: _dailyRank,
                                isDailyRankLoading: _isDailyRankLoading,
                                onRestart: _restartGame,
                                onReplay: _replayGame,
                                onShare: _shareReplay,
                                onHome: () {
                                  unawaited(_goHome());
                                },
                                onRanking: _openRanking,
                                isSharing: _isSharingReplay,
                              ),
                            ),
                          if (_controller.isTutorialMode &&
                              _controller.tutorialMessage != null)
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 40,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(_controller.tutorialStepIndex),
                                duration: const Duration(milliseconds: 400),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: GestureDetector(
                                  onTap: _controller.tutorialRequiresInteraction
                                      ? null
                                      : _controller.nextTutorialStep,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: charcoalBlack,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x261A1A1A),
                                          offset: Offset(0, 4),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _controller.tutorialMessage!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: charcoalBlack,
                                          ),
                                        ),
                                        if (!_controller
                                            .tutorialRequiresInteraction) ...[
                                          const SizedBox(height: 12),
                                          const Text(
                                            '터치해서 계속하기',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
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
                                color:
                                    Colors.red.withValues(alpha: value * 0.4),
                                width: 20 * value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.red.withValues(alpha: value * 0.2),
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
      unawaited(_finalizeCompletedRun());
    } else if (!_controller.isGameOver) {
      _didReportGameOver = false;
    }
  }

  void _restartGame() {
    _scoreController.resetScore();
    _lastSyncedScore = 0;
    _didReportGameOver = false;
    _dailyRank = null;
    _isDailyRankLoading = false;

    if (_controller.sessionConfig.isDailyMode) {
      showAppSnackBar(
        title: '오늘의 퍼즐',
        message: '오늘의 퍼즐은 하루 한 번만 플레이할 수 있어요. 홈으로 돌아갑니다.',
        icon: Icons.lock_outline_rounded,
        duration: const Duration(seconds: 3),
      );
      unawaited(_goHome());
      return;
    }

    _controller.playAgain();
  }

  void _replayGame() {
    _scoreController.resetScore();
    _lastSyncedScore = 0;
    _didReportGameOver = false;
    _dailyRank = null;
    _isDailyRankLoading = false;
    unawaited(_controller.watchReplay());
  }

  void _openRanking() {
    if (_isLeavingScreen ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        Get.overlayContext == null) {
      return;
    }

    try {
      Get.bottomSheet(
        RankingScreen(isDailyOnly: _controller.sessionConfig.isDailyMode),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enterBottomSheetDuration: const Duration(milliseconds: 300),
      );
    } catch (error, stackTrace) {
      debugPrint(
          'Skipping ranking sheet because overlay is unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _finalizeCompletedRun() async {
    final summary = _controller.runSummary;
    final dbService = Get.find<DatabaseService>();

    if (summary.mode == GameMode.dailyOfficial && mounted) {
      setState(() {
        _dailyRank = null;
        _isDailyRankLoading = true;
      });
    }

    final dailyResult = await _submitDailyScoreIfNeeded(
      dbService: dbService,
      summary: summary,
    );

    if (dailyResult == DailySubmissionResult.success &&
        summary.mode == GameMode.dailyOfficial &&
        _controller.sessionConfig.dateKey != null) {
      final dailyRank = await dbService.getMyDailyRank(
        gameId,
        dateKey: _controller.sessionConfig.dateKey!,
      );

      if (mounted) {
        setState(() {
          _dailyRank = dailyRank;
          _isDailyRankLoading = false;
        });
      }
    } else if (mounted && summary.mode == GameMode.dailyOfficial) {
      setState(() {
        _isDailyRankLoading = false;
      });
    }

    if (!mounted) {
      return;
    }

    // Ranking is intentionally opened only by the user's explicit tap.
  }

  Future<void> _goHome() async {
    if (_isLeavingScreen || !mounted) {
      return;
    }

    _isLeavingScreen = true;
    clearAppSnackBars();
    await Get.offAll(() => const HomeScreen());
  }

  Future<DailySubmissionResult> _submitDailyScoreIfNeeded({
    required DatabaseService dbService,
    required GameRunSummary summary,
  }) async {
    if (!_controller.sessionConfig.isOfficialScoreSubmission ||
        !_controller.sessionConfig.isDailyMode ||
        _controller.sessionConfig.dateKey == null) {
      return DailySubmissionResult.notNeeded;
    }

    try {
      final replayCode = ReplayShareService.buildReplayCode(
        seed: _controller.initialSeed,
        recordedMoves: _controller.recordedMoves,
      );
      final dailySubmissionService = Get.find<DailySubmissionService>();
      await dailySubmissionService.savePendingSubmission(
        gameId: gameId,
        dateKey: _controller.sessionConfig.dateKey!,
        seed: _controller.initialSeed,
        score: summary.score,
        replayCode: replayCode,
        summary: summary.toJson(),
      );
      final storedScore = await dbService.submitDailyScore(
        gameId: gameId,
        dateKey: _controller.sessionConfig.dateKey!,
        seed: _controller.initialSeed,
        score: summary.score,
        replayCode: replayCode,
        summary: summary.toJson(),
      );
      await dailySubmissionService.clearPendingSubmission();
      debugPrint('Daily score submitted: $storedScore');
      return DailySubmissionResult.success;
    } catch (e) {
      final message = e.toString();
      late final String snackMessage;

      if (message.contains('Daily attempt already used')) {
        snackMessage = '오늘의 퍼즐은 하루 한 번만 플레이할 수 있어요.';
      } else if (message.contains('Daily challenge is only valid for today')) {
        snackMessage = '날짜가 바뀌어 오늘 랭킹에 기록을 등록하지 못했어요.';
      } else if (message.contains('Daily challenge entry not claimed')) {
        snackMessage = '입장 정보가 확인되지 않아 오늘 랭킹에 반영되지 않았어요.';
      } else if (message.contains('Invalid daily challenge seed')) {
        snackMessage = '퍼즐 정보가 맞지 않아 오늘 랭킹에 반영되지 않았어요.';
      } else if (message.contains('Not authenticated')) {
        snackMessage = '로그인 정보가 만료되어 오늘 랭킹에 반영되지 않았어요.';
      } else {
        snackMessage = '공식 기록 저장에 실패했어요. 홈 화면에서 자동으로 다시 제출을 시도합니다.';
      }

      if (mounted && !_isLeavingScreen) {
        showAppSnackBar(
          title: '오늘의 퍼즐 저장 실패',
          message: snackMessage,
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
          duration: const Duration(seconds: 3),
        );
      }

      return DailySubmissionResult.failed;
    }
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
                    title: 'Bee House 리플레이',
                    subject: 'Bee House 리플레이',
                    text: shareText,
                    files: shareImage == null ? null : [shareImage],
                    fileNameOverrides:
                        shareImage == null ? null : const ['hexor-replay.png'],
                    sharePositionOrigin: shareOrigin,
                  ),
                );

                if (mounted) {
                  Get.back(); // Close dialog on success
                }
              } catch (e) {
                showAppSnackBar(
                  title: '공유 실패',
                  message: '리플레이를 공유하지 못했습니다. 잠시 후 다시 시도해 주세요.',
                  backgroundColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFEF4444),
                  icon: Icons.error_outline_rounded,
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

enum DailySubmissionResult { notNeeded, success, failed }
