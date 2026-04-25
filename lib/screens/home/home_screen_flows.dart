import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/daily_challenge_entry.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/screens/game_screen.dart';
import 'package:hexor/screens/ranking_screen.dart';
import 'package:hexor/screens/settings_screen.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/services/daily_submission_service.dart';
import 'package:hexor/utils/app_snackbar.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';

void handleRankingPress(AuthService authService) {
  showRankingSheet();
}

void openGameScreen(
    [GameSessionConfig sessionConfig = const GameSessionConfig.normal()]) {
  Get.off(() => GameScreen(sessionConfig: sessionConfig));
}

Future<void> openDailyChallenge(AuthService authService) async {
  final dbService = Get.find<DatabaseService>();
  final dailySubmissionService = Get.find<DailySubmissionService>();

  if (authService.user.value == null) {
    showLoginSheet(
      authService,
      initialError: '오늘의 퍼즐은 로그인 후 하루 한 번만 참여할 수 있어요.',
    );
    return;
  }

  try {
    debugPrint('🔵 [DailyFlow] Starting openDailyChallenge');
    var existingState = await dbService.getDailyChallenge(gameId);
    debugPrint('🔵 [DailyFlow] Challenge state: hasUsedEntry=${existingState.hasUsedEntry}, myScore=${existingState.myScore}');

    if (existingState.hasUsedEntry && !existingState.hasScoreEntry) {
      debugPrint('🔵 [DailyFlow] Detected used entry without score, attempting retry');
      try {
        final retried =
            await dailySubmissionService.retryPendingSubmissionIfMatches(
          gameId: gameId,
          dateKey: existingState.dateKey,
        );
        if (retried != null) {
          debugPrint('🔵 [DailyFlow] Retry successful, refreshing state');
          existingState = await dbService.getDailyChallenge(gameId);
        }
      } catch (e) {
        debugPrint('🔴 [DailyFlow] Retry failed: $e');
      }
    }

    final gateDecision = resolveDailyChallengeLaunch(
      challenge: existingState,
      isLoggedIn: true,
    );
    debugPrint('🔵 [DailyFlow] Gate decision: canLaunch=${gateDecision.canLaunch}, message=${gateDecision.noticeMessage}');

    if (!gateDecision.canLaunch) {
      debugPrint('🟡 [DailyFlow] Launch blocked. Showing snackbar.');
      showAppSnackBar(
        title: '오늘의 퍼즐',
        message: gateDecision.noticeMessage ?? '오늘은 이미 참여했어요! 내일 다시 도전해 주세요.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    final launchConfig = gateDecision.sessionConfig;
    if (launchConfig != null &&
        existingState.hasUsedEntry &&
        !existingState.hasScoreEntry) {
      _showDailyLaunchNotice(gateDecision.noticeMessage);
      openGameScreen(launchConfig);
      return;
    }

    try {
      final claimedChallenge = await dbService.claimDailyChallengeEntry(gameId);
      openGameScreen(
        GameSessionConfig(
          mode: GameMode.dailyOfficial,
          seed: claimedChallenge.seed,
          dateKey: claimedChallenge.dateKey,
          isOfficialScoreSubmission: true,
        ),
      );
    } catch (error) {
      if (error.toString().contains('Daily challenge already used')) {
        _showDailyLaunchNotice('오늘의 퍼즐은 하루에 한 번만 가능해요.');
        return;
      }
      rethrow;
    }
  } catch (error) {
    showAppSnackBar(
      title: '입장 실패',
      message: _dailyEntryFailureMessage(error),
      backgroundColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
    );
  }
}

Future<void> openDailyChallengeTest() async {
  final dbService = Get.find<DatabaseService>();

  try {
    final challenge = await dbService.getDailyChallenge(gameId);
    showAppSnackBar(
      title: '테스트 모드',
      message: '공식 기록 없이 오늘의 퍼즐을 테스트합니다.',
    );
    openGameScreen(
      GameSessionConfig(
        mode: GameMode.dailyPractice,
        seed: challenge.seed,
        dateKey: challenge.dateKey,
      ),
    );
  } catch (_) {
    showAppSnackBar(
      title: '테스트 실패',
      message: '오늘의 퍼즐 테스트를 시작하지 못했어요.',
      backgroundColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
    );
  }
}

void _showDailyLaunchNotice(String? message) {
  if (message == null || message.trim().isEmpty) {
    return;
  }

  showAppSnackBar(
    title: '오늘의 퍼즐',
    message: message,
    icon: Icons.info_outline_rounded,
  );
}

String _dailyEntryFailureMessage(Object error) {
  final message = error.toString();
  if (message.contains('Daily challenge already used')) {
    return '오늘의 퍼즐은 하루에 한 번만 가능해요.';
  }
  return '오늘의 퍼즐 입장 처리에 실패했어요. 잠시 후 다시 시도해 주세요.';
}

void showLoginSheet(
  AuthService authService, {
  bool isRankingAction = false,
  String? initialError,
}) {
  Get.bottomSheet(
    LoginSheet(
      isRankingAction: isRankingAction,
      initialError: initialError,
      onGoogleSignIn: () async {
        return authService.signInWithGoogle();
      },
      onAppleSignIn: () async {
        return authService.signInWithApple();
      },
      onLoginSuccess: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (isRankingAction) {
          showRankingSheet();
        }
      },
    ),
    isScrollControlled: true,
  );
}

void showSettingsScreen(AuthService authService) {
  final dbService = Get.find<DatabaseService>();
  Get.to(
    () => SettingsScreen(
      authService: authService,
      dbService: dbService,
    ),
    transition: Transition.rightToLeft,
    duration: const Duration(milliseconds: 300),
  );
}

void showRankingSheet() {
  Get.bottomSheet(
    const RankingScreen(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enterBottomSheetDuration: const Duration(milliseconds: 300),
  );
}

void showDailyRankingSheet() {
  Get.bottomSheet(
    const RankingScreen(isDailyOnly: true),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enterBottomSheetDuration: const Duration(milliseconds: 300),
  );
}

Future<void> showInitialNicknameDialog(AuthService authService) async {
  await Get.dialog(
    EditNicknameDialog(
      currentNickname: '',
      isInitialSetup: true,
      onSave: (newNickname) async {
        return authService.updateNickname(newNickname);
      },
    ),
    barrierDismissible: false,
  );
}
