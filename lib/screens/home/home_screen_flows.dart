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
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';

void handleRankingPress(AuthService authService) {
  if (authService.user.value != null) {
    showRankingSheet();
  } else {
    showLoginSheet(authService, isRankingAction: true);
  }
}

void openGameScreen(
    [GameSessionConfig sessionConfig = const GameSessionConfig.normal()]) {
  Get.off(() => GameScreen(sessionConfig: sessionConfig));
}

Future<void> openDailyChallenge(AuthService authService) async {
  final dbService = Get.find<DatabaseService>();

  if (authService.user.value == null) {
    showLoginSheet(
      authService,
      initialError: '오늘의 퍼즐은 로그인 후 하루 한 번만 참여할 수 있어요.',
    );
    return;
  }

  try {
    final existingState = await dbService.getDailyChallenge(gameId);
    final gateDecision = resolveDailyChallengeLaunch(
      challenge: existingState,
      isLoggedIn: true,
    );
    if (!gateDecision.canLaunch) {
      Get.snackbar(
        '오늘의 퍼즐',
        gateDecision.noticeMessage ?? '오늘의 퍼즐은 오늘 이미 사용했어요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final claimedChallenge = await dbService.claimDailyChallengeEntry(gameId);
    openGameScreen(
      GameSessionConfig(
        mode: GameMode.dailyOfficial,
        seed: claimedChallenge.seed,
        dateKey: claimedChallenge.dateKey,
        isOfficialScoreSubmission: true,
      ),
    );
  } catch (_) {
    Get.snackbar(
      '입장 실패',
      '오늘의 퍼즐 입장 처리에 실패했어요. 잠시 후 다시 시도해 주세요.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
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
